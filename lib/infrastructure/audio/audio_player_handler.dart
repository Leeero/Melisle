import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:just_audio/just_audio.dart';

/// [AudioPlayerHandler] 是系统级播放能力的唯一入口。
///
/// 设计原则（2026 Q2 重构）：
/// - **一次只加载一首歌**。所有"切歌 = 重置 AudioPlayer + 加载新的单一 AudioSource"，
///   不再使用 ConcatenatingAudioSource / 占位 silence / 500 首大队列等会引发
///   `setAudioSources` 竞态的做法。
/// - **循环 / 随机 / 上下一曲 / 曲间静音由上层（PlayerCubit）控制**。handler 只做
///   "加载并播放这一首"、"当前这首播完了发事件"、"暂停 / 继续 / seek"。
/// - **与 audio_service 集成**：队列（MediaItem 列表）与 queueIndex 由上层通过
///   [publishQueue] 主动刷新；播放事件通过 [playbackState] 桥接到系统 NowPlaying /
///   MediaSession / SMTC / MPRemoteCommandCenter。
/// - **系统控件的 next / previous / skipToQueueItem**：回调到外部注册的
///   [onSkipNext] / [onSkipPrevious] / [onSkipToIndex]，由 PlayerCubit 实现。
class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AudioPlayerHandler({required CustomMediaSourceResolver mediaSourceResolver})
    : _mediaSourceResolver = mediaSourceResolver,
      _audioPlayer = AudioPlayer() {
    _attachSystemBindings();
  }

  // ignore: unused_field  保留字段以便后续（自定义协议解析、封面代理等）扩展。
  final CustomMediaSourceResolver _mediaSourceResolver;
  final AudioPlayer _audioPlayer;

  /// 外部回调：系统播控请求"下一首 / 上一首 / 跳到队列某项"。
  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;
  Future<void> Function(int index)? onSkipToIndex;

  // ========= 事件流 =========

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// 自然播放完成事件（每当 processingState 从非 completed 变为 completed 时推送一次）。
  Stream<void> get trackCompletionStream => _completionController.stream;

  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  bool get isPlaying => _audioPlayer.playing;

  bool get isIdle =>
      _audioPlayer.processingState == ProcessingState.idle;

  Duration get position => _audioPlayer.position;

  final StreamController<void> _completionController =
      StreamController<void>.broadcast();
  bool _lastWasCompleted = false;

  /// 串行化加载操作，避免并发 load 导致原生层处于中间态。
  Future<void> _pendingLoad = Future<void>.value();

  // ========= 核心：加载并播放 =========

  /// 加载单首曲目的 [AudioSource] 并播放。
  ///
  /// 重要：just_audio 的 `play()` 返回的 Future **不会在"开始播放"时完成**，
  /// 而是通常要等到"播放结束 / 被 stop / 被 pause / 出错"后才 resolve。
  /// 如果这里 `await play()`，上层的切歌串行队列会被一首歌的整个播放时长卡住，
  /// 于是 `next()` / `previous()` / `playIndex()` / 队列点击切歌都会表现为失效。
  ///
  /// 因此这里的正确做法是：
  /// 1. 串行化 load；
  /// 2. 切歌前先 stop 当前源；
  /// 3. `setAudioSource` 等待加载完成；
  /// 4. `play()` 只触发，不等待其完成。
  Future<void> loadAndPlay(AudioSource source) {
    return _queueLoad(() async {
      try {
        await _audioPlayer.stop();
      } catch (_) {
        // 首次播放 / 已经 idle 时 stop 失败可忽略。
      }
      await _audioPlayer.setAudioSource(source);
      // 等待 ready 后再 play，避免在 loading/idle 中间态调用 play 无效。
      await _audioPlayer
          .playerStateStream
          .firstWhere(
            (s) =>
                s.processingState == ProcessingState.ready ||
                s.processingState == ProcessingState.completed,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => _audioPlayer.playerState,
          );
      unawaited(_audioPlayer.play());
    });
  }

  /// 仅加载、不自动播放。
  Future<void> loadOnly(AudioSource source) {
    return _queueLoad(() async {
      try {
        await _audioPlayer.stop();
      } catch (_) {}
      await _audioPlayer.setAudioSource(source);
    });
  }

  Future<void> _queueLoad(Future<void> Function() action) {
    final completer = Completer<void>();
    _pendingLoad = _pendingLoad.catchError((_) {}).then((_) async {
      try {
        await action();
        completer.complete();
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  // ========= 普通播放控制 =========

  @override
  Future<void> play() => _audioPlayer.play();

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await super.stop();
  }

  /// 清空当前加载曲目、重置播放状态。用于"清空队列"。
  Future<void> clearPlayback() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    queue.add(const []);
    mediaItem.add(null);
  }

  Future<void> setVolume(double volume) =>
      _audioPlayer.setVolume(volume.clamp(0, 1));

  Timer? _fadeTimer;

  /// 在 [duration] 内把音量线性过渡到 [target]（0.0 - 1.0）。
  Future<void> setVolumeAnimated(
    double target, {
    Duration duration = const Duration(milliseconds: 600),
  }) async {
    _fadeTimer?.cancel();
    final clampedTarget = target.clamp(0.0, 1.0).toDouble();
    final start = _audioPlayer.volume;
    if ((start - clampedTarget).abs() < 0.005 || duration.inMilliseconds <= 0) {
      await _audioPlayer.setVolume(clampedTarget);
      return;
    }

    const tickMs = 40;
    final totalTicks = (duration.inMilliseconds / tickMs).ceil();
    var elapsed = 0;
    final completer = Completer<void>();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      elapsed++;
      final t = (elapsed / totalTicks).clamp(0.0, 1.0);
      final v = start + (clampedTarget - start) * t;
      _audioPlayer.setVolume(v);
      if (elapsed >= totalTicks) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future;
  }

  // ========= 系统级播控桥接（被 audio_service / 媒体按键触发） =========

  @override
  Future<void> skipToNext() async {
    final cb = onSkipNext;
    if (cb == null) return;
    await cb();
  }

  @override
  Future<void> skipToPrevious() async {
    final cb = onSkipPrevious;
    if (cb == null) return;
    await cb();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final cb = onSkipToIndex;
    if (cb == null) return;
    await cb(index);
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    // 由 PlayerCubit 负责处理（通过 UI 操作），这里不做处理。
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    // 由 PlayerCubit 管理循环模式，这里留空以避免 audio_service 尝试调用
    // just_audio 的 LoopMode 而与我们的逻辑冲突。
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    // 同上，shuffle 由 PlayerCubit 管理。
  }

  // ========= 队列信息推送（供锁屏 / 系统控件显示） =========

  /// 由外部（PlayerCubit）在队列变化时调用，用于刷新系统面板上的歌单 + 当前项。
  void publishQueue({
    required List<MusicTrack> tracks,
    required int currentIndex,
  }) {
    final items = [for (final t in tracks) _asMediaItem(t)];
    queue.add(items);
    if (items.isEmpty) {
      mediaItem.add(null);
      return;
    }
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    mediaItem.add(items[safeIndex]);
    // 同时把 queueIndex 刷到 playbackState，让系统控件正确高亮当前项。
    playbackState.add(playbackState.value.copyWith(queueIndex: safeIndex));
  }

  Future<void> dispose() async {
    _fadeTimer?.cancel();
    try {
      await _pendingLoad;
    } catch (_) {}
    await _completionController.close();
    await _audioPlayer.dispose();
  }

  // ========= 把 just_audio 事件桥接到 audio_service =========

  void _attachSystemBindings() {
    _audioPlayer.playbackEventStream.listen(_broadcastPlaybackState);
    _audioPlayer.playerStateStream.listen((state) {
      final completedNow = state.processingState == ProcessingState.completed;
      if (completedNow && !_lastWasCompleted) {
        _lastWasCompleted = true;
        _completionController.add(null);
      } else if (!completedNow) {
        _lastWasCompleted = false;
      }
    });
    _audioPlayer.durationStream.listen((d) {
      final current = mediaItem.valueOrNull;
      if (current != null && d != null) {
        mediaItem.add(current.copyWith(duration: d));
      }
    });
  }

  void _broadcastPlaybackState(PlaybackEvent event) {
    final playing = _audioPlayer.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(event.processingState),
        playing: playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _audioPlayer.speed,
        // queueIndex 交给 publishQueue 去维护，这里不覆盖。
        queueIndex: playbackState.value.queueIndex,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  MediaItem _asMediaItem(MusicTrack track) {
    return MediaItem(
      id: track.id,
      title: track.title.isEmpty ? '未知歌曲' : track.title,
      album: track.albumTitle,
      artist: track.artistName,
      artUri: track.artworkUrl.isNotEmpty
          ? Uri.tryParse(track.artworkUrl)
          : null,
      duration: track.duration == Duration.zero ? null : track.duration,
    );
  }
}

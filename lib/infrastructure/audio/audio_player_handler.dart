import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/audio/playback_clock.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:just_audio/just_audio.dart';

final class PlaybackFailure {
  const PlaybackFailure({required this.trackId, required this.error});

  final String trackId;
  final Object error;
}

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
      _audioPlayer = AudioPlayer(
        userAgent: AppConstants.httpUserAgent,
        useProxyForRequestHeaders: false,
      ) {
    _attachSystemBindings();
  }

  // ignore: unused_field  保留字段以便后续（自定义协议解析、封面代理等）扩展。
  final CustomMediaSourceResolver _mediaSourceResolver;
  final AudioPlayer _audioPlayer;
  static const int _systemQueueWindowSize = 25;
  int _publishedQueueStartIndex = 0;

  /// 外部回调：系统播控请求"下一首 / 上一首 / 跳到队列某项"。
  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;
  Future<void> Function(int index)? onSkipToIndex;

  // ========= 事件流 =========

  Stream<Duration> get positionStream => _positionController.stream;

  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Stream<PlaybackFailure> get playbackErrorStream =>
      _playbackErrorController.stream;

  /// 自然播放完成事件。事件携带曲目 ID，避免旧音源的延迟事件推进新队列。
  Stream<String> get trackCompletionStream => _completionController.stream;

  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  bool get isPlaying => _audioPlayer.playing;

  bool get isIdle => _audioPlayer.processingState == ProcessingState.idle;

  Duration get position => _effectivePosition();

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<String> _completionController =
      StreamController<String>.broadcast();
  final StreamController<PlaybackFailure> _playbackErrorController =
      StreamController<PlaybackFailure>.broadcast();
  bool _lastWasCompleted = false;
  int _sourceGeneration = 0;
  bool _sourceReady = false;
  String? _activeTrackId;
  final PlaybackClock _playbackClock = PlaybackClock();
  Timer? _positionTicker;

  static const Duration _nativeBackwardCorrectionLimit = Duration(
    milliseconds: 500,
  );

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
  /// 2. 先暂停当前源，避免破坏性的 stop 归零；
  /// 3. `setAudioSource` 以指定位置等待加载完成；
  /// 4. `play()` 只触发，不等待其完成。
  Future<void> loadAndPlay(
    AudioSource source, {
    Duration initialPosition = Duration.zero,
  }) {
    return _queueLoad(() async {
      await _loadSource(source, initialPosition: initialPosition);
      _startPlayback();
    });
  }

  /// 在指定位置加载音源，保持暂停，由上层确认播放意图后再播放。
  Future<void> loadOnly(
    AudioSource source, {
    Duration initialPosition = Duration.zero,
  }) {
    return _queueLoad(() async {
      await _loadSource(source, initialPosition: initialPosition);
    });
  }

  Future<void> _loadSource(
    AudioSource source, {
    required Duration initialPosition,
  }) async {
    final track = source is IndexedAudioSource ? source.tag : null;
    if (track is! MusicTrack) {
      throw ArgumentError.value(track, 'source.tag', '必须是 MusicTrack');
    }
    _sourceReady = false;
    _activeTrackId = null;
    _playbackClock.reset(position: initialPosition, duration: track.duration);
    _sourceGeneration += 1;
    await _audioPlayer.pause();
    await _audioPlayer.setAudioSource(source, initialPosition: initialPosition);
    _activeTrackId = track.id;
    _sourceReady = true;
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
  Future<void> play() async {
    _startPlayback();
  }

  void _startPlayback() {
    final generation = _sourceGeneration;
    final trackId = _activeTrackId;
    if (!_sourceReady || trackId == null) return;
    _playbackClock.start(speed: _audioPlayer.speed);
    unawaited(
      _audioPlayer.play().catchError((Object error, StackTrace _) {
        if (generation == _sourceGeneration &&
            trackId == _activeTrackId &&
            !_playbackErrorController.isClosed) {
          _playbackErrorController.add(
            PlaybackFailure(trackId: trackId, error: error),
          );
        }
      }),
    );
  }

  @override
  Future<void> pause() async {
    final preservedPosition = position;
    _playbackClock.pause();
    await _audioPlayer.pause();
    if ((_audioPlayer.position - preservedPosition).abs() >
        const Duration(milliseconds: 500)) {
      await _audioPlayer.seek(preservedPosition);
    }
    _playbackClock.seek(preservedPosition);
  }

  @override
  Future<void> seek(Duration position) async {
    _playbackClock.seek(position);
    await _audioPlayer.seek(position);
    _emitPosition();
  }

  @override
  Future<void> stop() async {
    _sourceReady = false;
    _activeTrackId = null;
    _playbackClock.reset();
    _sourceGeneration += 1;
    await _audioPlayer.stop();
    await super.stop();
  }

  /// 清空当前加载曲目、重置播放状态。用于"清空队列"。
  Future<void> clearPlayback() async {
    _sourceReady = false;
    _activeTrackId = null;
    _playbackClock.reset();
    _sourceGeneration += 1;
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
    await cb(_publishedQueueStartIndex + index);
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
    if (tracks.isEmpty) {
      _publishedQueueStartIndex = 0;
      queue.add(const []);
      mediaItem.add(null);
      playbackState.add(playbackState.value.copyWith(queueIndex: null));
      return;
    }

    final safeIndex = currentIndex.clamp(0, tracks.length - 1).toInt();
    final halfWindow = _systemQueueWindowSize ~/ 2;
    final maxStart = (tracks.length - _systemQueueWindowSize).clamp(
      0,
      tracks.length,
    );
    final start = (safeIndex - halfWindow).clamp(0, maxStart).toInt();
    final end = (start + _systemQueueWindowSize).clamp(start, tracks.length);
    final windowTracks = tracks.sublist(start, end);
    final items = [for (final t in windowTracks) _asMediaItem(t)];
    final queueIndex = safeIndex - start;

    _publishedQueueStartIndex = start;
    queue.add(items);
    mediaItem.add(items[queueIndex]);
    // 同时把 queueIndex 刷到 playbackState，让系统控件正确高亮当前项。
    playbackState.add(playbackState.value.copyWith(queueIndex: queueIndex));
  }

  Future<void> dispose() async {
    _fadeTimer?.cancel();
    _positionTicker?.cancel();
    try {
      await _pendingLoad;
    } catch (_) {}
    await _positionController.close();
    await _completionController.close();
    await _playbackErrorController.close();
    await _audioPlayer.dispose();
  }

  // ========= 把 just_audio 事件桥接到 audio_service =========

  void _attachSystemBindings() {
    _audioPlayer.playbackEventStream.listen((event) {
      _synchronizePlaybackClock(event);
      _broadcastPlaybackState(event);
      _emitPosition();
    });
    _audioPlayer.playerStateStream.listen((state) {
      _updatePositionTicker(state);
      final completedNow = state.processingState == ProcessingState.completed;
      if (completedNow && !_lastWasCompleted) {
        _lastWasCompleted = true;
        final trackId = _activeTrackId;
        if (_sourceReady &&
            trackId != null &&
            !_completionController.isClosed) {
          _completionController.add(trackId);
        }
      } else if (!completedNow) {
        _lastWasCompleted = false;
      }
    });
    _audioPlayer.durationStream.listen((d) {
      _playbackClock.setDuration(d ?? mediaItem.valueOrNull?.duration);
      final current = mediaItem.valueOrNull;
      if (current != null && d != null) {
        mediaItem.add(current.copyWith(duration: d));
      }
    });
  }

  Duration _effectivePosition() => _playbackClock.position;

  void _synchronizePlaybackClock(PlaybackEvent event) {
    if (!_sourceReady) return;
    final duration =
        event.duration ??
        _audioPlayer.duration ??
        mediaItem.valueOrNull?.duration;
    _playbackClock.setDuration(duration);

    switch (event.processingState) {
      case ProcessingState.ready:
        final elapsed = _audioPlayer.playing
            ? DateTime.now().difference(event.updateTime)
            : Duration.zero;
        final nativePosition = elapsed.isNegative
            ? event.updatePosition
            : event.updatePosition + elapsed * _audioPlayer.speed;
        _playbackClock.synchronize(
          nativePosition,
          allowBackward: true,
          // Continuous playback only accepts small phase corrections. Large
          // backward jumps are stale proxy/native samples; explicit seeks and
          // pauses already re-anchor the clock through their control paths.
          maxBackwardCorrection: _audioPlayer.playing
              ? _nativeBackwardCorrectionLimit
              : null,
        );
        if (_audioPlayer.playing) {
          _playbackClock.start(speed: _audioPlayer.speed);
        } else {
          _playbackClock.pause();
        }
        break;
      case ProcessingState.buffering:
        _playbackClock.synchronize(event.updatePosition, allowBackward: false);
        // playing 只表示用户仍有播放意图；buffering 期间没有音频产出，时间轴
        // 必须冻结。否则网络或解码卡顿会被伪装成“进度正常但突然没声音”。
        _playbackClock.pause();
        break;
      case ProcessingState.completed:
        _playbackClock.complete(nativePosition: event.updatePosition);
        break;
      case ProcessingState.idle:
      case ProcessingState.loading:
        _playbackClock.pause();
        break;
    }
  }

  void _updatePositionTicker(PlayerState state) {
    final shouldTick =
        state.playing && state.processingState == ProcessingState.ready;
    if (!shouldTick) {
      _positionTicker?.cancel();
      _positionTicker = null;
      _emitPosition();
      return;
    }
    _positionTicker ??= Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _emitPosition(),
    );
    _emitPosition();
  }

  void _emitPosition() {
    if (!_sourceReady || _positionController.isClosed) return;
    final currentPosition = _effectivePosition();
    _positionController.add(currentPosition);
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
        updatePosition: _sourceReady
            ? _effectivePosition()
            : event.updatePosition,
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

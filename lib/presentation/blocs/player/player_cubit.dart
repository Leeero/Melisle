import 'dart:async';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/play_queue.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/audio/audio_player_handler.dart';
import 'package:cross_platform_music_player/infrastructure/audio/sleep_timer.dart';
import 'package:cross_platform_music_player/infrastructure/audio/track_resolver.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

/// 播放页 / 迷你播放条的状态管理。
///
/// 架构：
/// - 维护一份 [PlayQueue]（不可变逻辑队列 + 当前索引 + 循环 / 随机状态）；
/// - 每次切歌都走同一条路径：`_playAt(index)` → `TrackResolver.resolve` →
///   `AudioPlayerHandler.loadAndPlay`；
/// - 上 / 下一曲 / playIndex / 队列条目点击都是 `_playAt` 的薄包装；
/// - 上层播放完成事件（`AudioPlayerHandler.trackCompletionStream`）触发"自动进入下一首"
///   （包含循环 / 随机 / 曲间静音处理）。
class PlayerCubit extends Cubit<PlayerViewState> {
  PlayerCubit({
    required MusicRepository repository,
    required AudioPlayerHandler controller,
    AppDatabase? database,
  }) : _resolver = TrackResolver(repository: repository, database: database),
       _repository = repository,
       _controller = controller,
       _database = database,
       super(const PlayerViewState()) {
    // 订阅底层 player 的事件流。
    _subscriptions.add(_controller.positionStream.listen(_onPositionChanged));
    _subscriptions.add(_controller.durationStream.listen(_onDurationChanged));
    _subscriptions.add(
      _controller.playerStateStream.listen(_onPlayerStateChanged),
    );
    _subscriptions.add(
      _controller.trackCompletionStream.listen((_) {
        _onTrackCompleted();
      }),
    );
    _subscriptions.add(_controller.volumeStream.listen(_onVolumeChanged));

    // 让系统媒体键 / 锁屏按钮能调用我们的 next / previous / skipTo 逻辑。
    _controller.onSkipNext = next;
    _controller.onSkipPrevious = previous;
    _controller.onSkipToIndex = playIndex;
  }

  final MusicRepository _repository;
  final AudioPlayerHandler _controller;
  final AppDatabase? _database;
  final TrackResolver _resolver;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final SleepTimer _sleepTimer = SleepTimer();
  Timer? _sleepTicker;
  Timer? _reportProgressTimer;

  static const _uuid = Uuid();

  /// 播放全部曲目的队列上限，防止内存溢出。
  static const int _maxQueueSize = 500;

  /// 当前逻辑队列。
  PlayQueue _queue = const PlayQueue.empty();

  /// 发起的最新一次 [_playAt] 对应的 token。若 token 在异步解析 URL 时被
  /// 替换（= 用户又点了新歌），则丢弃这次结果、不影响新播放。
  int _playToken = 0;

  /// 发起的最新一次歌词加载 token。设置变更或切歌时用于丢弃旧歌词请求。
  int _lyricsToken = 0;

  /// 串行化所有"会改变当前播放"的操作（playTracks / playIndex / next / previous /
  /// onTrackCompleted），避免并发打架。
  Future<void> _serialTail = Future<void>.value();

  /// 暂停过程中屏蔽 positionStream 的虚假归零。
  bool _pausingGuard = false;

  /// seek 后的最新位置，用于屏蔽 positionStream 中过期的旧位置事件。
  /// 在 [seek] 中设置，在收到有效位置事件或切歌时清空。
  Duration? _lastSeekPosition;

  /// 两首之间的静音间隔，默认为 0（无间隔）。
  Duration _gapBetweenTracks = Duration.zero;

  /// 正在等待 gap 结束的定时器。下一次任何操作（play / skip / stop）都应取消它。
  Timer? _gapTimer;

  /// 外部（AppSettingsCubit）通知切换间隔时长；立即生效，不需要重建队列。
  void setGapBetweenTracks(Duration gap) {
    _gapBetweenTracks = gap < Duration.zero ? Duration.zero : gap;
    emit(state.copyWith(gapBetweenTracks: _gapBetweenTracks));
  }

  /// 外部（AppSettingsCubit）通知歌词整体同步偏移；立即重新计算当前高亮行。
  /// 正值表示歌词提前显示，负值表示歌词延后显示。
  void setLyricSyncOffset(Duration offset) {
    emit(
      state.copyWith(
        lyricSyncOffset: offset,
        currentLyricIndex: _findLyricIndex(
          state.lyrics,
          _lyricLookupPosition(state.position, offset),
        ),
      ),
    );
  }

  /// 每次播放上报使用的会话 ID（全程保持，直到切歌）。
  String? _playSessionId;
  String? _reportedStartTrackId;
  int? _currentHistoryRowId;
  int? _currentHistoryStartMs;

  // ========= 对外 API =========

  /// 用一组新的曲目替换当前队列并开始播放。
  Future<void> playTracks(List<MusicTrack> tracks, {int startIndex = 0}) {
    return _enqueueSerial(() async {
      if (tracks.isEmpty) return;

      final effectiveTracks = tracks.length > _maxQueueSize
          ? tracks.sublist(0, _maxQueueSize)
          : tracks;
      final safeStart = startIndex.clamp(0, effectiveTracks.length - 1);

      _playbackRevision++;
      _queue = _queue.replaceAll(effectiveTracks, startIndex: safeStart);
      _publishQueueToSystem();
      emit(
        state.copyWith(
          queue: _queue.tracks,
          currentIndex: _queue.currentIndex,
          isLoading: true,
          errorMessage: null,
          lyrics: const [],
          currentLyricIndex: null,
          position: Duration.zero,
          duration: Duration.zero,
        ),
      );

      await _playCurrentTrack();
    });
  }

  /// 追加一首曲目到当前队列末尾。空队列时等价于从头播放。
  Future<void> addToQueue(MusicTrack track) {
    return _enqueueSerial(() async {
      if (_queue.isEmpty) {
        _queue = _queue.replaceAll([track], startIndex: 0);
        _publishQueueToSystem();
        emit(
          state.copyWith(
            queue: _queue.tracks,
            currentIndex: 0,
            isLoading: true,
            errorMessage: null,
          ),
        );
        await _playCurrentTrack();
        return;
      }
      _queue = _queue.append([track]);
      _publishQueueToSystem();
      emit(state.copyWith(queue: _queue.tracks));
    });
  }

  /// 当前播放标识：每次 [playTracks] / [playIndex] 都会递增，配合
  /// [appendTracksIfRevisionMatches] 用于"后台补齐全量"的场景。
  int get playbackRevision => _playbackRevision;
  int _playbackRevision = 0;

  /// 仅当当前这一轮播放仍然匹配 [expectedRevision]，且队列头部与 [initialTracks]
  /// 一致时，把 [allTracks] 的尾部追加到队列末尾。用于"播放全部"时先用分页数据
  /// 立即起播、再后台补齐完整列表的场景。
  ///
  /// 不会触发切歌 / 重建播放。
  Future<void> appendTracksIfRevisionMatches({
    required int expectedRevision,
    required List<MusicTrack> initialTracks,
    required List<MusicTrack> allTracks,
  }) async {
    if (_playbackRevision != expectedRevision ||
        initialTracks.isEmpty ||
        allTracks.isEmpty) {
      return;
    }

    final effectiveAll = allTracks.length > _maxQueueSize
        ? allTracks.sublist(0, _maxQueueSize)
        : allTracks;
    if (effectiveAll.length <= initialTracks.length) return;
    if (_queue.tracks.length != initialTracks.length) return;
    if (!_queueHasPrefix(_queue.tracks, initialTracks)) return;
    if (!_queueHasPrefix(effectiveAll, initialTracks)) return;

    final suffix = effectiveAll.sublist(initialTracks.length);
    if (suffix.isEmpty) return;

    _queue = _queue.append(suffix);
    _publishQueueToSystem();
    emit(state.copyWith(queue: _queue.tracks));
  }

  bool _queueHasPrefix(List<MusicTrack> queue, List<MusicTrack> prefix) {
    if (queue.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (queue[i].id != prefix[i].id) return false;
    }
    return true;
  }

  Future<void> playIndex(int index) {
    return _enqueueSerial(() async {
      if (index < 0 || index >= _queue.tracks.length) return;
      _queue = _queue.moveTo(index);
      _publishQueueToSystem();
      emit(
        state.copyWith(
          currentIndex: _queue.currentIndex,
          isLoading: true,
          errorMessage: null,
          position: Duration.zero,
          duration: Duration.zero,
          lyrics: const [],
          currentLyricIndex: null,
        ),
      );
      await _playCurrentTrack();
    });
  }

  Future<void> next() {
    return _enqueueSerial(() async {
      final nextIdx = _queue.nextIndex();
      if (nextIdx == null) {
        // 没有下一曲（顺序模式 + 最后一首），不做任何事。
        return;
      }
      _queue = _queue.moveTo(nextIdx);
      _publishQueueToSystem();
      emit(
        state.copyWith(
          currentIndex: _queue.currentIndex,
          isLoading: true,
          errorMessage: null,
          position: Duration.zero,
          duration: Duration.zero,
          lyrics: const [],
          currentLyricIndex: null,
        ),
      );
      await _playCurrentTrack();
    });
  }

  Future<void> previous() {
    return _enqueueSerial(() async {
      final prevIdx = _queue.previousIndex();
      if (prevIdx == null) {
        // 没有上一曲（顺序模式 + 第一首）—— 不做任何事，保持当前播放状态。
        return;
      }
      _queue = _queue.moveTo(prevIdx);
      _publishQueueToSystem();
      emit(
        state.copyWith(
          currentIndex: _queue.currentIndex,
          isLoading: true,
          errorMessage: null,
          position: Duration.zero,
          duration: Duration.zero,
          lyrics: const [],
          currentLyricIndex: null,
        ),
      );
      await _playCurrentTrack();
    });
  }

  Future<void> togglePlayback() async {
    _cancelGap();
    if (state.isPlaying) {
      _pausingGuard = true;
      await _controller.pause();
      _pausingGuard = false;
      return;
    }
    // 空队列，无事可做。
    if (_queue.isEmpty) return;

    // 若当前播放已完成（processingState == completed）或 position 已经抵达末尾，
    // 点击"播放"期望"从当前曲开头重新播放"—— 这是绝大多数播放器的行为。
    // 通过重新 loadAndPlay 当前曲目来避免 just_audio 在 completed 状态下 play()
    // 立刻再次 complete 的问题。
    final dur = state.duration;
    final hasReachedEnd =
        dur > Duration.zero &&
        state.position + const Duration(milliseconds: 300) >= dur;
    // handler 处于 idle 时说明 source 未加载（例如切歌后加载失败，或刚启动），
    // 此时直接 play() 无效，需要重新走 loadAndPlay 流程。
    final handlerIsIdle = !_controller.isPlaying && _controller.isIdle;
    if (hasReachedEnd || state.currentTrack == null || handlerIsIdle) {
      await _enqueueSerial(() async => _playCurrentTrack());
      return;
    }
    await _controller.play();
  }

  Future<void> seek(Duration position) async {
    final target = _clampSeekPosition(position);
    await _controller.seek(target);

    // 使用 target（已 clamp）而非 _controller.position：just_audio seek 后
    // position 未必立即更新到新值，读取旧位置会导致 state 回滚，歌词高亮闪回。
    final effectiveDuration = _durationCoveringPosition(target);
    _lastSeekPosition = target;

    emit(state.copyWith(position: target, duration: effectiveDuration));
    // seek 后立即更新歌词高亮，避免被旧播放位置的 _onPositionChanged 覆盖。
    _updateLyricHighlight(target);
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    // ReorderableListView 的 newIndex 约定：移出后的位置（插入点），实际目标索引要 -1。
    final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    if (oldIndex < 0 ||
        oldIndex >= _queue.tracks.length ||
        targetIndex < 0 ||
        targetIndex >= _queue.tracks.length ||
        oldIndex == targetIndex) {
      return;
    }
    _queue = _queue.move(oldIndex, targetIndex);
    _publishQueueToSystem();
    emit(
      state.copyWith(queue: _queue.tracks, currentIndex: _queue.currentIndex),
    );
  }

  Future<void> removeQueueItem(int index) async {
    if (index < 0 || index >= _queue.tracks.length) return;
    final removingCurrent = index == _queue.currentIndex;
    _queue = _queue.removeAt(index);
    _publishQueueToSystem();

    if (_queue.isEmpty) {
      await clearQueue();
      return;
    }

    if (removingCurrent) {
      // 当前曲被删掉 → 立刻播新当前位置（moveAt 已经 clamp 过）。
      emit(
        state.copyWith(
          queue: _queue.tracks,
          currentIndex: _queue.currentIndex,
          position: Duration.zero,
          duration: Duration.zero,
          lyrics: const [],
          currentLyricIndex: null,
        ),
      );
      await _enqueueSerial(() async => _playCurrentTrack());
      return;
    }

    emit(
      state.copyWith(
        queue: _queue.tracks,
        currentIndex: _queue.currentIndex,
        errorMessage: null,
      ),
    );
  }

  Future<void> clearQueue() async {
    _cancelGap();
    _playToken++; // 让任何正在解析的 _playAt 作废
    _playbackRevision++;
    _queue = const PlayQueue.empty();
    await _controller.clearPlayback();
    _stopProgressReporting();
    _playSessionId = null;
    _reportedStartTrackId = null;
    emit(
      state.copyWith(
        queue: const [],
        currentIndex: 0,
        isPlaying: false,
        isLoading: false,
        position: Duration.zero,
        duration: Duration.zero,
        errorMessage: null,
        lyrics: const [],
        currentLyricIndex: null,
      ),
    );
  }

  // ========= 循环 / 随机 =========

  Future<void> toggleLoopMode() async {
    final next = switch (_queue.loopMode) {
      QueueLoopMode.off => QueueLoopMode.all,
      QueueLoopMode.all => QueueLoopMode.one,
      QueueLoopMode.one => QueueLoopMode.off,
    };
    _queue = _queue.withLoopMode(next);
    emit(state.copyWith(loopMode: _toJustAudioLoop(next)));
  }

  Future<void> toggleShuffle() async {
    _queue = _queue.withShuffle(!_queue.shuffleEnabled);
    emit(state.copyWith(shuffleEnabled: _queue.shuffleEnabled));
  }

  Future<void> cyclePlaybackMode() async {
    final next = switch (state.playbackMode) {
      PlaybackModeOption.sequence => PlaybackModeOption.loopAll,
      PlaybackModeOption.loopAll => PlaybackModeOption.loopOne,
      PlaybackModeOption.loopOne => PlaybackModeOption.shuffle,
      PlaybackModeOption.shuffle => PlaybackModeOption.sequence,
    };
    await setPlaybackMode(next);
  }

  Future<void> setPlaybackMode(PlaybackModeOption mode) async {
    switch (mode) {
      case PlaybackModeOption.sequence:
        _queue = _queue.withLoopMode(QueueLoopMode.off).withShuffle(false);
        break;
      case PlaybackModeOption.loopAll:
        _queue = _queue.withLoopMode(QueueLoopMode.all).withShuffle(false);
        break;
      case PlaybackModeOption.loopOne:
        _queue = _queue.withLoopMode(QueueLoopMode.one).withShuffle(false);
        break;
      case PlaybackModeOption.shuffle:
        _queue = _queue.withLoopMode(QueueLoopMode.off).withShuffle(true);
        break;
    }
    emit(
      state.copyWith(
        loopMode: _toJustAudioLoop(_queue.loopMode),
        shuffleEnabled: _queue.shuffleEnabled,
      ),
    );
  }

  LoopMode _toJustAudioLoop(QueueLoopMode mode) {
    switch (mode) {
      case QueueLoopMode.off:
        return LoopMode.off;
      case QueueLoopMode.all:
        return LoopMode.all;
      case QueueLoopMode.one:
        return LoopMode.one;
    }
  }

  Future<void> setVolume(double volume) async {
    await _controller.setVolume(volume);
  }

  Future<void> setQuality(AudioQuality quality) async {
    if (quality == state.quality) return;
    emit(state.copyWith(quality: quality));
  }

  // ========= 核心：加载并播放当前曲目 =========

  /// 把 `_queue.currentTrack` 解析为 AudioSource 并交给 handler 加载播放。
  ///
  /// 调用方必须保证自己正位于 [_enqueueSerial] 的执行链中，以防并发。
  ///
  /// [_playToken] 机制：如果本方法执行期间又发起了新的切歌请求，
  /// 新的请求会递增 [_playToken]，导致本次请求的所有后续操作都被跳过。
  Future<void> _playCurrentTrack() async {
    _cancelGap();
    final track = _queue.currentTrack;
    if (track == null) return;

    // 切歌时清除 seek 过期位置守卫，避免新曲目首个 position 事件被误屏蔽。
    _lastSeekPosition = null;

    final myToken = ++_playToken;
    try {
      final source = await _resolver.resolve(track, quality: state.quality);
      if (myToken != _playToken || isClosed) return;
      await _controller.loadAndPlay(source);
      if (myToken != _playToken || isClosed) return;
      // 只有"本次请求仍然有效"时才更新状态，避免旧请求覆盖新状态。
      emit(state.copyWith(isLoading: false, errorMessage: null));
      _loadLyricsForCurrent();
      _reportStoppedIfNeeded();
      _reportStartForCurrent();
    } catch (error) {
      if (myToken != _playToken || isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: '播放失败：$error'));
    }
  }

  /// 把所有"会切歌 / 重置播放"的操作串行化，避免竞态。
  ///
  /// 实现说明：
  /// - 用 [_serialTail] 保证同一时间只有一个 action 在执行。
  /// - action 的异常会被捕获并传递给返回的 Future，不会污染 [_serialTail]。
  /// - 如果 Cubit 已关闭，返回的 Future 会以 StateError 拒绝。
  Future<T> _enqueueSerial<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final oldTail = _serialTail;
    _serialTail = oldTail
        .then((_) async {
          if (isClosed) {
            completer.completeError(StateError('PlayerCubit is closed'));
            return;
          }
          try {
            completer.complete(await action());
          } catch (e, st) {
            completer.completeError(e, st);
          }
        })
        .catchError((_) {
          // oldTail 的异常已经被处理过了，这里吞掉，不影响后续链条。
        });
    return completer.future;
  }

  void _publishQueueToSystem() {
    _controller.publishQueue(
      tracks: _queue.tracks,
      currentIndex: _queue.currentIndex,
    );
  }

  // ========= player 事件处理 =========

  void _onPositionChanged(Duration position) {
    if (_pausingGuard) return;

    // seek 后 positionStream 可能投递过期位置，与 seek 目标偏差 >500ms 则屏蔽。
    if (_lastSeekPosition != null) {
      if ((position - _lastSeekPosition!).abs() >
          const Duration(milliseconds: 500)) {
        return;
      }
      _lastSeekPosition = null;
    }

    emit(state.copyWith(position: position));
    _updateLyricHighlight(position);
  }

  void _onDurationChanged(Duration? duration) {
    final resolvedDuration = duration ?? Duration.zero;
    emit(
      state.copyWith(duration: _maxDuration(resolvedDuration, state.position)),
    );
  }

  Duration _clampSeekPosition(Duration position) {
    if (position.isNegative) return Duration.zero;
    final duration = state.duration;
    if (duration > Duration.zero && position > duration) {
      return duration;
    }
    return position;
  }

  Duration _durationCoveringPosition(Duration position) {
    return _maxDuration(state.duration, position);
  }

  Duration _maxDuration(Duration a, Duration b) {
    return a >= b ? a : b;
  }

  void _onPlayerStateChanged(PlayerState playerState) {
    final nowPlaying = playerState.playing;
    final wasPlaying = state.isPlaying;

    final isBusy =
        playerState.processingState == ProcessingState.loading ||
        playerState.processingState == ProcessingState.buffering;

    emit(state.copyWith(isLoading: isBusy, isPlaying: nowPlaying));

    if (nowPlaying && !wasPlaying) {
      _startProgressReporting();
    } else if (!nowPlaying && wasPlaying) {
      _stopProgressReporting();
    }
  }

  /// 自然播完（来自 [AudioPlayerHandler.trackCompletionStream]）。
  void _onTrackCompleted() {
    if (isClosed) return;

    // "本曲结束"睡眠 → 不进入下一曲，先触发睡眠回调再 return。
    if (state.sleepEndOfTrack) {
      _sleepTimer.fireNow();
      return;
    }

    final targetIndex = _queue.autoAdvanceIndex();
    if (targetIndex == null) {
      // 没有下一曲 —— 停在当前位置末尾。
      return;
    }

    // 曲间静音：延迟后再播下一曲。
    if (_gapBetweenTracks > Duration.zero) {
      _gapTimer?.cancel();
      _gapTimer = Timer(_gapBetweenTracks, () {
        _gapTimer = null;
        _advanceTo(targetIndex);
      });
      return;
    }
    _advanceTo(targetIndex);
  }

  void _advanceTo(int index) {
    _enqueueSerial(() async {
      if (index < 0 || index >= _queue.tracks.length) return;
      _queue = _queue.moveTo(index);
      _publishQueueToSystem();
      emit(
        state.copyWith(
          currentIndex: _queue.currentIndex,
          isLoading: true,
          errorMessage: null,
          position: Duration.zero,
          duration: Duration.zero,
          lyrics: const [],
          currentLyricIndex: null,
        ),
      );
      await _playCurrentTrack();
    });
  }

  void _cancelGap() {
    _gapTimer?.cancel();
    _gapTimer = null;
  }

  void _onVolumeChanged(double volume) {
    emit(state.copyWith(volume: volume));
  }

  // ========= 歌词 =========

  Future<void> reloadLyricsForCurrent() {
    return _loadLyricsForCurrent();
  }

  Future<void> _loadLyricsForCurrent() async {
    final track = _queue.currentTrack;
    if (track == null) return;
    final trackId = track.id;
    final myToken = ++_lyricsToken;

    emit(state.copyWith(isLyricsLoading: true));
    try {
      final lyrics = await _repository.fetchLyrics(trackId);
      if (myToken != _lyricsToken ||
          _queue.currentTrack?.id != trackId ||
          isClosed) {
        return;
      }
      if (lyrics == null || lyrics.isEmpty) {
        emit(
          state.copyWith(
            isLyricsLoading: false,
            lyrics: const [],
            currentLyricIndex: null,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isLyricsLoading: false,
          lyrics: lyrics,
          currentLyricIndex: _findLyricIndex(
            lyrics,
            _lyricLookupPosition(state.position, state.lyricSyncOffset),
          ),
        ),
      );
    } catch (_) {
      if (myToken != _lyricsToken ||
          _queue.currentTrack?.id != trackId ||
          isClosed) {
        return;
      }
      emit(
        state.copyWith(
          isLyricsLoading: false,
          lyrics: const [],
          currentLyricIndex: null,
        ),
      );
    }
  }

  void _updateLyricHighlight(Duration position) {
    final lyrics = state.lyrics;
    if (lyrics.isEmpty) return;
    final idx = _findLyricIndex(
      lyrics,
      _lyricLookupPosition(position, state.lyricSyncOffset),
    );
    if (idx != state.currentLyricIndex) {
      emit(state.copyWith(currentLyricIndex: idx));
    }
  }

  int? _findLyricIndex(List<LyricLine> lyrics, Duration position) {
    if (lyrics.isEmpty) return null;
    if (position < lyrics.first.start) return null;
    var lo = 0;
    var hi = lyrics.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lyrics[mid].start <= position) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  Future<void> seekToLyricIndex(int index) async {
    if (index < 0 || index >= state.lyrics.length) return;
    final target = state.lyrics[index].start - state.lyricSyncOffset;
    await seek(target.isNegative ? Duration.zero : target);
  }

  Duration _lyricLookupPosition(Duration position, Duration offset) {
    final shifted = position + offset;
    return shifted.isNegative ? Duration.zero : shifted;
  }

  // ========= 睡眠定时器 =========

  Future<void> startSleepTimer(Duration duration) async {
    _sleepTicker?.cancel();
    _sleepTimer.startCountdown(duration, _onSleepFired);
    emit(state.copyWith(sleepRemaining: duration, sleepEndOfTrack: false));
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _sleepTimer.remaining;
      if (left == null) {
        _sleepTicker?.cancel();
        _sleepTicker = null;
        return;
      }
      emit(state.copyWith(sleepRemaining: left));
    });
  }

  Future<void> startSleepTimerEndOfTrack() async {
    _sleepTicker?.cancel();
    _sleepTimer.startEndOfTrack(_onSleepFired);
    emit(state.copyWith(sleepRemaining: null, sleepEndOfTrack: true));
  }

  Future<void> cancelSleepTimer() async {
    _sleepTicker?.cancel();
    _sleepTicker = null;
    _sleepTimer.cancel();
    emit(state.copyWith(sleepRemaining: null, sleepEndOfTrack: false));
  }

  Future<void> _onSleepFired() async {
    _sleepTicker?.cancel();
    _sleepTicker = null;
    emit(state.copyWith(sleepRemaining: null, sleepEndOfTrack: false));
    _pausingGuard = true;
    await _controller.pause();
    _pausingGuard = false;
  }

  // ========= 播放上报 =========

  void _startProgressReporting() {
    _reportProgressTimer?.cancel();
    _reportProgressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final track = state.currentTrack;
      final sessionId = _playSessionId;
      if (track == null || sessionId == null) return;
      _repository
          .reportPlaybackProgress(
            track.id,
            sessionId,
            state.position,
            isPaused: !state.isPlaying,
          )
          .catchError((_) {});
    });
  }

  void _stopProgressReporting() {
    _reportProgressTimer?.cancel();
    _reportProgressTimer = null;
    final track = state.currentTrack;
    final sessionId = _playSessionId;
    if (track != null && sessionId != null) {
      _repository
          .reportPlaybackProgress(
            track.id,
            sessionId,
            state.position,
            isPaused: true,
          )
          .catchError((_) {});
    }
  }

  void _reportStartForCurrent() {
    final track = _queue.currentTrack;
    if (track == null) return;
    if (_reportedStartTrackId == track.id) return;
    final sessionId = _uuid.v4();
    _playSessionId = sessionId;
    _reportedStartTrackId = track.id;
    _repository.reportPlaybackStart(track.id, sessionId).catchError((_) {});
    _recordLocalHistoryStart(track);
  }

  void _reportStoppedIfNeeded() {
    final previousTrackId = _reportedStartTrackId;
    final sessionId = _playSessionId;
    if (previousTrackId == null || sessionId == null) return;
    _repository
        .reportPlaybackStopped(previousTrackId, sessionId, state.position)
        .catchError((_) {});
    _finalizeLocalHistoryEntry();
    _reportedStartTrackId = null;
    _playSessionId = null;
  }

  // ---- Local play history (drift) -----------------------------------------

  void _recordLocalHistoryStart(MusicTrack track) {
    final db = _database;
    if (db == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _currentHistoryStartMs = nowMs;
    _currentHistoryRowId = null;
    db
        .insertPlayHistory(
          PlayHistoryCompanion.insert(
            trackId: track.id,
            title: track.title,
            artistName: Value(track.artistName),
            albumTitle: Value(track.albumTitle),
            albumId: Value(track.albumId),
            artistId: Value(track.artistId),
            artworkUrl: Value(track.artworkUrl),
            playedAtMs: nowMs,
          ),
        )
        .then((id) {
          _currentHistoryRowId = id;
        })
        .catchError((_) {});
  }

  void _finalizeLocalHistoryEntry() {
    final db = _database;
    final rowId = _currentHistoryRowId;
    final startMs = _currentHistoryStartMs;
    if (db == null || rowId == null || startMs == null) {
      _currentHistoryRowId = null;
      _currentHistoryStartMs = null;
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final playedMs = (nowMs - startMs).clamp(0, 1 << 30);
    db
        .customUpdate(
          'UPDATE play_history SET duration_played_ms = ? WHERE id = ?',
          variables: [Variable<int>(playedMs), Variable<int>(rowId)],
          updates: {db.playHistory},
        )
        .catchError((_) {
          return 0;
        });
    _currentHistoryRowId = null;
    _currentHistoryStartMs = null;
  }

  @override
  Future<void> close() async {
    _cancelGap();
    _reportProgressTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimer.cancel();
    _reportStoppedIfNeeded();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _controller.dispose();
    return super.close();
  }
}

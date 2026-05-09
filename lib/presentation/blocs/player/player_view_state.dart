import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:just_audio/just_audio.dart';

enum PlaybackModeOption { sequence, loopAll, loopOne, shuffle }

class PlayerViewState {
  const PlayerViewState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.loopMode = LoopMode.off,
    this.shuffleEnabled = false,
    this.volume = 1,
    this.errorMessage,
    this.quality = AudioQuality.auto,
    this.lyrics = const [],
    this.currentLyricIndex,
    this.isLyricsLoading = false,
    this.sleepRemaining,
    this.sleepEndOfTrack = false,
    this.gapBetweenTracks = Duration.zero,
    this.lyricSyncOffset = Duration.zero,
  });

  final List<MusicTrack> queue;
  final int currentIndex;
  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final LoopMode loopMode;
  final bool shuffleEnabled;
  final double volume;
  final String? errorMessage;

  /// 当前播放音质。
  final AudioQuality quality;

  /// 当前歌曲的同步歌词（空列表 = 无 / 未加载完）。
  final List<LyricLine> lyrics;

  /// 当前高亮行索引（null = 没有可高亮的行）。
  final int? currentLyricIndex;

  /// 正在拉取歌词。
  final bool isLyricsLoading;

  /// 睡眠定时器剩余（null = 未启用）。
  final Duration? sleepRemaining;

  /// 睡眠定时器"本曲结束"模式。
  final bool sleepEndOfTrack;

  /// 曲目间插入的静音时长。
  final Duration gapBetweenTracks;

  /// 歌词高亮使用的整体偏移。正值表示歌词提前显示，负值表示歌词延后显示。
  final Duration lyricSyncOffset;

  MusicTrack? get currentTrack {
    if (queue.isEmpty || currentIndex < 0 || currentIndex >= queue.length) {
      return null;
    }

    return queue[currentIndex];
  }

  PlaybackModeOption get playbackMode {
    if (shuffleEnabled) {
      return PlaybackModeOption.shuffle;
    }

    return switch (loopMode) {
      LoopMode.all => PlaybackModeOption.loopAll,
      LoopMode.one => PlaybackModeOption.loopOne,
      LoopMode.off => PlaybackModeOption.sequence,
    };
  }

  PlayerViewState copyWith({
    List<MusicTrack>? queue,
    int? currentIndex,
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    LoopMode? loopMode,
    bool? shuffleEnabled,
    double? volume,
    String? errorMessage,
    AudioQuality? quality,
    List<LyricLine>? lyrics,
    Object? currentLyricIndex = _noChange,
    bool? isLyricsLoading,
    Object? sleepRemaining = _noChange,
    bool? sleepEndOfTrack,
    Duration? gapBetweenTracks,
    Duration? lyricSyncOffset,
  }) {
    return PlayerViewState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      loopMode: loopMode ?? this.loopMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      volume: volume ?? this.volume,
      errorMessage: errorMessage,
      quality: quality ?? this.quality,
      lyrics: lyrics ?? this.lyrics,
      currentLyricIndex: identical(currentLyricIndex, _noChange)
          ? this.currentLyricIndex
          : currentLyricIndex as int?,
      isLyricsLoading: isLyricsLoading ?? this.isLyricsLoading,
      sleepRemaining: identical(sleepRemaining, _noChange)
          ? this.sleepRemaining
          : sleepRemaining as Duration?,
      sleepEndOfTrack: sleepEndOfTrack ?? this.sleepEndOfTrack,
      gapBetweenTracks: gapBetweenTracks ?? this.gapBetweenTracks,
      lyricSyncOffset: lyricSyncOffset ?? this.lyricSyncOffset,
    );
  }
}

const Object _noChange = Object();

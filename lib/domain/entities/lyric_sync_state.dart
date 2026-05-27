import 'package:cross_platform_music_player/domain/entities/lyric_timeline.dart';

class LyricSyncState {
  const LyricSyncState({
    this.timeline = LyricTimeline.empty,
    this.activeIndex,
    this.playbackPosition = Duration.zero,
    this.effectivePosition = Duration.zero,
    this.userOffset = Duration.zero,
    this.sourceOffset = Duration.zero,
    this.effectiveOffset = Duration.zero,
  });

  final LyricTimeline timeline;
  final int? activeIndex;
  final Duration playbackPosition;
  final Duration effectivePosition;
  final Duration userOffset;
  final Duration sourceOffset;
  final Duration effectiveOffset;

  bool get hasLyrics => timeline.isNotEmpty;

  LyricTimelineEntry? get activeEntry {
    final index = activeIndex;
    if (index == null || index < 0 || index >= timeline.length) return null;
    return timeline[index];
  }

  LyricTimelineEntry? get nextEntry {
    final index = activeIndex;
    if (index == null) return timeline.isNotEmpty ? timeline[0] : null;
    final nextIndex = index + 1;
    if (nextIndex >= timeline.length) return null;
    return timeline[nextIndex];
  }

  LyricSyncState copyWith({
    LyricTimeline? timeline,
    Object? activeIndex = _noChange,
    Duration? playbackPosition,
    Duration? effectivePosition,
    Duration? userOffset,
    Duration? sourceOffset,
    Duration? effectiveOffset,
  }) {
    return LyricSyncState(
      timeline: timeline ?? this.timeline,
      activeIndex: identical(activeIndex, _noChange)
          ? this.activeIndex
          : activeIndex as int?,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      effectivePosition: effectivePosition ?? this.effectivePosition,
      userOffset: userOffset ?? this.userOffset,
      sourceOffset: sourceOffset ?? this.sourceOffset,
      effectiveOffset: effectiveOffset ?? this.effectiveOffset,
    );
  }
}

const Object _noChange = Object();

import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_sync_state.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_timeline.dart';

class LyricSyncEngine {
  const LyricSyncEngine({
    this.boundaryTolerance = Duration.zero,
    this.fallbackLineDuration = const Duration(seconds: 4),
  });

  final Duration boundaryTolerance;
  final Duration fallbackLineDuration;

  LyricTimeline buildTimeline(List<LyricLine> lines, {Duration? duration}) {
    return LyricTimeline.fromLines(
      lines,
      duration: duration,
      fallbackLineDuration: fallbackLineDuration,
    );
  }

  LyricSyncState resolve({
    required LyricTimeline timeline,
    required Duration playbackPosition,
    required Duration userOffset,
  }) {
    final sourceOffset = timeline.sourceOffset;
    final effectiveOffset = userOffset - sourceOffset;
    final effectivePosition = shiftPosition(playbackPosition, effectiveOffset);
    return LyricSyncState(
      timeline: timeline,
      activeIndex: findActiveIndex(timeline, effectivePosition),
      playbackPosition: playbackPosition,
      effectivePosition: effectivePosition,
      userOffset: userOffset,
      sourceOffset: sourceOffset,
      effectiveOffset: effectiveOffset,
    );
  }

  int? findActiveIndex(LyricTimeline timeline, Duration effectivePosition) {
    if (timeline.isEmpty) return null;
    final position = boundaryTolerance > Duration.zero
        ? effectivePosition - boundaryTolerance
        : effectivePosition;
    final lookupPosition = position.isNegative ? Duration.zero : position;
    if (lookupPosition < timeline[0].start) return null;

    var lo = 0;
    var hi = timeline.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (timeline[mid].start <= lookupPosition) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  Duration shiftPosition(Duration position, Duration offset) {
    final shifted = position + offset;
    return shifted.isNegative ? Duration.zero : shifted;
  }

  Duration seekPositionForIndex(
    LyricTimeline timeline,
    int index,
    Duration userOffset,
  ) {
    if (index < 0 || index >= timeline.length) return Duration.zero;
    final shifted =
        timeline[index].seekStart - userOffset + timeline.sourceOffset;
    return shifted.isNegative ? Duration.zero : shifted;
  }
}

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';

/// Lightweight playback performance counters for local diagnostics.
///
/// The metrics stay out of UI state so frequent player events do not trigger
/// extra rebuilds.
final class PlaybackMetricsSnapshot {
  const PlaybackMetricsSnapshot({
    required this.trackId,
    required this.quality,
    required this.sourceResolveTime,
    required this.loadReadyTime,
    required this.startupTime,
    required this.bufferingEvents,
    required this.startedAt,
  });

  final String trackId;
  final AudioQuality quality;
  final Duration sourceResolveTime;
  final Duration loadReadyTime;
  final Duration startupTime;
  final int bufferingEvents;
  final DateTime startedAt;

  PlaybackMetricsSnapshot copyWith({int? bufferingEvents}) {
    return PlaybackMetricsSnapshot(
      trackId: trackId,
      quality: quality,
      sourceResolveTime: sourceResolveTime,
      loadReadyTime: loadReadyTime,
      startupTime: startupTime,
      bufferingEvents: bufferingEvents ?? this.bufferingEvents,
      startedAt: startedAt,
    );
  }
}

final class PlaybackMetricsSummary {
  const PlaybackMetricsSummary({
    this.playAttempts = 0,
    this.totalStartupTime = Duration.zero,
    this.totalBufferingEvents = 0,
    this.lastSnapshot,
  });

  final int playAttempts;
  final Duration totalStartupTime;
  final int totalBufferingEvents;
  final PlaybackMetricsSnapshot? lastSnapshot;

  Duration get averageStartupTime {
    if (playAttempts == 0) return Duration.zero;
    return Duration(
      microseconds: totalStartupTime.inMicroseconds ~/ playAttempts,
    );
  }

  PlaybackMetricsSummary record(PlaybackMetricsSnapshot snapshot) {
    return PlaybackMetricsSummary(
      playAttempts: playAttempts + 1,
      totalStartupTime: totalStartupTime + snapshot.startupTime,
      totalBufferingEvents:
          totalBufferingEvents + snapshot.bufferingEvents,
      lastSnapshot: snapshot,
    );
  }

  PlaybackMetricsSummary replaceLast(PlaybackMetricsSnapshot snapshot) {
    final previous = lastSnapshot;
    if (previous == null) return record(snapshot);

    return PlaybackMetricsSummary(
      playAttempts: playAttempts,
      totalStartupTime: totalStartupTime,
      totalBufferingEvents:
          totalBufferingEvents -
          previous.bufferingEvents +
          snapshot.bufferingEvents,
      lastSnapshot: snapshot,
    );
  }
}

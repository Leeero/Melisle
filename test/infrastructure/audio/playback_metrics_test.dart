import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/infrastructure/audio/playback_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlaybackMetricsSummary records average startup and updates buffering', () {
    final first = _snapshot(
      trackId: 'track-1',
      startupTime: const Duration(milliseconds: 600),
      bufferingEvents: 0,
    );
    final second = _snapshot(
      trackId: 'track-2',
      startupTime: const Duration(milliseconds: 1000),
      bufferingEvents: 1,
    );

    var summary = const PlaybackMetricsSummary().record(first).record(second);

    expect(summary.playAttempts, 2);
    expect(summary.averageStartupTime, const Duration(milliseconds: 800));
    expect(summary.totalBufferingEvents, 1);

    summary = summary.replaceLast(second.copyWith(bufferingEvents: 3));

    expect(summary.playAttempts, 2);
    expect(summary.averageStartupTime, const Duration(milliseconds: 800));
    expect(summary.totalBufferingEvents, 3);
    expect(summary.lastSnapshot?.bufferingEvents, 3);
  });
}

PlaybackMetricsSnapshot _snapshot({
  required String trackId,
  required Duration startupTime,
  required int bufferingEvents,
}) {
  return PlaybackMetricsSnapshot(
    trackId: trackId,
    quality: AudioQuality.high,
    sourceResolveTime: const Duration(milliseconds: 40),
    loadReadyTime: const Duration(milliseconds: 120),
    startupTime: startupTime,
    bufferingEvents: bufferingEvents,
    startedAt: DateTime(2026, 6, 8, 10),
  );
}

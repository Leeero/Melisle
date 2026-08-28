import 'package:cross_platform_music_player/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LyricSyncEngine', () {
    const engine = LyricSyncEngine(
      boundaryTolerance: Duration(milliseconds: 220),
    );

    test('returns null before the first lyric line', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(start: Duration(seconds: 10), text: '第一句'),
      ]);

      final state = engine.resolve(
        timeline: timeline,
        playbackPosition: const Duration(seconds: 9),
        userOffset: Duration.zero,
      );

      expect(state.activeIndex, isNull);
    });

    test('keeps one stable lyric list for the same timeline', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(start: Duration(seconds: 10), text: '第一句'),
      ]);

      expect(
        identical(timeline.toLyricLines(), timeline.toLyricLines()),
        isTrue,
      );
    });

    test('activates a line at its start after boundary tolerance', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(start: Duration(seconds: 10), text: '现在我只想 要逃离'),
        LyricLine(start: Duration(seconds: 38), text: '所谓的规矩'),
      ]);

      final beforeBoundary = engine.resolve(
        timeline: timeline,
        playbackPosition: const Duration(milliseconds: 38000),
        userOffset: Duration.zero,
      );
      final afterTolerance = engine.resolve(
        timeline: timeline,
        playbackPosition: const Duration(milliseconds: 38220),
        userOffset: Duration.zero,
      );

      expect(beforeBoundary.activeIndex, 0);
      expect(afterTolerance.activeIndex, 1);
    });

    test('keeps previous line shortly before next line', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(start: Duration(seconds: 10), text: '现在我只想 要逃离'),
        LyricLine(start: Duration(seconds: 38), text: '所谓的规矩'),
      ]);

      final state = engine.resolve(
        timeline: timeline,
        playbackPosition: const Duration(milliseconds: 37790),
        userOffset: Duration.zero,
      );

      expect(state.activeIndex, 0);
      expect(state.activeEntry?.text, '现在我只想 要逃离');
    });

    test('positive offset advances the active line', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(start: Duration(seconds: 10), text: '第一句'),
        LyricLine(start: Duration(seconds: 20), text: '第二句'),
      ]);

      final state = engine.resolve(
        timeline: timeline,
        playbackPosition: const Duration(milliseconds: 19800),
        userOffset: const Duration(milliseconds: 420),
      );

      expect(state.activeIndex, 1);
    });

    test('negative offset delays the active line', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(start: Duration(seconds: 10), text: '第一句'),
        LyricLine(start: Duration(seconds: 20), text: '第二句'),
      ]);

      final state = engine.resolve(
        timeline: timeline,
        playbackPosition: const Duration(milliseconds: 20300),
        userOffset: const Duration(milliseconds: -200),
      );

      expect(state.activeIndex, 0);
    });

    test('normalizes empty, negative, unordered and duplicate lines', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(start: Duration(seconds: 20), text: '第二句'),
        LyricLine(start: Duration(seconds: -1), text: '  开头  '),
        LyricLine(start: Duration(seconds: 20), text: '副歌'),
        LyricLine(start: Duration(seconds: 15), text: '   '),
      ], duration: const Duration(seconds: 30));

      expect(timeline.length, 2);
      expect(timeline[0].start, Duration.zero);
      expect(timeline[0].text, '开头');
      expect(timeline[0].end, const Duration(seconds: 20));
      expect(timeline[1].text, '第二句\n副歌');
      expect(timeline[1].end, const Duration(seconds: 30));
    });

    test('seek position subtracts offset and clamps to zero', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(start: Duration(milliseconds: 150), text: '开头'),
        LyricLine(start: Duration(seconds: 8), text: '下一句'),
      ]);

      final clamped = engine.seekPositionForIndex(
        timeline,
        0,
        const Duration(milliseconds: 300),
      );
      final shifted = engine.seekPositionForIndex(
        timeline,
        1,
        const Duration(milliseconds: 500),
      );

      expect(clamped, Duration.zero);
      expect(shifted, const Duration(milliseconds: 7500));
    });

    test('keeps source offset separate and applies it in one place', () {
      final timeline = engine.buildTimeline(const [
        LyricLine(
          start: Duration(seconds: 20),
          text: '第二句',
          sourceOffset: Duration(milliseconds: 500),
        ),
      ]);

      final beforeSourceOffset = engine.resolve(
        timeline: timeline,
        playbackPosition: const Duration(milliseconds: 19700),
        userOffset: Duration.zero,
      );
      final afterSourceOffset = engine.resolve(
        timeline: timeline,
        playbackPosition: const Duration(milliseconds: 20720),
        userOffset: Duration.zero,
      );

      expect(timeline[0].start, const Duration(seconds: 20));
      expect(timeline.sourceOffset, const Duration(milliseconds: 500));
      expect(beforeSourceOffset.activeIndex, isNull);
      expect(afterSourceOffset.activeIndex, 0);
      expect(afterSourceOffset.sourceOffset, const Duration(milliseconds: 500));
      expect(
        afterSourceOffset.effectiveOffset,
        const Duration(milliseconds: -500),
      );
    });
  });
}

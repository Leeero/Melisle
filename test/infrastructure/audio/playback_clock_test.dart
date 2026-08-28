import 'package:cross_platform_music_player/infrastructure/audio/playback_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaybackClock', () {
    late DateTime now;
    late PlaybackClock clock;

    setUp(() {
      now = DateTime.utc(2026, 1, 1);
      clock = PlaybackClock(now: () => now);
      clock.reset(duration: const Duration(minutes: 3));
    });

    test('freezes while native playback is buffering', () {
      clock.start();
      now = now.add(const Duration(seconds: 2));

      clock.synchronize(Duration.zero, allowBackward: false);
      clock.pause();
      now = now.add(const Duration(seconds: 3));

      expect(clock.position, const Duration(seconds: 2));
    });

    test('rejects an implausible backward correction while running', () {
      clock.start();
      now = now.add(const Duration(seconds: 8));

      clock.synchronize(
        const Duration(seconds: 2),
        allowBackward: true,
        maxBackwardCorrection: const Duration(milliseconds: 500),
      );

      expect(clock.position, const Duration(seconds: 8));
    });

    test('accepts a small native phase correction while running', () {
      clock.start();
      now = now.add(const Duration(seconds: 8));

      clock.synchronize(
        const Duration(milliseconds: 7700),
        allowBackward: true,
        maxBackwardCorrection: const Duration(milliseconds: 500),
      );
      now = now.add(const Duration(seconds: 1));

      expect(clock.position, const Duration(milliseconds: 8700));
    });

    test('pause freezes and resume continues from the preserved position', () {
      clock.start();
      now = now.add(const Duration(seconds: 4));
      clock.pause();
      now = now.add(const Duration(seconds: 10));

      expect(clock.position, const Duration(seconds: 4));

      clock.start();
      now = now.add(const Duration(seconds: 2));
      expect(clock.position, const Duration(seconds: 6));
    });

    test('seek re-anchors a running clock without stopping it', () {
      clock.start();
      now = now.add(const Duration(seconds: 4));
      clock.seek(const Duration(seconds: 40));
      now = now.add(const Duration(seconds: 2));

      expect(clock.position, const Duration(seconds: 42));
      expect(clock.isRunning, isTrue);
    });

    test('completion snaps to known duration and stops the clock', () {
      clock.start();
      now = now.add(const Duration(seconds: 20));
      clock.complete(nativePosition: const Duration(seconds: 19));
      now = now.add(const Duration(seconds: 5));

      expect(clock.position, const Duration(minutes: 3));
      expect(clock.isRunning, isFalse);
    });
  });
}

import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/play_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayQueue shuffle navigation', () {
    final tracks = [
      _track('t0'),
      _track('t1'),
      _track('t2'),
      _track('t3'),
      _track('t4'),
    ];

    PlayQueue buildShuffleQueue() {
      return const PlayQueue.empty()
          .withShuffle(true, seed: 7)
          .replaceAll(tracks, startIndex: 0, seed: 7);
    }

    test('next() should follow a stable shuffle order', () {
      final queue = buildShuffleQueue();
      final order = queue.shuffleOrder;

      expect(order, hasLength(tracks.length));
      expect(order.first, 0);

      final firstNext = queue.nextIndex();
      expect(firstNext, order[1]);

      final afterNext = queue.moveTo(firstNext!);
      expect(afterNext.currentIndex, order[1]);
      expect(afterNext.shuffleOrder, orderedEquals(order));
      expect(afterNext.previousIndex(), order[0]);
      expect(afterNext.nextIndex(), order[2]);
    });

    test('manual selection in shuffle should not rewrite shuffle order', () {
      final queue = buildShuffleQueue();
      final order = queue.shuffleOrder;
      final target = order[3];

      final moved = queue.moveTo(target);

      expect(moved.currentIndex, target);
      expect(moved.shuffleOrder, orderedEquals(order));
      expect(moved.previousIndex(), order[2]);
      expect(moved.nextIndex(), order[4]);
    });

    test('loopOne in shuffle keeps manual next/previous on current track', () {
      final queue = buildShuffleQueue().withLoopMode(QueueLoopMode.one);
      final order = queue.shuffleOrder;
      final current = queue.moveTo(order.last);

      expect(current.nextIndex(), current.currentIndex);
      expect(current.previousIndex(), current.currentIndex);
      expect(current.autoAdvanceIndex(), current.currentIndex);
      expect(current.shuffleOrder, orderedEquals(order));
    });
  });
}

MusicTrack _track(String id) {
  return MusicTrack(
    id: id,
    title: id,
    artistName: 'artist',
    albumTitle: 'album',
    artworkUrl: '',
    duration: Duration.zero,
  );
}

import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late HistoryCubit cubit;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    cubit = HistoryCubit(database);
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  test('load keeps the latest unique tracks and exposes pagination', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var index = 0; index < 31; index++) {
      await database.insertPlayHistory(
        PlayHistoryCompanion.insert(
          trackId: 'track-$index',
          title: '曲目 $index',
          playedAtMs: now - index,
        ),
      );
    }

    await cubit.load();

    expect(cubit.state.status, HistoryStatus.success);
    expect(cubit.state.tracks, hasLength(30));
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();

    expect(cubit.state.tracks, hasLength(31));
    expect(cubit.state.hasMore, isFalse);
  });

  test('load deduplicates repeated track history without creating a second source',
      () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var index = 0; index < 3; index++) {
      await database.insertPlayHistory(
        PlayHistoryCompanion.insert(
          trackId: 'same-track',
          title: '重复播放',
          playedAtMs: now - index,
        ),
      );
    }

    await cubit.load();

    expect(cubit.state.status, HistoryStatus.success);
    expect(cubit.state.tracks.map((track) => track.id), ['same-track']);
    expect(cubit.state.hasMore, isFalse);
  });

  test('fetchAllTracks returns the complete unique history for playback', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var index = 0; index < 31; index++) {
      await database.insertPlayHistory(
        PlayHistoryCompanion.insert(
          trackId: index == 30 ? 'track-0' : 'track-$index',
          title: '曲目 $index',
          playedAtMs: now - index,
        ),
      );
    }

    final tracks = await cubit.fetchAllTracks();

    expect(tracks, hasLength(30));
    expect(tracks.first.id, 'track-0');
  });
}

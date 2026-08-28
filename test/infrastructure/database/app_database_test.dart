import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trimPlayHistory keeps only latest entries', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    for (var i = 0; i < 5; i++) {
      await database.insertPlayHistory(
        PlayHistoryCompanion.insert(
          trackId: 'track-$i',
          title: 'Track $i',
          playedAtMs: i,
          durationPlayedMs: const Value(1000),
        ),
      );
    }

    await database.trimPlayHistory(keepLatest: 3);

    final rows = await database.recentPlays(limit: 10);
    expect(rows.map((row) => row.trackId), ['track-4', 'track-3', 'track-2']);
  });

  test('trimPlayHistory clears entries when keepLatest is zero', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.insertPlayHistory(
      PlayHistoryCompanion.insert(
        trackId: 'track-1',
        title: 'Track 1',
        playedAtMs: 1,
      ),
    );

    await database.trimPlayHistory(keepLatest: 0);

    expect(await database.recentPlays(limit: 10), isEmpty);
  });

  test('clearSessionHistory removes play and search history', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.insertPlayHistory(
      PlayHistoryCompanion.insert(
        trackId: 'track-1',
        title: 'Track 1',
        playedAtMs: 1,
      ),
    );
    await database.touchSearchHistory('previous account query');

    await database.clearSessionHistory();

    expect(await database.recentPlays(limit: 10), isEmpty);
    expect(await database.recentSearches(limit: 10), isEmpty);
  });
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [PlayHistory, SearchHistory, AppSettings, Downloads])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // ---- Play history -------------------------------------------------------

  Future<int> insertPlayHistory(PlayHistoryCompanion entry) {
    return into(playHistory).insert(entry);
  }

  Future<int> trimPlayHistory({int keepLatest = 3000}) {
    if (keepLatest <= 0) return delete(playHistory).go();
    return customUpdate(
      '''
      DELETE FROM play_history
      WHERE id NOT IN (
        SELECT id FROM play_history
        ORDER BY played_at_ms DESC, id DESC
        LIMIT ?
      )
      ''',
      variables: [Variable<int>(keepLatest)],
      updates: {playHistory},
    );
  }

  Stream<List<PlayHistoryData>> watchRecentPlays({int limit = 40}) {
    return (select(playHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAtMs)])
          ..limit(limit))
        .watch();
  }

  Future<List<PlayHistoryData>> recentPlays({int limit = 40}) {
    return (select(playHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAtMs)])
          ..limit(limit))
        .get();
  }

  /// Top tracks ordered by local play-count, aggregated from [PlayHistory].
  Future<List<MostPlayedRow>> mostPlayed({int limit = 40}) async {
    final countExpr = playHistory.id.count();
    final lastExpr = playHistory.playedAtMs.max();
    final durationExpr = playHistory.durationPlayedMs.max();
    final query = selectOnly(playHistory)
      ..addColumns([
        playHistory.trackId,
        playHistory.title,
        playHistory.artistName,
        playHistory.albumTitle,
        playHistory.albumId,
        playHistory.artistId,
        playHistory.artworkUrl,
        countExpr,
        lastExpr,
        durationExpr,
      ])
      ..groupBy([playHistory.trackId])
      ..orderBy([OrderingTerm.desc(countExpr), OrderingTerm.desc(lastExpr)])
      ..limit(limit);

    final rows = await query.get();
    return [
      for (final r in rows)
        MostPlayedRow(
          trackId: r.read(playHistory.trackId)!,
          title: r.read(playHistory.title)!,
          artistName: r.read(playHistory.artistName),
          albumTitle: r.read(playHistory.albumTitle),
          albumId: r.read(playHistory.albumId),
          artistId: r.read(playHistory.artistId),
          artworkUrl: r.read(playHistory.artworkUrl),
          playCount: r.read(countExpr) ?? 0,
          lastPlayedAtMs: r.read(lastExpr) ?? 0,
          durationMs: r.read(durationExpr) ?? 0,
        ),
    ];
  }

  // ---- Search history -----------------------------------------------------

  Future<void> touchSearchHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final existing =
        await (select(searchHistory)
              ..where((t) => t.query.equals(q))
              ..limit(1))
            .getSingleOrNull();
    if (existing == null) {
      await into(
        searchHistory,
      ).insert(SearchHistoryCompanion.insert(query: q, lastUsedAtMs: nowMs));
    } else {
      await (update(
        searchHistory,
      )..where((t) => t.id.equals(existing.id))).write(
        SearchHistoryCompanion(
          lastUsedAtMs: Value(nowMs),
          useCount: Value(existing.useCount + 1),
        ),
      );
    }
  }

  Future<List<SearchHistoryData>> recentSearches({int limit = 10}) {
    return (select(searchHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAtMs)])
          ..limit(limit))
        .get();
  }

  Future<void> clearSearchHistory() => delete(searchHistory).go();

  // ---- App settings (key/value) -------------------------------------------

  Future<String?> readSetting(String key) async {
    final row =
        await (select(appSettings)
              ..where((t) => t.key.equals(key))
              ..limit(1))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  Future<Map<String, String>> readAllSettings() async {
    final rows = await select(appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  // ---- Downloads ----------------------------------------------------------

  Future<void> upsertDownload(DownloadsCompanion entry) {
    return into(downloads).insertOnConflictUpdate(entry);
  }

  Future<Download?> findDownload(String trackId) {
    return (select(downloads)
          ..where((t) => t.trackId.equals(trackId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Download>> allDownloads() {
    return (select(
      downloads,
    )..orderBy([(t) => OrderingTerm.desc(t.downloadedAtMs)])).get();
  }

  Future<int> deleteDownload(String trackId) {
    return (delete(downloads)..where((t) => t.trackId.equals(trackId))).go();
  }
}

/// Aggregated row returned by [AppDatabase.mostPlayed].
class MostPlayedRow {
  const MostPlayedRow({
    required this.trackId,
    required this.title,
    required this.playCount,
    required this.lastPlayedAtMs,
    required this.durationMs,
    this.artistName,
    this.albumTitle,
    this.albumId,
    this.artistId,
    this.artworkUrl,
  });

  final String trackId;
  final String title;
  final String? artistName;
  final String? albumTitle;
  final String? albumId;
  final String? artistId;
  final String? artworkUrl;
  final int playCount;
  final int lastPlayedAtMs;
  final int durationMs;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'music_player.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

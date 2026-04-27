import 'package:drift/drift.dart';

/// Local cache of playback events. Drives the "recently played" and "most
/// played" sections on the home page when the remote backend does not provide
/// them, and is also used for observability in the UI.
class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  TextColumn get title => text()();
  TextColumn get artistName => text().nullable()();
  TextColumn get albumTitle => text().nullable()();
  TextColumn get albumId => text().nullable()();
  TextColumn get artistId => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get playedAtMs => integer()();
  IntColumn get durationPlayedMs => integer().withDefault(const Constant(0))();
}

/// Tracks the user's recent free-text searches for auto-completion / history.
class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()();
  IntColumn get lastUsedAtMs => integer()();
  IntColumn get useCount => integer().withDefault(const Constant(1))();
}

/// Simple key/value table for app settings (theme, default audio quality,
/// fade / gap preferences, etc.). Values are stored as strings — callers are
/// responsible for encoding and decoding them.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Tracks offline downloaded media.
class Downloads extends Table {
  TextColumn get trackId => text()();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get container => text().nullable()();
  IntColumn get bitrate => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get artistName => text().nullable()();
  TextColumn get albumTitle => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get downloadedAtMs => integer()();
  IntColumn get status =>
      integer().withDefault(const Constant(0))(); // 0=done, 1=pending, 2=failed

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

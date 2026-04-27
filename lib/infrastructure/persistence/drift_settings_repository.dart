import 'package:flutter/material.dart';

import '../../domain/entities/audio_quality.dart';
import '../../domain/repositories/settings_repository.dart';
import '../database/app_database.dart';

/// Drift-backed implementation of [SettingsRepository].
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  static const _kThemeMode = 'theme_mode';
  static const _kDefaultQuality = 'default_quality';
  static const _kGapBetweenTracks = 'gap_between_tracks_ms';
  static const _kCustomArtworkSourceEnabled = 'custom_artwork_source_enabled';
  static const _kCustomArtworkSourceUrl = 'custom_artwork_source_url';
  static const _kCustomLyricsSourceEnabled = 'custom_lyrics_source_enabled';
  static const _kCustomLyricsSourceUrl = 'custom_lyrics_source_url';

  @override
  Future<AppSettingsSnapshot> load() async {
    final map = await _db.readAllSettings();
    return AppSettingsSnapshot(
      themeMode: _parseThemeMode(map[_kThemeMode]),
      defaultQuality: AudioQuality.fromStorageKey(map[_kDefaultQuality]),
      gapBetweenTracks: Duration(
        milliseconds: int.tryParse(map[_kGapBetweenTracks] ?? '') ?? 0,
      ),
      customArtworkSourceEnabled: _parseBool(
        map[_kCustomArtworkSourceEnabled],
        defaultValue: false,
      ),
      customArtworkSourceUrl: map[_kCustomArtworkSourceUrl] ?? '',
      customLyricsSourceEnabled: _parseBool(
        map[_kCustomLyricsSourceEnabled],
        defaultValue: false,
      ),
      customLyricsSourceUrl: map[_kCustomLyricsSourceUrl] ?? '',
    );
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) =>
      _db.writeSetting(_kThemeMode, _themeModeToString(mode));

  @override
  Future<void> saveDefaultQuality(AudioQuality quality) =>
      _db.writeSetting(_kDefaultQuality, quality.storageKey);

  @override
  Future<void> saveGapBetweenTracks(Duration gap) => _db.writeSetting(
    _kGapBetweenTracks,
    gap.inMilliseconds.toString(),
  );

  @override
  Future<void> saveCustomArtworkSourceEnabled(bool enabled) =>
      _db.writeSetting(_kCustomArtworkSourceEnabled, enabled ? '1' : '0');

  @override
  Future<void> saveCustomArtworkSourceUrl(String url) =>
      _db.writeSetting(_kCustomArtworkSourceUrl, url.trim());

  @override
  Future<void> saveCustomLyricsSourceEnabled(bool enabled) =>
      _db.writeSetting(_kCustomLyricsSourceEnabled, enabled ? '1' : '0');

  @override
  Future<void> saveCustomLyricsSourceUrl(String url) =>
      _db.writeSetting(_kCustomLyricsSourceUrl, url.trim());

  static ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static bool _parseBool(String? raw, {required bool defaultValue}) {
    if (raw == null) return defaultValue;
    if (raw == '1' || raw.toLowerCase() == 'true') return true;
    if (raw == '0' || raw.toLowerCase() == 'false') return false;
    return defaultValue;
  }
}

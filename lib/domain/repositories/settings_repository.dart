import 'package:flutter/material.dart';

import '../entities/audio_quality.dart';

/// Simple application-level preferences persisted locally.
///
/// UI surfaces (`ThemeCubit`, quality picker, custom media source toggle, …)
/// read/write through this abstraction so the storage backend (drift today,
/// possibly something else tomorrow) stays swappable.
abstract class SettingsRepository {
  Future<AppSettingsSnapshot> load();

  Future<void> saveThemeMode(ThemeMode mode);

  Future<void> saveDefaultQuality(AudioQuality quality);

  Future<void> saveGapBetweenTracks(Duration gap);

  Future<void> saveLyricSyncOffset(Duration offset);

  Future<void> saveCustomArtworkSourceEnabled(bool enabled);

  Future<void> saveCustomArtworkSourceUrl(String url);

  Future<void> saveCustomLyricsSourceEnabled(bool enabled);

  Future<void> saveCustomLyricsSourceUrl(String url);
}

/// Immutable snapshot of the persisted settings.
class AppSettingsSnapshot {
  const AppSettingsSnapshot({
    this.themeMode = ThemeMode.system,
    this.defaultQuality = AudioQuality.auto,
    this.gapBetweenTracks = Duration.zero,
    this.lyricSyncOffset = Duration.zero,
    this.customArtworkSourceEnabled = false,
    this.customArtworkSourceUrl = '',
    this.customLyricsSourceEnabled = false,
    this.customLyricsSourceUrl = '',
  });

  final ThemeMode themeMode;
  final AudioQuality defaultQuality;
  final Duration gapBetweenTracks;
  final Duration lyricSyncOffset;
  final bool customArtworkSourceEnabled;
  final String customArtworkSourceUrl;
  final bool customLyricsSourceEnabled;
  final String customLyricsSourceUrl;

  AppSettingsSnapshot copyWith({
    ThemeMode? themeMode,
    AudioQuality? defaultQuality,
    Duration? gapBetweenTracks,
    Duration? lyricSyncOffset,
    bool? customArtworkSourceEnabled,
    String? customArtworkSourceUrl,
    bool? customLyricsSourceEnabled,
    String? customLyricsSourceUrl,
  }) {
    return AppSettingsSnapshot(
      themeMode: themeMode ?? this.themeMode,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      gapBetweenTracks: gapBetweenTracks ?? this.gapBetweenTracks,
      lyricSyncOffset: lyricSyncOffset ?? this.lyricSyncOffset,
      customArtworkSourceEnabled:
          customArtworkSourceEnabled ?? this.customArtworkSourceEnabled,
      customArtworkSourceUrl:
          customArtworkSourceUrl ?? this.customArtworkSourceUrl,
      customLyricsSourceEnabled:
          customLyricsSourceEnabled ?? this.customLyricsSourceEnabled,
      customLyricsSourceUrl:
          customLyricsSourceUrl ?? this.customLyricsSourceUrl,
    );
  }
}

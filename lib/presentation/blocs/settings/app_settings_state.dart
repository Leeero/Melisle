import 'package:flutter/material.dart';

import '../../../domain/entities/audio_quality.dart';
import '../../../domain/repositories/settings_repository.dart';

enum SourceTestStatus { idle, testing, success, failure }

class SourceTestState {
  const SourceTestState({
    this.status = SourceTestStatus.idle,
    this.message,
    this.resolvedUrl,
  });

  final SourceTestStatus status;
  final String? message;
  final String? resolvedUrl;
}

class AppSettingsState {
  const AppSettingsState({
    required this.themeMode,
    required this.defaultQuality,
    required this.gapBetweenTracks,
    required this.lyricSyncOffset,
    required this.customArtworkSourceEnabled,
    required this.customArtworkSourceUrl,
    required this.customLyricsSourceEnabled,
    required this.customLyricsSourceUrl,
    this.isLoading = false,
    this.artworkSourceTest = const SourceTestState(),
    this.lyricsSourceTest = const SourceTestState(),
  });

  const AppSettingsState.initial()
    : themeMode = ThemeMode.system,
      defaultQuality = AudioQuality.auto,
      gapBetweenTracks = Duration.zero,
      lyricSyncOffset = Duration.zero,
      customArtworkSourceEnabled = false,
      customArtworkSourceUrl = '',
      customLyricsSourceEnabled = false,
      customLyricsSourceUrl = '',
      isLoading = true,
      artworkSourceTest = const SourceTestState(),
      lyricsSourceTest = const SourceTestState();

  final ThemeMode themeMode;
  final AudioQuality defaultQuality;
  final Duration gapBetweenTracks;
  final Duration lyricSyncOffset;
  final bool customArtworkSourceEnabled;
  final String customArtworkSourceUrl;
  final bool customLyricsSourceEnabled;
  final String customLyricsSourceUrl;
  final bool isLoading;
  final SourceTestState artworkSourceTest;
  final SourceTestState lyricsSourceTest;

  AppSettingsSnapshot toSnapshot() {
    return AppSettingsSnapshot(
      themeMode: themeMode,
      defaultQuality: defaultQuality,
      gapBetweenTracks: gapBetweenTracks,
      lyricSyncOffset: lyricSyncOffset,
      customArtworkSourceEnabled: customArtworkSourceEnabled,
      customArtworkSourceUrl: customArtworkSourceUrl,
      customLyricsSourceEnabled: customLyricsSourceEnabled,
      customLyricsSourceUrl: customLyricsSourceUrl,
    );
  }

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    AudioQuality? defaultQuality,
    Duration? gapBetweenTracks,
    Duration? lyricSyncOffset,
    bool? customArtworkSourceEnabled,
    String? customArtworkSourceUrl,
    bool? customLyricsSourceEnabled,
    String? customLyricsSourceUrl,
    bool? isLoading,
    SourceTestState? artworkSourceTest,
    SourceTestState? lyricsSourceTest,
  }) {
    return AppSettingsState(
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
      isLoading: isLoading ?? this.isLoading,
      artworkSourceTest: artworkSourceTest ?? this.artworkSourceTest,
      lyricsSourceTest: lyricsSourceTest ?? this.lyricsSourceTest,
    );
  }
}
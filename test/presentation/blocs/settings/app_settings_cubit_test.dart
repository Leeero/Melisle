import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persists custom media source settings and reports explicit save feedback',
      () async {
    final repository = _FakeSettingsRepository();
    final cubit = AppSettingsCubit(repository, CustomMediaSourceResolver());
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.setCustomArtworkSourceEnabled(true);
    await cubit.setCustomArtworkSourceUrl(
      'https://cover.example.test/{artist}/{album}',
    );
    await cubit.setCustomLyricsSourceEnabled(true);
    await cubit.setCustomLyricsSourceUrl(
      'https://lyrics.example.test?title={title}',
    );
    await cubit.saveCustomMediaSources();

    expect(repository.snapshot.customArtworkSourceEnabled, isTrue);
    expect(
      repository.snapshot.customArtworkSourceUrl,
      'https://cover.example.test/{artist}/{album}',
    );
    expect(repository.snapshot.customLyricsSourceEnabled, isTrue);
    expect(
      repository.snapshot.customLyricsSourceUrl,
      'https://lyrics.example.test?title={title}',
    );
    expect(cubit.state.feedback?.kind, SettingsFeedbackKind.success);
  });

  test('rejects invalid custom source URL before starting a connection test',
      () async {
    final cubit = AppSettingsCubit(
      _FakeSettingsRepository(),
      CustomMediaSourceResolver(),
    );
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.setCustomLyricsSourceUrl('not-a-url');
    await cubit.testCustomLyricsSource();

    expect(cubit.state.lyricsSourceTest.status, SourceTestStatus.failure);
    expect(cubit.state.lyricsSourceTest.message, '请输入合法的 http/https URL。');
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettingsSnapshot snapshot = const AppSettingsSnapshot();

  @override
  Future<AppSettingsSnapshot> load() async => snapshot;

  @override
  Future<void> saveCustomArtworkSourceEnabled(bool enabled) async {
    snapshot = snapshot.copyWith(customArtworkSourceEnabled: enabled);
  }

  @override
  Future<void> saveCustomArtworkSourceUrl(String url) async {
    snapshot = snapshot.copyWith(customArtworkSourceUrl: url);
  }

  @override
  Future<void> saveCustomLyricsSourceEnabled(bool enabled) async {
    snapshot = snapshot.copyWith(customLyricsSourceEnabled: enabled);
  }

  @override
  Future<void> saveCustomLyricsSourceUrl(String url) async {
    snapshot = snapshot.copyWith(customLyricsSourceUrl: url);
  }

  @override
  Future<void> saveDefaultQuality(AudioQuality quality) async {
    snapshot = snapshot.copyWith(defaultQuality: quality);
  }

  @override
  Future<void> saveGapBetweenTracks(Duration gap) async {
    snapshot = snapshot.copyWith(gapBetweenTracks: gap);
  }

  @override
  Future<void> saveLyricSyncOffset(Duration offset) async {
    snapshot = snapshot.copyWith(lyricSyncOffset: offset);
  }

  @override
  Future<void> saveMenuBarLyricsEnabled(bool enabled) async {
    snapshot = snapshot.copyWith(menuBarLyricsEnabled: enabled);
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    snapshot = snapshot.copyWith(themeMode: mode);
  }
}

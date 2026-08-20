import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/application/usecases/login_with_emby.dart';
import 'package:cross_platform_music_player/application/usecases/logout.dart';
import 'package:cross_platform_music_player/application/usecases/restore_session.dart';
import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_state.dart';
import 'package:cross_platform_music_player/presentation/pages/settings/settings_page.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsPage screenshots', () {
    for (final size in _viewports) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets(
            '${size.width.toInt()}x${size.height.toInt()} $mode scale-$scale',
            (tester) async {
              await _setViewport(tester, size, textScale: scale);
              await _pumpSettings(tester, themeMode: mode);
              expect(tester.takeException(), isNull);
              final brightness = mode == ThemeMode.light ? 'light' : 'dark';
              await _capture(
                tester,
                'settings-${size.width.toInt()}x${size.height.toInt()}-$brightness-scale-$scale',
              );
            },
          );
        }
      }
    }
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final settingsCubit = AppSettingsCubit(
    _MockSettingsRepository(),
    CustomMediaSourceResolver(),
  );
  final authCubit = AuthCubit(
    loginWithEmby: _MockLoginWithEmby(),
    restoreSession: _MockRestoreSession(),
    logout: _MockLogout(),
    fetchPlaylists: _MockFetchPlaylists(),
  );
  addTearDown(() {
    settingsCubit.close();
    authCubit.close();
  });
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const RepaintBoundary(
          key: ValueKey('settings-capture'),
          child: SettingsPage(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _setViewport(
  WidgetTester tester,
  ui.Size size, {
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_SETTINGS_SCREENSHOTS'] != 'true') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('settings-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Unable to encode settings screenshot');
    final directory = Directory('design-reference/screenshots/actual');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });
}

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

// Mock SettingsRepository
class _MockSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettingsSnapshot> load() async => const AppSettingsSnapshot(
        themeMode: ThemeMode.system,
        defaultQuality: AudioQuality.auto,
        gapBetweenTracks: Duration.zero,
        lyricSyncOffset: Duration.zero,
        menuBarLyricsEnabled: true,
        customArtworkSourceEnabled: false,
        customArtworkSourceUrl: '',
        customLyricsSourceEnabled: false,
        customLyricsSourceUrl: '',
      );

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}

  @override
  Future<void> saveDefaultQuality(AudioQuality quality) async {}

  @override
  Future<void> saveGapBetweenTracks(Duration gap) async {}

  @override
  Future<void> saveLyricSyncOffset(Duration offset) async {}

  @override
  Future<void> saveMenuBarLyricsEnabled(bool enabled) async {}

  @override
  Future<void> saveCustomArtworkSourceEnabled(bool enabled) async {}

  @override
  Future<void> saveCustomArtworkSourceUrl(String url) async {}

  @override
  Future<void> saveCustomLyricsSourceEnabled(bool enabled) async {}

  @override
  Future<void> saveCustomLyricsSourceUrl(String url) async {}
}

// Mock use cases
class _MockLoginWithEmby implements LoginWithEmby {
  @override
  Future<AuthSession> call({
    required String serverUrl,
    required String username,
    required String password,
  }) async => const AuthSession(
        serverUrl: 'https://example.com',
        userId: '1',
        userName: 'Test',
        accessToken: 'token',
        backendType: MusicBackendType.emby,
      );
}

class _MockRestoreSession implements RestoreSession {
  @override
  Future<AuthSession?> call() async => null;
}

class _MockLogout implements Logout {
  @override
  Future<void> call() async {}
}

class _MockFetchPlaylists implements FetchPlaylists {
  @override
  Future<void> call() async {}
}

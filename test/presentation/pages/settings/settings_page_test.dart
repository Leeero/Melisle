import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/application/usecases/login_with_emby.dart';
import 'package:cross_platform_music_player/application/usecases/logout.dart';
import 'package:cross_platform_music_player/application/usecases/restore_session.dart';
import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/settings/settings_page.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsPage responsive layout', () {
    testWidgets('uses the selected single-column layout on mobile', (
      tester,
    ) async {
      await _setViewport(tester, const ui.Size(390, 844));
      await _pumpSettings(tester, themeMode: ThemeMode.dark);

      expect(
        find.byKey(const ValueKey('settings-compact-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('settings-desktop-layout')),
        findsNothing,
      );
      expect(find.text('当前服务器'), findsOneWidget);
      expect(find.text('常用偏好'), findsOneWidget);
      expect(find.text('媒体与设备'), findsOneWidget);
      expect(find.text('存储'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
    });

    testWidgets('uses the single-column layout on desktop', (tester) async {
      await _setViewport(tester, const ui.Size(1440, 900));
      await _pumpSettings(tester, themeMode: ThemeMode.dark);

      expect(
        find.byKey(const ValueKey('settings-desktop-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('settings-compact-layout')),
        findsNothing,
      );
      expect(find.text('媒体与设备'), findsOneWidget);
      expect(find.text('当前服务器'), findsOneWidget);
      expect(find.text('存储'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
      expect(
        tester.widget(find.byKey(const ValueKey('settings-desktop-layout'))),
        isA<Column>(),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses anchored preference menus on desktop', (tester) async {
      await _setViewport(tester, const ui.Size(1440, 900));
      await _pumpSettings(tester, themeMode: ThemeMode.light);

      await tester.tap(find.text('在线音质'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('quality-preference-menu')),
        findsOneWidget,
      );
      expect(find.text('默认音质'), findsNothing);
      expect(find.text('省流 (128 kbps)'), findsOneWidget);
      expect(find.text('无损'), findsOneWidget);
      expect(find.text('直接播放源文件，不转码。'), findsOneWidget);
      expect(find.byIcon(Icons.high_quality_rounded), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.checked == true &&
              widget.properties.inMutuallyExclusiveGroup == true,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('无损'));
      await tester.pumpAndSettle();

      expect(find.text('无损'), findsOneWidget);
      expect(_qualityTriggerBorderColor(tester), Colors.transparent);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'settings-desktop-quality-menu-closed-pointer');
    });

    testWidgets('quality menu supports keyboard open and focus return', (
      tester,
    ) async {
      await _setViewport(tester, const ui.Size(1440, 900));
      await _pumpSettings(tester, themeMode: ThemeMode.dark);

      final triggerFinder = find.descendant(
        of: find.byKey(const ValueKey('quality-preference-menu')),
        matching: find.byType(InkWell),
      );
      final trigger = tester.widget<InkWell>(triggerFinder);
      trigger.focusNode!.unfocus();
      await tester.pump();
      trigger.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(_qualityTriggerBorderColor(tester), isNot(Colors.transparent));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('直接播放源文件，不转码。'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(trigger.focusNode!.hasFocus, isTrue);
      expect(_qualityTriggerBorderColor(tester), isNot(Colors.transparent));
    });

    testWidgets('quality menu stays readable in light mode at 1.3x text', (
      tester,
    ) async {
      await _setViewport(tester, const ui.Size(1440, 900), textScale: 1.3);
      await _pumpSettings(tester, themeMode: ThemeMode.light);

      await tester.tap(find.text('在线音质'));
      await tester.pumpAndSettle();

      expect(find.text('原始音质'), findsWidgets);
      expect(find.text('直接播放源文件，不转码。'), findsOneWidget);
      expect(find.text('省流 (128 kbps)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps preference pickers and confirmations interactive', (
      tester,
    ) async {
      await _setViewport(tester, const ui.Size(390, 844));
      await _pumpSettings(tester, themeMode: ThemeMode.dark);

      await tester.tap(find.text('在线音质'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('默认音质'), findsOneWidget);

      await tester.tapAt(const Offset(8, 8));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.scrollUntilVisible(
        find.text('清理缓存'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('清理缓存'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('将清除临时数据并释放本地存储空间，已下载的离线曲目不会受到影响。'), findsOneWidget);
    });
  });

  group('SettingsPage screenshots', () {
    testWidgets('desktop quality preference menu open', (tester) async {
      await _setViewport(tester, const ui.Size(1440, 900));
      await _pumpSettings(tester, themeMode: ThemeMode.dark);
      await tester.tap(find.text('在线音质'));
      await tester.pumpAndSettle();

      expect(find.text('无损'), findsOneWidget);
      await _capture(tester, 'settings-desktop-quality-menu-dark');
    });

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
  await settingsCubit.load();
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
      child: RepaintBoundary(
        key: const ValueKey('settings-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: const SettingsPage(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
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

Color _qualityTriggerBorderColor(WidgetTester tester) {
  final surface = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey('quality-preference-trigger-surface')),
  );
  final decoration = surface.decoration! as BoxDecoration;
  final border = decoration.border! as Border;
  return border.top.color;
}

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
  ui.Size(1440, 1024),
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
  Future<AuthSession?> call() async => const AuthSession(
    serverUrl: 'https://example.com',
    userId: '1',
    userName: 'Test',
    accessToken: 'token',
    backendType: MusicBackendType.emby,
  );
}

class _MockLogout implements Logout {
  @override
  Future<void> call() async {}
}

class _MockFetchPlaylists implements FetchPlaylists {
  @override
  Future<List<MusicPlaylist>> call({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => [];
}

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/application/usecases/login_with_emby.dart';
import 'package:cross_platform_music_player/application/usecases/logout.dart';
import 'package:cross_platform_music_player/application/usecases/restore_session.dart';
import 'package:cross_platform_music_player/bootstrap/app.dart';
import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/audio/audio_player_handler.dart';
import 'package:cross_platform_music_player/infrastructure/cache/audio_cache_manager.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/favorites/favorites_page.dart';
import 'package:cross_platform_music_player/presentation/pages/history/history_page.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/local_keyboard_shortcuts.dart';
import 'package:cross_platform_music_player/presentation/widgets/mini_player_bar.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_playlist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/queue_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('global shortcuts do not intercept text field input', (
    tester,
  ) async {
    final playerCubit = _MiniPlayerCubit(const PlayerViewState());
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: TextField()),
        ),
      ],
    );
    addTearDown(playerCubit.close);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => LocalKeyboardShortcuts(
          playerCubit: playerCubit,
          router: router,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'lisi@2024');
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('lisi@2024'), findsOneWidget);
  });

  testWidgets('login keeps the V3 card stable across loading and failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final loginCompleter = Completer<AuthSession>();
    final repository = _FakeMusicRepository(loginCompleter: loginCompleter);
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final authCubit = AuthCubit(
      loginWithEmby: LoginWithEmby(repository),
      restoreSession: RestoreSession(repository),
      logout: Logout(repository),
      fetchPlaylists: FetchPlaylists(repository),
    );
    final playerCubit = PlayerCubit(
      repository: repository,
      controller: AudioPlayerHandler(mediaSourceResolver: mediaSourceResolver),
    );
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
    );
    await settingsCubit.load();
    final favoritesCubit = FavoritesCubit(repository);
    final downloadsCubit = DownloadsCubit(
      repository: repository,
      database: database,
      cacheManager: AudioCacheManager(),
    );
    await tester.pumpWidget(
      MusicPlayerApp(
        repository: repository,
        settingsRepository: settingsRepository,
        mediaSourceResolver: mediaSourceResolver,
        database: database,
        authCubit: authCubit,
        playerCubit: playerCubit,
        settingsCubit: settingsCubit,
        favoritesCubit: favoritesCubit,
        downloadsCubit: downloadsCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Melisle 乐岛'), findsOneWidget);
    expect(find.text('连接您的个人音乐服务器'), findsOneWidget);
    expect(find.text('音乐源'), findsNothing);
    expect(
      find.text('自动识别 Emby、Navidrome 或 Subsonic/OpenSubsonic'),
      findsOneWidget,
    );
    expect(find.text('连接服务器'), findsOneWidget);
    expect(find.text('等待登录'), findsNothing);
    expect(find.byKey(const ValueKey('v3-login-card')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-login-card'))).width,
      480,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('v3-login-card'))).dx,
      720,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-login-logo'))),
      const Size(64, 64),
    );

    await tester.tap(find.text('连接服务器'));
    await tester.pump();
    expect(find.text('请输入服务器地址'), findsOneWidget);
    expect(find.text('请输入用户名'), findsOneWidget);
    expect(find.text('请输入密码或 API Token'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'https://music.example.com');
    await tester.enterText(fields.at(1), 'test-user');
    await tester.enterText(fields.at(2), 'test-password');
    await tester.tap(find.text('连接服务器'));
    await tester.pump();

    expect(find.text('正在连接…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('v3-login-submit')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const ValueKey('v3-login-card')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-login-logo'))),
      const Size(64, 64),
    );

    loginCompleter.completeError(Exception('network unavailable'));
    await tester.pumpAndSettle();

    expect(find.textContaining('network unavailable'), findsOneWidget);
    expect(find.text('重新连接'), findsOneWidget);
    expect(find.text('连接您的个人音乐服务器'), findsOneWidget);
    expect(
      find.text('自动识别 Emby、Navidrome 或 Subsonic/OpenSubsonic'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-login-logo'))),
      const Size(64, 64),
    );
    await _captureLogin(tester, 'login-desktop-light-1440x900');
    await settingsCubit.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    await _captureLogin(tester, 'login-desktop-dark-1440x900');

    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('v3-login-card'))).width,
      374,
    );
    expect(find.textContaining('network unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _captureLogin(tester, 'login-mobile-dark-390x844-scale-1.3');
    await settingsCubit.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    await _captureLogin(tester, 'login-mobile-light-390x844-scale-1.3');
  });

  testWidgets('play all icon button exposes tooltip and touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayAllButton(
              variant: PlayAllButtonVariant.iconOnly,
              onPressed: () {},
              onShufflePressed: () {},
            ),
          ),
        ),
      ),
    );

    final button = find.byTooltip('播放全部');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));

    final shuffleButton = find.byTooltip('随机播放');
    expect(shuffleButton, findsOneWidget);
    expect(tester.getSize(shuffleButton).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(shuffleButton).height, greaterThanOrEqualTo(44));
  });

  testWidgets('mobile shell renders design bottom tab bar and navigates', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);

    final repository = _FakeMusicRepository(session: _authenticatedSession);
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final authCubit = AuthCubit(
      loginWithEmby: LoginWithEmby(repository),
      restoreSession: RestoreSession(repository),
      logout: Logout(repository),
      fetchPlaylists: FetchPlaylists(repository),
    );
    final playerCubit = _ControllablePlayerCubit(
      repository: repository,
      controller: AudioPlayerHandler(mediaSourceResolver: mediaSourceResolver),
    );
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
    );
    await settingsCubit.load();
    final favoritesCubit = FavoritesCubit(repository);
    final downloadsCubit = DownloadsCubit(
      repository: repository,
      database: database,
      cacheManager: AudioCacheManager(),
    );

    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('app-shell-capture'),
        child: MusicPlayerApp(
          repository: repository,
          settingsRepository: settingsRepository,
          mediaSourceResolver: mediaSourceResolver,
          database: database,
          authCubit: authCubit,
          playerCubit: playerCubit,
          settingsCubit: settingsCubit,
          favoritesCubit: favoritesCubit,
          downloadsCubit: downloadsCubit,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('shell-compact')), findsOneWidget);
    await _captureAppShell(tester, 'app-shell-390x844-hidden');
    expect(
      tester.getSize(find.byKey(const ValueKey('shell-bottom-bar'))).height,
      AppSpacingTokens.mobileTabContentHeight + 34 + 5,
    );
    for (final label in const ['首页', '搜索', '媒体库', '收藏', '设置']) {
      expect(find.text(label), findsWidgets);
    }

    playerCubit.update(
      PlayerViewState(
        queue: const [
          MusicTrack(
            id: 'shell-track',
            title: '夜航星',
            artistName: '乐岛测试歌手',
            albumTitle: '响应式壳层',
            artworkUrl: '',
            duration: Duration(minutes: 3, seconds: 42),
          ),
        ],
        currentIndex: 0,
      ),
    );
    await tester.pumpAndSettle();
    await _captureAppShell(tester, 'app-shell-390x844-visible');

    tester.view.physicalSize = const Size(375, 812);
    await tester.pumpAndSettle();
    await _captureAppShell(tester, 'app-shell-375x812-visible');

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.byKey(const ValueKey('shell-compact'))),
    ).go('/history');
    await tester.pumpAndSettle();
    expect(find.text('播放历史'), findsOneWidget);

    tester.view.physicalSize = const Size(768, 900);
    await tester.pumpAndSettle();
    await _captureAppShell(tester, 'app-shell-768x900');
    expect(tester.takeException(), isNull, reason: '768');
    expect(find.byKey(const ValueKey('shell-medium')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-sidebar-compact')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-toolbar')), findsOneWidget);
    expect(find.text('历史'), findsOneWidget);

    final homeFocus = tester.widget<Focus>(
      find.byKey(const ValueKey('shell-nav-focus-首页')),
    );
    homeFocus.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    expect(homeFocus.focusNode?.hasFocus, isTrue);
    final focusedSurface = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('shell-nav-surface-首页')),
    );
    final focusedDecoration = focusedSurface.decoration! as BoxDecoration;
    expect(focusedDecoration.border?.top.width, AppBorderTokens.focus);
    expect(
      focusedDecoration.border?.top.color,
      Theme.of(
        tester.element(find.byKey(const ValueKey('shell-nav-surface-首页'))),
      ).colorScheme.primary,
    );

    tester.view.physicalSize = const Size(1079, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-medium')), findsOneWidget);

    tester.view.physicalSize = const Size(1080, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-desktop')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-sidebar-wide')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-toolbar-settings')), findsOneWidget);
    expect(find.byTooltip('收起侧边栏'), findsNothing);
    expect(find.text('歌曲'), findsOneWidget);
    final miniPlayerRect = tester.getRect(find.byType(MiniPlayerBar));
    expect(miniPlayerRect.left, 0);
    expect(miniPlayerRect.width, 1080);
    expect(miniPlayerRect.bottom, 900);
    await _captureAppShell(tester, 'app-shell-1080x900-expanded');
    expect(tester.takeException(), isNull, reason: '1080 expanded');

    await tester.tap(find.byKey(const ValueKey('shell-nav-surface-媒体库')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-sidebar-wide')), findsOneWidget);
    expect(find.text('歌曲'), findsNothing);
    expect(find.text('播放历史'), findsOneWidget);
    await _captureAppShell(tester, 'app-shell-1080x900-library-collapsed');
    expect(tester.takeException(), isNull, reason: '1080 library collapsed');

    tester.view.physicalSize = const Size(767, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-compact')), findsOneWidget);
    expect(find.text('播放历史'), findsOneWidget);

    tester.view.physicalSize = const Size(1080, 900);
    expect(tester.takeException(), isNull, reason: '767');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-sidebar-wide')), findsOneWidget);

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    await _captureAppShell(tester, 'app-shell-1440x900');
    expect(tester.takeException(), isNull, reason: '1440');

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    await tester.tap(find.text('搜索').last);
    expect(tester.takeException(), isNull, reason: '390 before search');
    await tester.pumpAndSettle();

    final layoutException = tester.takeException();
    expect(
      layoutException,
      isNull,
      reason: layoutException is FlutterError
          ? layoutException.toStringDeep()
          : layoutException?.toString(),
    );
    expect(find.text('搜索歌曲、专辑、歌手、歌单'), findsOneWidget);

    await tester.tap(find.text('首页').last);
    await tester.pumpAndSettle();
    expect(find.text('播放历史'), findsOneWidget);
  });

  testWidgets('mobile mini player follows V3 transport and touch targets', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    final track = MusicTrack(
      id: 'track-1',
      title: '夜曲',
      artistName: '周杰伦',
      albumTitle: '十一月的萧邦',
      artworkUrl: '',
      duration: const Duration(minutes: 3, seconds: 46),
    );
    final playerCubit = _TrackingMiniPlayerCubit(
      PlayerViewState(queue: [track], currentIndex: 0),
    );
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      _FakeSettingsRepository(),
      mediaSourceResolver,
    );
    await settingsCubit.load();
    addTearDown(playerCubit.close);
    addTearDown(settingsCubit.close);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CustomMediaSourceResolver>.value(
            value: mediaSourceResolver,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PlayerCubit>.value(value: playerCubit),
            BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox.shrink(),
              bottomNavigationBar: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: MiniPlayerBar(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('夜曲'), findsOneWidget);
    expect(find.text('周杰伦'), findsOneWidget);
    expect(find.byTooltip('播放'), findsOneWidget);
    expect(find.byTooltip('下一曲'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('播放')).width, 44);
    expect(tester.getSize(find.byTooltip('播放')).height, 44);
    expect(tester.getSize(find.byTooltip('下一曲')).width, 44);
    expect(tester.getSize(find.byTooltip('下一曲')).height, 44);
    expect(tester.getSize(find.byType(CachedArtwork)).width, 40);
    expect(tester.getSize(find.byType(CachedArtwork)).height, 40);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == '迷你播放器：已暂停',
      ),
      findsOneWidget,
    );

    final swipeDetector = tester.widget<GestureDetector>(
      find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector && widget.onHorizontalDragEnd != null,
      ),
    );
    swipeDetector.onHorizontalDragEnd!(
      DragEndDetails(
        primaryVelocity: -300,
        velocity: const Velocity(pixelsPerSecond: Offset(-300, 0)),
      ),
    );
    expect(playerCubit.nextCalls, 1);

    playerCubit.update(
      playerCubit.state.copyWith(isLoading: true, isPlaying: false),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == '迷你播放器：正在缓冲',
      ),
      findsOneWidget,
    );

    playerCubit.update(
      playerCubit.state.copyWith(isLoading: false, isPlaying: true),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == '迷你播放器：正在播放',
      ),
      findsOneWidget,
    );

    playerCubit.update(
      playerCubit.state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: '播放失败',
      ),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == '迷你播放器：播放失败',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('重试播放'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('重试播放')), const Size(44, 44));
    expect(tester.getSize(find.byTooltip('下一曲')), const Size(44, 44));
  });

  testWidgets('desktop mini player follows V3 three-zone controls', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;

    final repository = _FakeMusicRepository();
    final track = MusicTrack(
      id: 'desktop-track',
      title: '夜曲',
      artistName: '周杰伦',
      albumTitle: '十一月的萧邦',
      artworkUrl: '',
      duration: const Duration(minutes: 3, seconds: 46),
    );
    final playerCubit = _MiniPlayerCubit(
      PlayerViewState(queue: [track], currentIndex: 0),
    );
    final favoritesCubit = FavoritesCubit(repository);
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      _FakeSettingsRepository(),
      mediaSourceResolver,
    );
    await settingsCubit.load();
    addTearDown(playerCubit.close);
    addTearDown(favoritesCubit.close);
    addTearDown(settingsCubit.close);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CustomMediaSourceResolver>.value(
            value: mediaSourceResolver,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PlayerCubit>.value(value: playerCubit),
            BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
            BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          ],
          child: const MaterialApp(
            home: Scaffold(bottomNavigationBar: MiniPlayerBar()),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MiniPlayerBar)).height, 92);
    for (final tooltip in const ['收藏', '上一曲', '播放', '下一曲', '当前歌单', '静音']) {
      expect(find.byTooltip(tooltip), findsOneWidget);
    }
    expect(find.text('标准音质'), findsOneWidget);
    expect(find.byTooltip('播放模式：顺序播放，点击切换'), findsOneWidget);
    expect(find.byTooltip('查看歌词'), findsNothing);
    expect(find.byTooltip('展开播放器'), findsNothing);

    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byTooltip('静音')));
    await mouse.moveTo(tester.getCenter(find.byTooltip('静音')));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));

    await tester.tap(find.byTooltip('静音'));
    await tester.pump();
    expect(playerCubit.state.volume, 0);
    expect(find.byTooltip('取消静音'), findsOneWidget);

    await tester.tap(find.byTooltip('取消静音'));
    await tester.pump();
    expect(playerCubit.state.volume, 1);
  });

  testWidgets(
    'mini player remains visible without a track',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final playerCubit = _MiniPlayerCubit(const PlayerViewState());
      addTearDown(playerCubit.close);

      for (final size in const [Size(390, 844), Size(1280, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          BlocProvider<PlayerCubit>.value(
            value: playerCubit,
            child: const MaterialApp(
              home: Scaffold(bottomNavigationBar: MiniPlayerBar()),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(MiniPlayerBar), findsOneWidget);
        expect(tester.getSize(find.byType(MiniPlayerBar)).height, isNonZero);
        expect(find.text('未在播放'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'mobile queue sheet supports row actions and clear confirmation',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      final tracks = [
        const MusicTrack(
          id: 'queue-1',
          title: '夜曲',
          artistName: '周杰伦',
          albumTitle: '十一月的萧邦',
          artworkUrl: '',
          duration: Duration(minutes: 3, seconds: 46),
        ),
        const MusicTrack(
          id: 'queue-2',
          title: '晴天',
          artistName: '周杰伦',
          albumTitle: '叶惠美',
          artworkUrl: '',
          duration: Duration(minutes: 4, seconds: 29),
        ),
      ];
      final playerCubit = _MiniPlayerCubit(
        PlayerViewState(queue: tracks, currentIndex: 0, isPlaying: true),
      );
      final mediaSourceResolver = CustomMediaSourceResolver();
      final settingsCubit = AppSettingsCubit(
        _FakeSettingsRepository(),
        mediaSourceResolver,
      );
      await settingsCubit.load();
      addTearDown(playerCubit.close);
      addTearDown(settingsCubit.close);

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CustomMediaSourceResolver>.value(
              value: mediaSourceResolver,
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<PlayerCubit>.value(value: playerCubit),
              BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
            ],
            child: const MaterialApp(home: Scaffold(body: QueueSheet())),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('播放队列'), findsOneWidget);
      expect(find.text('2 首歌曲'), findsOneWidget);
      expect(find.text('清空'), findsOneWidget);
      expect(find.byTooltip('移出队列'), findsNWidgets(2));
      expect(find.byTooltip('拖拽排序'), findsNWidgets(2));

      await tester.tap(find.text('清空'));
      await tester.pumpAndSettle();
      expect(find.text('确定清空播放队列？'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    },
  );

  testWidgets('mobile playlist grid card keeps title within compact cell', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      _FakeSettingsRepository(),
      mediaSourceResolver,
    );
    await settingsCubit.load();
    addTearDown(settingsCubit.close);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CustomMediaSourceResolver>.value(
            value: mediaSourceResolver,
          ),
        ],
        child: BlocProvider<AppSettingsCubit>.value(
          value: settingsCubit,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 164,
                  height: 193.7,
                  child: MusicPlaylistGridCard(
                    playlist: const MusicPlaylist(
                      id: 'playlist-overflow',
                      name: '一个非常非常长的移动端测试歌单标题',
                      artworkUrl: '',
                      trackCount: 128,
                    ),
                    onTap: () {},
                    artworkRadius: AppRadiusTokens.mobileMd,
                    compact: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('一个非常非常长的移动端测试歌单标题'), findsOneWidget);
  });

  testWidgets('desktop playlist grid card keeps V3 text stack within cell', (
    tester,
  ) async {
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      _FakeSettingsRepository(),
      mediaSourceResolver,
    );
    await settingsCubit.load();
    addTearDown(settingsCubit.close);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CustomMediaSourceResolver>.value(
            value: mediaSourceResolver,
          ),
        ],
        child: BlocProvider<AppSettingsCubit>.value(
          value: settingsCubit,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 172,
                  height: 239,
                  child: MusicPlaylistGridCard(
                    playlist: const MusicPlaylist(
                      id: 'desktop-playlist-overflow',
                      name: '《2026 必听热曲大合集》',
                      artworkUrl: '',
                      trackCount: 199,
                    ),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '打开歌单《《2026 必听热曲大合集》》',
      ),
      findsOneWidget,
    );
    expect(find.text('199 首歌曲'), findsOneWidget);
  });

  testWidgets('dense app action button keeps a 44px touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppActionButton(
              icon: Icons.delete_sweep_rounded,
              label: '清空',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final button = find.widgetWithText(TextButton, '清空');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
  });

  testWidgets('app back button exposes tooltip and touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: AppBackButton(onPressed: () {})),
        ),
      ),
    );

    final button = find.byTooltip('返回');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
  });

  testWidgets('renders empty favorites page', (tester) async {
    final repository = _FakeMusicRepository();
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
    );
    await settingsCubit.load();
    final favoritesCubit = FavoritesCubit(repository);
    final playerCubit = PlayerCubit(
      repository: repository,
      controller: AudioPlayerHandler(mediaSourceResolver: mediaSourceResolver),
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<MusicRepository>.value(value: repository),
          RepositoryProvider<SettingsRepository>.value(
            value: settingsRepository,
          ),
          RepositoryProvider<CustomMediaSourceResolver>.value(
            value: mediaSourceResolver,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
            BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
            BlocProvider<PlayerCubit>.value(value: playerCubit),
          ],
          child: const MaterialApp(home: FavoritesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('收藏'), findsWidgets);
    expect(find.text('还没有收藏歌曲'), findsOneWidget);
    expect(find.text('在媒体库或播放页点亮爱心后，歌曲会集中显示在这里。'), findsOneWidget);
    expect(find.byTooltip('返回'), findsNothing);
    expect(find.byType(AppContentPage), findsOneWidget);
  });

  testWidgets('renders empty history page', (tester) async {
    final repository = _FakeMusicRepository();
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
    );
    await settingsCubit.load();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final playerCubit = PlayerCubit(
      repository: repository,
      controller: AudioPlayerHandler(mediaSourceResolver: mediaSourceResolver),
    );
    addTearDown(database.close);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AppDatabase>.value(value: database),
          RepositoryProvider<SettingsRepository>.value(
            value: settingsRepository,
          ),
          RepositoryProvider<CustomMediaSourceResolver>.value(
            value: mediaSourceResolver,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
            BlocProvider<PlayerCubit>.value(value: playerCubit),
          ],
          child: const MaterialApp(home: HistoryPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('历史'), findsWidgets);
    expect(find.text('还没有播放历史'), findsOneWidget);
    expect(find.text('开始播放后，最近听过的歌曲会自动记录在这里。'), findsOneWidget);
    expect(find.byTooltip('返回'), findsNothing);
    expect(find.byType(AppContentPage), findsOneWidget);
  });

  testWidgets('history page with tracks keeps mobile header responsive', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    final repository = _FakeMusicRepository();
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
    );
    await settingsCubit.load();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.insertPlayHistory(
      PlayHistoryCompanion.insert(
        trackId: 'history-track-1',
        title: '最近听过的歌',
        artistName: const Value('测试歌手'),
        albumTitle: const Value('测试专辑'),
        playedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    final playerCubit = PlayerCubit(
      repository: repository,
      controller: AudioPlayerHandler(mediaSourceResolver: mediaSourceResolver),
    );
    addTearDown(database.close);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AppDatabase>.value(value: database),
          RepositoryProvider<SettingsRepository>.value(
            value: settingsRepository,
          ),
          RepositoryProvider<CustomMediaSourceResolver>.value(
            value: mediaSourceResolver,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
            BlocProvider<PlayerCubit>.value(value: playerCubit),
          ],
          child: MaterialApp(
            initialRoute: '/history',
            routes: {
              '/': (_) => const Scaffold(body: Text('Root')),
              '/history': (_) => const HistoryPage(),
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 320));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('返回'), findsOneWidget);
    expect(find.text('播放全部'), findsNothing);
    expect(find.text('播放历史'), findsWidgets);
    expect(find.text('最近听过的歌'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('清空'), findsNothing);
  });
}

Future<void> _captureAppShell(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_APP_SHELL_SCREENSHOTS'] != 'true') return;

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('app-shell-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('Unable to encode App Shell screenshot');
    }

    final directory = Directory('design-reference/screenshots/actual');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });
}

Future<void> _captureLogin(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_LOGIN_SCREENSHOTS'] != 'true') return;

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('v3-login-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Unable to encode login screenshot');

    final directory = Directory('design-reference/screenshots/actual');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });
}

const _authenticatedSession = AuthSession(
  serverUrl: 'https://music.example.test',
  userId: 'user-1',
  userName: '测试用户',
  accessToken: 'token',
  backendType: MusicBackendType.navidrome,
);

class _MiniPlayerCubit extends Cubit<PlayerViewState> implements PlayerCubit {
  _MiniPlayerCubit(super.initialState);

  void update(PlayerViewState state) => emit(state);

  @override
  Future<void> setVolume(double volume) async {
    emit(state.copyWith(volume: volume));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingMiniPlayerCubit extends _MiniPlayerCubit {
  _TrackingMiniPlayerCubit(super.initialState);

  int nextCalls = 0;

  @override
  Future<void> next() async {
    nextCalls += 1;
  }
}

class _ControllablePlayerCubit extends PlayerCubit {
  _ControllablePlayerCubit({
    required super.repository,
    required super.controller,
  });

  void update(PlayerViewState next) => emit(next);
}

class _FakeMusicRepository implements MusicRepository {
  _FakeMusicRepository({this.session, this.loginCompleter});

  final AuthSession? session;
  final Completer<AuthSession>? loginCompleter;

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async => [];

  @override
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) async => [];

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async => const PaginatedResult(items: []);

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => [];

  @override
  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) async => [];

  @override
  Future<List<Genre>> fetchGenres() async => [];

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => [];

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async => [];

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async => [];

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) async => '';

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) =>
      loginCompleter?.future ?? Future.value(session ?? _authenticatedSession);

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<void> setFavorite(String itemId, bool value) async {}

  @override
  Future<List<LyricLine>?> fetchLyrics(String trackId) async => null;

  @override
  Future<void> reportPlaybackStart(
    String trackId,
    String playSessionId,
  ) async {}

  @override
  Future<void> reportPlaybackProgress(
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  }) async {}

  @override
  Future<void> reportPlaybackStopped(
    String trackId,
    String playSessionId,
    Duration position,
  ) async {}

  @override
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) async => [];

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) async => [];

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async => [];

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) async => [];

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async => [];

  @override
  Future<SearchResults> search(String query) async => SearchResults.empty;
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettingsSnapshot _snap = const AppSettingsSnapshot();

  @override
  Future<AppSettingsSnapshot> load() async => _snap;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    _snap = _snap.copyWith(themeMode: mode);
  }

  @override
  Future<void> saveDefaultQuality(AudioQuality quality) async {
    _snap = _snap.copyWith(defaultQuality: quality);
  }

  @override
  Future<void> saveGapBetweenTracks(Duration gap) async {
    _snap = _snap.copyWith(gapBetweenTracks: gap);
  }

  @override
  Future<void> saveLyricSyncOffset(Duration offset) async {
    _snap = _snap.copyWith(lyricSyncOffset: offset);
  }

  @override
  Future<void> saveMenuBarLyricsEnabled(bool enabled) async {
    _snap = _snap.copyWith(menuBarLyricsEnabled: enabled);
  }

  @override
  Future<void> saveCustomArtworkSourceEnabled(bool enabled) async {
    _snap = _snap.copyWith(customArtworkSourceEnabled: enabled);
  }

  @override
  Future<void> saveCustomArtworkSourceUrl(String url) async {
    _snap = _snap.copyWith(customArtworkSourceUrl: url);
  }

  @override
  Future<void> saveCustomLyricsSourceEnabled(bool enabled) async {
    _snap = _snap.copyWith(customLyricsSourceEnabled: enabled);
  }

  @override
  Future<void> saveCustomLyricsSourceUrl(String url) async {
    _snap = _snap.copyWith(customLyricsSourceUrl: url);
  }
}

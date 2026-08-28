import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/application/usecases/login_with_emby.dart';
import 'package:cross_platform_music_player/application/usecases/logout.dart';
import 'package:cross_platform_music_player/application/usecases/restore_session.dart';
import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/cache/audio_cache_manager.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/downloads/downloads_page.dart';
import 'package:cross_platform_music_player/presentation/pages/library/library_page.dart';
import 'package:cross_platform_music_player/presentation/pages/player/player_page.dart';
import 'package:cross_platform_music_player/presentation/pages/playlists/playlist_detail_page.dart';
import 'package:cross_platform_music_player/presentation/pages/settings/settings_page.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/queue_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('SettingsPage_responsiveSmoke_hasNoLayoutExceptions', (
    tester,
  ) async {
    final harness = await _SettingsHarness.create();
    addTearDown(harness.dispose);

    await _pumpForSizes(
      tester,
      build: () => harness.wrap(const SettingsPage()),
      verify: (_) {
        expect(find.byType(AppContentPage), findsOneWidget);
        expect(find.text('设置'), findsOneWidget);
        expect(find.text('服务器'), findsOneWidget);
        expect(find.text('外观'), findsOneWidget);
        expect(find.text('播放'), findsOneWidget);
      },
    );
  });

  testWidgets('SettingsPage_mobileCustomMediaSources_opensDetailPage', (
    tester,
  ) async {
    final harness = await _SettingsHarness.create();
    addTearDown(harness.dispose);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => const Scaffold(body: SettingsPage()),
        ),
        GoRoute(
          path: '/settings/media-sources',
          builder: (_, _) => const Scaffold(body: CustomMediaSourcesPage()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpMobile(
      tester,
      build: () => harness.wrapRouter(router),
      verify: () {
        expect(find.text('设置'), findsWidgets);
        expect(find.text('歌词与封面'), findsOneWidget);
        expect(find.text('歌曲封面来源'), findsNothing);
        expect(find.text('歌词来源'), findsNothing);
      },
    );

    await tester.tap(find.text('歌词与封面'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 320));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('返回'), findsNothing);
    expect(find.text('歌词与封面'), findsWidgets);
    expect(find.text('自定义媒体来源'), findsOneWidget);
    expect(find.text('歌曲封面来源'), findsOneWidget);
    expect(find.text('歌词来源'), findsOneWidget);
    expect(find.text('自定义地址'), findsNothing);
    expect(tester.getTopLeft(find.text('歌词与封面').last).dx, closeTo(24, 0.1));

    final contentList = tester.widget<ListView>(find.byType(ListView));
    expect(
      contentList.padding,
      const EdgeInsets.fromLTRB(24, 0, 24, AppPageLayout.contentBottomInset),
    );

    await tester.tap(find.bySemanticsLabel('开启 歌曲封面来源'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(tester.takeException(), isNull);
    expect(find.text('自定义地址'), findsOneWidget);
    expect(find.text('测试连接'), findsOneWidget);
    expect(find.text('保存设置'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'not-a-url');
    await tester.pump();
    await tester.tap(find.text('测试连接'));
    await tester.pump();

    expect(find.text('请输入合法的 http/https URL。'), findsWidgets);
  });

  testWidgets('CustomMediaSourcesPage_desktopExposesCenteredSave', (
    tester,
  ) async {
    final harness = await _SettingsHarness.create();
    addTearDown(harness.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(harness.wrap(const CustomMediaSourcesPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.bySemanticsLabel('开启 歌曲封面来源'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('测试连接'), findsOneWidget);
    expect(find.text('保存全部'), findsNothing);
    expect(find.text('保存'), findsOneWidget);
    expect(find.byTooltip('返回'), findsNothing);

    final saveButton = find.widgetWithText(FilledButton, '保存');
    final saveIcon = find.descendant(
      of: saveButton,
      matching: find.byIcon(Icons.save_rounded),
    );
    final saveLabel = find.descendant(
      of: saveButton,
      matching: find.text('保存'),
    );
    expect(
      tester.getCenter(saveIcon).dy,
      closeTo(tester.getCenter(saveLabel).dy, 1),
    );
  });

  testWidgets('DownloadsPage_responsiveSmoke_hasNoLayoutExceptions', (
    tester,
  ) async {
    final harness = _DownloadsHarness.create();
    addTearDown(harness.dispose);

    await _pumpForSizes(
      tester,
      build: () => harness.wrap(const DownloadsPage()),
      verify: (_) {
        expect(find.byType(AppContentPage), findsOneWidget);
        expect(find.text('下载管理'), findsNothing);
        expect(find.text('管理离线缓存、下载任务和本地存储。'), findsNothing);
        expect(find.text('已下载'), findsOneWidget);
        expect(find.text('下载中'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('download-quality-menu')),
          findsOneWidget,
        );
        expect(find.byTooltip('修改下载目录'), findsOneWidget);
        expect(find.text('还没有下载内容'), findsOneWidget);
      },
    );
  });

  testWidgets('DownloadsPage_directoryEditor_exposesFolderPicker', (
    tester,
  ) async {
    final harness = _DownloadsHarness.create();
    addTearDown(harness.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(harness.wrap(const DownloadsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byTooltip('修改下载目录'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('选择文件夹'), findsOneWidget);
    expect(find.text('保存更改'), findsOneWidget);
    expect(find.text('当前保存位置'), findsOneWidget);
    expect(find.byType(AppSheetScaffold), findsNothing);
  });

  testWidgets('DownloadsPage_qualityMenu_updatesDefaultQuality', (
    tester,
  ) async {
    final harness = _DownloadsHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.wrap(const DownloadsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('download-quality-menu')));
    await tester.pumpAndSettle();

    expect(find.text('自动选择'), findsOneWidget);
    expect(find.text('按网络与可用音源选择'), findsOneWidget);
    expect(find.text('320 kbps · 兼顾细节与空间'), findsOneWidget);

    await tester.tap(find.text('无损').last);
    await tester.pumpAndSettle();

    expect(harness.downloadsCubit.state.downloadQuality, AudioQuality.lossless);
    expect(find.text('下载音质  无损'), findsOneWidget);
  });

  testWidgets('LibraryPage_mobileLoadingState_hidesEmptyState', (tester) async {
    final repository = _DelayedLibraryRepository();
    final playerCubit = _FakeQueuePlayerCubit();
    addTearDown(playerCubit.close);

    await _pumpMobile(
      tester,
      build: () => MultiRepositoryProvider(
        providers: [
          RepositoryProvider<MusicRepository>.value(value: repository),
        ],
        child: BlocProvider<PlayerCubit>.value(
          value: playerCubit,
          child: const MaterialApp(home: Scaffold(body: LibraryPage())),
        ),
      ),
      verify: () {
        expect(find.text('媒体库'), findsWidgets);
        expect(find.bySemanticsLabel('正在加载歌曲'), findsOneWidget);
        expect(find.text('当前还没有歌曲。'), findsNothing);
      },
    );

    repository.completeTracks();
    await tester.pump();
  });

  testWidgets('LibraryPage_emptyState_keepsFourCategoriesAcrossBreakpoints', (
    tester,
  ) async {
    final repository = _FakeMusicRepository();
    final playerCubit = _FakeQueuePlayerCubit();
    addTearDown(playerCubit.close);

    await _pumpForSizes(
      tester,
      build: () => _wrapLibrary(repository, playerCubit),
      verify: (_) {
        expect(find.text('歌曲'), findsOneWidget);
        expect(find.text('专辑'), findsOneWidget);
        expect(find.text('歌手'), findsOneWidget);
        expect(find.text('歌单'), findsOneWidget);
        expect(find.text('当前还没有歌曲。'), findsOneWidget);
      },
    );
  });

  testWidgets('LibraryPage_failureState_exposesRetryAction', (tester) async {
    final repository = _FailingLibraryRepository();
    final playerCubit = _FakeQueuePlayerCubit();
    addTearDown(playerCubit.close);

    await _pumpMobile(
      tester,
      build: () => _wrapLibrary(repository, playerCubit),
      verify: () {
        expect(find.textContaining('加载媒体库失败'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, '重新加载'), findsOneWidget);
      },
    );
  });

  testWidgets('LibraryPage_desktopUsesSidebarFilterWithoutTabsOrSearch', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    final repository = _FakeMusicRepository(
      libraryAlbums: const [
        MusicAlbum(
          id: 'album-1',
          title: '很长的专辑名称用于验证媒体库布局',
          artistName: '测试歌手',
          artworkUrl: '',
          trackCount: 10,
        ),
      ],
      libraryArtists: const [
        MusicArtist(id: 'artist-1', name: '很长的歌手名称用于验证媒体库布局', artworkUrl: ''),
      ],
      libraryPlaylists: const [
        MusicPlaylist(
          id: 'playlist-library-1',
          name: '很长的歌单名称用于验证媒体库布局',
          artworkUrl: '',
        ),
      ],
    );
    final playerCubit = _FakeQueuePlayerCubit();
    addTearDown(playerCubit.close);

    await tester.pumpWidget(_wrapLibrary(repository, playerCubit));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('搜索歌曲'), findsNothing);
    expect(find.text('歌曲'), findsOneWidget);
    expect(find.text('专辑'), findsNothing);
    expect(find.text('歌手'), findsNothing);
    expect(find.text('歌单'), findsNothing);
    expect(find.text('很长的专辑名称用于验证媒体库布局'), findsNothing);
    expect(find.text('很长的歌手名称用于验证媒体库布局'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('QueueSheet_emptyState_keepsResponsiveSheetStructure', (
    tester,
  ) async {
    final harness = _QueueHarness.create();
    addTearDown(harness.dispose);

    await _pumpForSizes(
      tester,
      build: () => harness.wrap(const QueueSheet()),
      verify: (_) {
        expect(find.text('播放队列'), findsOneWidget);
        expect(find.text('0 首歌曲'), findsOneWidget);
        expect(find.text('当前播放队列为空'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'PlayerPage_desktopSmoke_usesThreeColumnLayoutAndPersistentQueue',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;

      final tracks = _playlistTracks();
      final repository = _FakeMusicRepository(playlistTracks: tracks);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final playerCubit = _FakeQueuePlayerCubit(
        PlayerViewState(
          queue: tracks,
          currentIndex: 0,
          isPlaying: true,
          position: const Duration(minutes: 1, seconds: 18),
          duration: tracks.first.duration,
        ),
      );
      final favoritesCubit = FavoritesCubit(repository);
      final downloadsCubit = DownloadsCubit(
        repository: repository,
        database: database,
        cacheManager: AudioCacheManager(),
      );
      final mediaSourceResolver = CustomMediaSourceResolver();
      final settingsCubit = AppSettingsCubit(
        _FakeSettingsRepository(),
        mediaSourceResolver,
      );
      await settingsCubit.load();
      addTearDown(playerCubit.close);
      addTearDown(favoritesCubit.close);
      addTearDown(downloadsCubit.close);
      addTearDown(settingsCubit.close);
      addTearDown(database.close);

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<MusicRepository>.value(value: repository),
            RepositoryProvider<CustomMediaSourceResolver>.value(
              value: mediaSourceResolver,
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<PlayerCubit>.value(value: playerCubit),
              BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
              BlocProvider<DownloadsCubit>.value(value: downloadsCubit),
              BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
            ],
            child: const MaterialApp(home: PlayerPage()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(tester.takeException(), isNull);
      expect(find.text('正在播放'), findsOneWidget);
      expect(find.text('夜曲'), findsWidgets);
      expect(find.text('红豆'), findsNothing);
      expect(find.text('HI-RES'), findsOneWidget);
      expect(find.text('FLAC'), findsOneWidget);
      expect(find.byTooltip('收起播放页'), findsOneWidget);
      expect(find.byTooltip('更多操作'), findsOneWidget);
      expect(find.byTooltip('播放队列'), findsWidgets);

      await tester.tap(find.byTooltip('播放队列').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));

      expect(find.text('红豆'), findsOneWidget);
      expect(find.byTooltip('定位到当前播放'), findsOneWidget);
      expect(find.byTooltip('关闭播放队列'), findsNothing);

      await tester.tapAt(const Offset(24, 420));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));

      expect(find.text('红豆'), findsNothing);

      await tester.tap(find.byTooltip('更多操作'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));

      expect(tester.takeException(), isNull);
      expect(find.text('添加到当前队列'), findsOneWidget);
      expect(find.text('播放音质'), findsOneWidget);
      expect(find.text('睡眠定时'), findsOneWidget);
    },
  );

  testWidgets('PlaylistDetailPage_mobileSmoke_hasNoLayoutExceptions', (
    tester,
  ) async {
    final playlist = MusicPlaylist(
      id: 'playlist-1',
      name: '很长很长的深夜独处歌单标题用于验证移动端换行和视觉层级',
      artworkUrl: '',
      trackCount: 3,
    );
    final repository = _FakeMusicRepository(playlistTracks: _playlistTracks());
    final playerCubit = _FakeQueuePlayerCubit();
    final favoritesCubit = FavoritesCubit(repository);
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
    );
    await settingsCubit.load();
    addTearDown(playerCubit.close);
    addTearDown(favoritesCubit.close);
    addTearDown(settingsCubit.close);

    await _pumpMobile(
      tester,
      build: () => MultiRepositoryProvider(
        providers: [
          RepositoryProvider<MusicRepository>.value(value: repository),
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
          child: MaterialApp(
            home: PlaylistDetailPage(
              playlistId: playlist.id,
              playlist: playlist,
            ),
          ),
        ),
      ),
      verify: () {
        expect(find.text('播放'), findsOneWidget);
        expect(find.text('加入队列'), findsNothing);
        expect(find.text('歌曲'), findsOneWidget);
        expect(find.text('夜曲'), findsOneWidget);
        expect(find.text('红豆'), findsOneWidget);
        expect(find.byTooltip('播放歌曲'), findsNWidgets(3));
        expect(find.byTooltip('收藏'), findsNWidgets(3));
        expect(find.byTooltip('加入队列'), findsNWidgets(3));
      },
    );
  });

  testWidgets('PlaylistDetailPage_desktopHero_usesSideBySideLayout', (
    tester,
  ) async {
    final playlist = MusicPlaylist(
      id: 'playlist-1',
      name: '深夜独处',
      artworkUrl: '',
      trackCount: 3,
    );
    final repository = _FakeMusicRepository(playlistTracks: _playlistTracks());
    final playerCubit = _FakeQueuePlayerCubit();
    final favoritesCubit = FavoritesCubit(repository);
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
    );
    await settingsCubit.load();
    addTearDown(playerCubit.close);
    addTearDown(favoritesCubit.close);
    addTearDown(settingsCubit.close);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<MusicRepository>.value(value: repository),
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
          child: MaterialApp(
            home: PlaylistDetailPage(
              playlistId: playlist.id,
              playlist: playlist,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 320));

    expect(tester.takeException(), isNull);
    expect(find.text('返回'), findsNothing);
    expect(find.text('深夜独处'), findsOneWidget);
    expect(find.text('播放全部'), findsOneWidget);

    final coverRect = tester.getRect(find.byType(CachedArtwork).first);
    final titleRect = tester.getRect(find.text('深夜独处'));
    final actionsRect = tester.getRect(find.byType(PlayAllButton));

    expect(titleRect.left, greaterThan(coverRect.right));
    expect(titleRect.top, lessThan(coverRect.bottom));
    expect(titleRect.bottom, greaterThan(coverRect.top));
    expect(
      actionsRect.bottom,
      closeTo(coverRect.bottom + AppSpacingTokens.compactGap, 0.1),
    );
  });
}

Future<void> _pumpForSizes(
  WidgetTester tester, {
  required Widget Function() build,
  required ValueChanged<Size> verify,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  for (final size in const [
    Size(375, 812),
    Size(390, 844),
    Size(768, 900),
    Size(1080, 720),
    Size(1280, 900),
    Size(1440, 900),
  ]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(build());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 320));

    expect(tester.takeException(), isNull);
    verify(size);
  }
}

Future<void> _pumpMobile(
  WidgetTester tester, {
  required Widget Function() build,
  required VoidCallback verify,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;

  await tester.pumpWidget(build());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
  await tester.pump(const Duration(milliseconds: 320));

  expect(tester.takeException(), isNull);
  verify();
}

Widget _wrapLibrary(MusicRepository repository, PlayerCubit playerCubit) {
  final mediaSourceResolver = CustomMediaSourceResolver();
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<MusicRepository>.value(value: repository),
      RepositoryProvider<CustomMediaSourceResolver>.value(
        value: mediaSourceResolver,
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>.value(value: playerCubit),
        BlocProvider<AppSettingsCubit>(
          create: (_) =>
              AppSettingsCubit(_FakeSettingsRepository(), mediaSourceResolver)
                ..load(),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: LibraryPage())),
    ),
  );
}

class _SettingsHarness {
  _SettingsHarness({
    required this.repository,
    required this.settingsRepository,
    required this.mediaSourceResolver,
    required this.authCubit,
    required this.settingsCubit,
  });

  final _FakeMusicRepository repository;
  final _FakeSettingsRepository settingsRepository;
  final CustomMediaSourceResolver mediaSourceResolver;
  final AuthCubit authCubit;
  final AppSettingsCubit settingsCubit;

  static Future<_SettingsHarness> create() async {
    final repository = _FakeMusicRepository();
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final authCubit = AuthCubit(
      loginWithEmby: LoginWithEmby(repository),
      restoreSession: RestoreSession(repository),
      logout: Logout(repository),
      fetchPlaylists: FetchPlaylists(repository),
    );
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
    );
    await settingsCubit.load();

    return _SettingsHarness(
      repository: repository,
      settingsRepository: settingsRepository,
      mediaSourceResolver: mediaSourceResolver,
      authCubit: authCubit,
      settingsCubit: settingsCubit,
    );
  }

  Widget wrap(Widget child) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicRepository>.value(value: repository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<CustomMediaSourceResolver>.value(
          value: mediaSourceResolver,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  Widget wrapRouter(GoRouter router) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicRepository>.value(value: repository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<CustomMediaSourceResolver>.value(
          value: mediaSourceResolver,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  Future<void> dispose() async {
    await settingsCubit.close();
    await authCubit.close();
  }
}

class _DownloadsHarness {
  _DownloadsHarness({
    required this.repository,
    required this.database,
    required this.downloadsCubit,
  });

  final _FakeMusicRepository repository;
  final AppDatabase database;
  final DownloadsCubit downloadsCubit;

  static _DownloadsHarness create() {
    final repository = _FakeMusicRepository();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final downloadsCubit = DownloadsCubit(
      repository: repository,
      database: database,
      cacheManager: AudioCacheManager(),
    );

    return _DownloadsHarness(
      repository: repository,
      database: database,
      downloadsCubit: downloadsCubit,
    );
  }

  Widget wrap(Widget child) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicRepository>.value(value: repository),
        RepositoryProvider<AppDatabase>.value(value: database),
      ],
      child: BlocProvider<DownloadsCubit>.value(
        value: downloadsCubit,
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  Future<void> dispose() async {
    await downloadsCubit.close();
    await database.close();
  }
}

class _QueueHarness {
  _QueueHarness({required this.playerCubit});

  final _FakeQueuePlayerCubit playerCubit;

  static _QueueHarness create() {
    return _QueueHarness(playerCubit: _FakeQueuePlayerCubit());
  }

  Widget wrap(Widget child) {
    return BlocProvider<PlayerCubit>.value(
      value: playerCubit,
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  Future<void> dispose() async {
    await playerCubit.close();
  }
}

class _FakeQueuePlayerCubit extends Cubit<PlayerViewState>
    implements PlayerCubit {
  _FakeQueuePlayerCubit([super.initialState = const PlayerViewState()]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<MusicTrack> _playlistTracks() {
  return const [
    MusicTrack(
      id: 'track-1',
      title: '夜曲',
      artistName: '周杰伦',
      albumTitle: '十一月的萧邦',
      artworkUrl: '',
      duration: Duration(minutes: 3, seconds: 46),
      bitRate: 1_100_000,
      codec: 'flac',
    ),
    MusicTrack(
      id: 'track-2',
      title: '红豆',
      artistName: '王菲',
      albumTitle: '唱游',
      artworkUrl: '',
      duration: Duration(minutes: 5, seconds: 12),
    ),
    MusicTrack(
      id: 'track-3',
      title: '很长很长的歌曲标题用于验证移动端歌单详情行内容不会横向溢出',
      artistName: '很长很长的歌手名称',
      albumTitle: '很长很长的专辑名称',
      artworkUrl: '',
      duration: Duration(minutes: 4, seconds: 38),
    ),
  ];
}

class _FakeMusicRepository implements MusicRepository {
  _FakeMusicRepository({
    this.playlistTracks = const [],
    this.libraryAlbums = const [],
    this.libraryArtists = const [],
    this.libraryPlaylists = const [],
  });

  final List<MusicTrack> playlistTracks;
  final List<MusicAlbum> libraryAlbums;
  final List<MusicArtist> libraryArtists;
  final List<MusicPlaylist> libraryPlaylists;

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
  }) async => libraryAlbums;

  @override
  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) async => libraryArtists;

  @override
  Future<List<Genre>> fetchGenres() async => [];

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => libraryPlaylists;

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async => [];

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async {
    final effectiveLimit = limit ?? playlistTracks.length;
    return playlistTracks.skip(startIndex).take(effectiveLimit).toList();
  }

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
  }) async {
    return _session;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => _session;

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

class _DelayedLibraryRepository extends _FakeMusicRepository {
  _DelayedLibraryRepository() : _tracksCompleter = Completer();

  final Completer<PaginatedResult<MusicTrack>> _tracksCompleter;

  void completeTracks({List<MusicTrack> tracks = const []}) {
    if (_tracksCompleter.isCompleted) return;
    _tracksCompleter.complete(
      PaginatedResult<MusicTrack>(items: tracks, totalCount: tracks.length),
    );
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _tracksCompleter.future;
  }
}

class _FailingLibraryRepository extends _FakeMusicRepository {
  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    throw Exception('offline');
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettingsSnapshot _snapshot = const AppSettingsSnapshot();

  @override
  Future<AppSettingsSnapshot> load() async => _snapshot;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    _snapshot = _snapshot.copyWith(themeMode: mode);
  }

  @override
  Future<void> saveDefaultQuality(AudioQuality quality) async {
    _snapshot = _snapshot.copyWith(defaultQuality: quality);
  }

  @override
  Future<void> saveGapBetweenTracks(Duration gap) async {
    _snapshot = _snapshot.copyWith(gapBetweenTracks: gap);
  }

  @override
  Future<void> saveLyricSyncOffset(Duration offset) async {
    _snapshot = _snapshot.copyWith(lyricSyncOffset: offset);
  }

  @override
  Future<void> saveMenuBarLyricsEnabled(bool enabled) async {
    _snapshot = _snapshot.copyWith(menuBarLyricsEnabled: enabled);
  }

  @override
  Future<void> saveCustomArtworkSourceEnabled(bool enabled) async {
    _snapshot = _snapshot.copyWith(customArtworkSourceEnabled: enabled);
  }

  @override
  Future<void> saveCustomArtworkSourceUrl(String url) async {
    _snapshot = _snapshot.copyWith(customArtworkSourceUrl: url);
  }

  @override
  Future<void> saveCustomLyricsSourceEnabled(bool enabled) async {
    _snapshot = _snapshot.copyWith(customLyricsSourceEnabled: enabled);
  }

  @override
  Future<void> saveCustomLyricsSourceUrl(String url) async {
    _snapshot = _snapshot.copyWith(customLyricsSourceUrl: url);
  }
}

const _session = AuthSession(
  serverUrl: 'https://music.example.test',
  userId: 'user-1',
  userName: '测试用户',
  accessToken: 'token',
  backendType: MusicBackendType.navidrome,
);

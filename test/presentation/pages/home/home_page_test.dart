import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/application/usecases/fetch_latest_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_random_albums.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/home/home_page.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/artwork_hover_overlay.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('首页空、部分失败和完全失败状态可见', (tester) async {
    final cubit = _TestHomeCubit();
    addTearDown(cubit.close);
    await _pumpHome(tester, cubit, const HomeState(status: HomeStatus.success));
    expect(find.text('还没有可展示的音乐'), findsOneWidget);
    await _pumpHome(
      tester,
      cubit,
      HomeState(
        status: HomeStatus.success,
        albums: _albums,
        errorMessage: '随机内容加载失败，请稍后重试',
      ),
    );
    expect(find.text('随机内容加载失败，请稍后重试'), findsOneWidget);
    expect(find.text('最新添加'), findsOneWidget);
    await _pumpHome(
      tester,
      cubit,
      const HomeState(status: HomeStatus.failure, errorMessage: '首页加载失败'),
    );
    expect(find.text('首页加载失败'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
  });

  testWidgets('首页加载状态保持区块骨架', (tester) async {
    final cubit = _TestHomeCubit();
    addTearDown(cubit.close);
    await _pumpHome(tester, cubit, const HomeState(status: HomeStatus.loading));
    expect(find.byKey(const ValueKey('home-loading-sections')), findsOneWidget);
  });

  testWidgets('桌面首页使用发现型首屏且当前曲目仅保留轻量标识', (tester) async {
    final cubit = _TestHomeCubit();
    addTearDown(cubit.close);
    await _setViewport(tester, const ui.Size(1280, 720));
    await _pumpHome(
      tester,
      cubit,
      const HomeState(
        status: HomeStatus.success,
        recentlyPlayed: _tracks,
        albums: _albums,
      ),
      capture: true,
      themeMode: ThemeMode.dark,
    );

    expect(find.byKey(const ValueKey('home-discovery-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('ambient-home-hero')), findsNothing);
    expect(find.byKey(const ValueKey('home-recent-desktop')), findsOneWidget);
    expect(find.text('为你发现'), findsOneWidget);
    expect(find.text('最近播放'), findsOneWidget);
    expect(find.text('打开专辑'), findsOneWidget);
    expect(find.text('正在聆听'), findsNothing);
    expect(find.text('展开独立播放器'), findsNothing);
    final openAlbumAction = find.byKey(
      const ValueKey('home-open-album-action'),
    );
    final browseAlbumsAction = find.byKey(
      const ValueKey('home-browse-albums-action'),
    );
    expect(tester.getSize(openAlbumAction).height, 48);
    expect(tester.getSize(browseAlbumsAction).height, 48);
    expect(
      tester
          .getCenter(
            find.descendant(
              of: openAlbumAction,
              matching: find.byIcon(Icons.album_rounded),
            ),
          )
          .dy,
      closeTo(
        tester
            .getCenter(
              find.descendant(of: openAlbumAction, matching: find.text('打开专辑')),
            )
            .dy,
        0.1,
      ),
    );
    expect(
      tester
          .getCenter(
            find.descendant(
              of: browseAlbumsAction,
              matching: find.byIcon(Icons.arrow_forward_rounded),
            ),
          )
          .dy,
      closeTo(
        tester
            .getCenter(
              find.descendant(
                of: browseAlbumsAction,
                matching: find.text('浏览全部专辑'),
              ),
            )
            .dy,
        0.1,
      ),
    );
    expect(
      find.byKey(const ValueKey('home-current-track-track-1')),
      findsOneWidget,
    );
    expect(find.text('正在播放'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'discovery-home-1280x720-dark');
  });

  testWidgets('桌面最近播放卡片悬停仅强调封面和标题', (tester) async {
    final cubit = _TestHomeCubit();
    addTearDown(cubit.close);
    await _setViewport(tester, const ui.Size(1280, 720));
    await _pumpHome(
      tester,
      cubit,
      const HomeState(
        status: HomeStatus.success,
        recentlyPlayed: _tracks,
        albums: _albums,
      ),
    );

    final card = find
        .ancestor(
          of: find.text(_tracks.first.title),
          matching: find.byType(InkWell),
        )
        .first;
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(card));
    await tester.pumpAndSettle();

    final overlay = find.descendant(
      of: card,
      matching: find.byType(ArtworkHoverOverlay),
    );
    expect(tester.widget<ArtworkHoverOverlay>(overlay).visible, isTrue);
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
      findsOneWidget,
    );
    expect(tester.widget<InkWell>(card).hoverColor, Colors.transparent);
    await mouse.removePointer();
  });

  testWidgets('移动首页避免重复播放器并展示最近播放和唱片架', (tester) async {
    final cubit = _TestHomeCubit();
    addTearDown(cubit.close);
    await _setViewport(tester, const ui.Size(390, 844), textScale: 2);
    await _pumpHome(tester, cubit, _successState);
    expect(find.text('乐岛'), findsOneWidget);
    expect(find.text('属于你的音乐岛屿'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-continue-listening')), findsNothing);
    expect(find.text('最近播放'), findsOneWidget);
    expect(find.text('我的唱片架'), findsOneWidget);
    expect(find.text('为你发现'), findsNothing);
    expect(find.textContaining('用于验证超长标题'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首页五个固定视口无溢出并可生成截图', (tester) async {
    final cubit = _TestHomeCubit();
    addTearDown(cubit.close);
    for (final size in _viewports) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 1.3]) {
          await _setViewport(tester, size, textScale: scale);
          await _pumpHome(
            tester,
            cubit,
            _successState,
            capture: true,
            themeMode: mode,
          );
          expect(tester.takeException(), isNull, reason: '$size $mode $scale');
          final brightness = mode == ThemeMode.light ? 'light' : 'dark';
          await _capture(
            tester,
            'home-${size.width.toInt()}x${size.height.toInt()}-$brightness-scale-$scale',
          );
        }
      }
    }
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  _TestHomeCubit cubit,
  HomeState state, {
  bool capture = false,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  cubit.show(state);
  final resolver = CustomMediaSourceResolver();
  final settingsCubit = AppSettingsCubit(_SettingsRepository(), resolver);
  final playerCubit = _TestPlayerCubit(
    PlayerViewState(
      queue: state.recentlyPlayed,
      isPlaying: state.recentlyPlayed.isNotEmpty,
      duration: state.recentlyPlayed.firstOrNull?.duration ?? Duration.zero,
    ),
  );
  addTearDown(settingsCubit.close);
  addTearDown(playerCubit.close);
  await tester.pumpWidget(
    RepositoryProvider<CustomMediaSourceResolver>.value(
      value: resolver,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>.value(value: cubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          BlocProvider<PlayerCubit>.value(value: playerCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: RepaintBoundary(
            key: capture ? const ValueKey('home-capture') : null,
            child: const HomeView(),
          ),
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
  if (Platform.environment['CAPTURE_HOME_SCREENSHOTS'] != 'true') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('home-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Unable to encode home screenshot');
    final directory = Directory('design-reference/screenshots/actual');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });
}

class _TestHomeCubit extends HomeCubit {
  _TestHomeCubit()
    : super(
        FetchLatestAlbums(_Repository()),
        FetchRandomAlbums(_Repository()),
        _Repository(),
      );
  void show(HomeState state) => emit(state);
}

class _TestPlayerCubit extends Cubit<PlayerViewState> implements PlayerCubit {
  _TestPlayerCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements MusicRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SettingsRepository implements SettingsRepository {
  @override
  Future<AppSettingsSnapshot> load() async => const AppSettingsSnapshot();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _albums = [
  MusicAlbum(
    id: 'album-1',
    title: '用于验证超长标题在有限宽度内稳定省略且不发生横向溢出的最新专辑',
    artistName: '未知歌手',
    artworkUrl: '',
    trackCount: 12,
  ),
  MusicAlbum(
    id: 'album-2',
    title: '无封面专辑',
    artistName: '测试歌手',
    artworkUrl: '',
    trackCount: 8,
  ),
  MusicAlbum(
    id: 'album-3',
    title: '随机专辑',
    artistName: '测试歌手',
    artworkUrl: '',
    trackCount: 10,
  ),
];

const _tracks = [
  MusicTrack(
    id: 'track-1',
    title: '用于验证超长标题在排行榜中稳定省略且不发生横向溢出的歌曲',
    artistName: '未知歌手',
    albumTitle: '未知专辑',
    artworkUrl: '',
    duration: Duration(minutes: 4),
    playCount: 42,
  ),
  MusicTrack(
    id: 'track-2',
    title: '无封面歌曲',
    artistName: '测试歌手',
    albumTitle: '测试专辑',
    artworkUrl: '',
    duration: Duration(minutes: 3),
    playCount: 21,
  ),
];

const _successState = HomeState(
  status: HomeStatus.success,
  albums: _albums,
  randomPicks: _albums,
  recentlyPlayed: _tracks,
  mostPlayed: _tracks,
);
const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

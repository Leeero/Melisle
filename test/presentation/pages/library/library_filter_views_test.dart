import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:cross_platform_music_player/presentation/pages/library/library_filter_views.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_artist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  testWidgets('renders the songs view with long text and no artwork', (
    tester,
  ) async {
    const track = MusicTrack(
      id: 'track',
      title: '这是一首用于验证超长标题不会破坏媒体库布局的歌曲',
      artistName: '未知歌手',
      albumTitle: '未知专辑',
      artworkUrl: '',
      duration: Duration(minutes: 3),
    );
    await _pumpSliver(
      tester,
      LibraryTrackSliver(
        state: const LibraryState(
          status: LibraryStatus.success,
          tracks: [track],
          hasMore: false,
        ),
        horizontalPadding: 20,
        currentTrackId: null,
        onPlayAll: () {},
        onShuffleAll: () {},
        onTrackTap: (_) {},
        desktopTrailingBuilder: (_, _, _) => null,
        mobileItemBuilder: (_, item, _, _) => ListTile(
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${item.artistName} · ${item.albumTitle}'),
        ),
      ),
    );

    expect(find.text(track.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the compact albums view without overflow', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;

    await _pumpSliver(
      tester,
      LibraryAlbumSliver(
        state: const LibraryState(
          status: LibraryStatus.success,
          currentFilter: LibraryFilter.albums,
          albums: [
            MusicAlbum(
              id: 'album',
              title: '未知专辑',
              artistName: '未知歌手',
              artworkUrl: '',
              trackCount: 1,
            ),
          ],
          hasMore: false,
        ),
        horizontalPadding: 20,
      ),
      size: const Size(375, 812),
    );

    expect(find.text('未知专辑'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders desktop albums with long metadata without overflow', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;

    await _pumpSliver(
      tester,
      LibraryAlbumSliver(
        state: const LibraryState(
          status: LibraryStatus.success,
          currentFilter: LibraryFilter.albums,
          albums: [
            MusicAlbum(
              id: 'album',
              title: '用于验证桌面端专辑卡片高度不会发生渲染溢出的超长专辑名称',
              artistName: '用于验证元数据会安全截断的超长歌手名称',
              artworkUrl: '',
              trackCount: 100,
              year: 2026,
            ),
          ],
          hasMore: false,
        ),
        horizontalPadding: 48,
      ),
      size: const Size(1440, 900),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('album density changes the responsive desktop column count', (
    tester,
  ) async {
    final albums = List.generate(
      7,
      (index) => MusicAlbum(
        id: 'album-$index',
        title: '专辑 $index',
        artistName: '歌手 $index',
        artworkUrl: '',
        trackCount: 10,
      ),
    );
    final state = LibraryState(
      status: LibraryStatus.success,
      currentFilter: LibraryFilter.albums,
      albums: albums,
      hasMore: false,
    );

    await _pumpSliver(
      tester,
      LibraryAlbumSliver(state: state, horizontalPadding: 40),
      size: const Size(1200, 900),
    );
    final comfortableGrid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    expect(
      (comfortableGrid.gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      5,
    );

    await _pumpSliver(
      tester,
      LibraryAlbumSliver(
        state: state,
        horizontalPadding: 40,
        density: LibraryAlbumGridDensity.compact,
      ),
      size: const Size(1200, 900),
    );
    final compactGrid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    expect(
      (compactGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      6,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('album card opens from its text area', (tester) async {
    var tapCount = 0;
    await _pumpSliver(
      tester,
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 220,
            height: 290,
            child: MusicAlbumGridCard(
              album: const MusicAlbum(
                id: 'album',
                title: '整卡可点击专辑',
                artistName: '测试歌手',
                artworkUrl: '',
                trackCount: 8,
              ),
              onTap: () => tapCount++,
            ),
          ),
        ),
      ),
      size: const Size(375, 812),
    );

    await tester.tap(find.text('整卡可点击专辑'));
    await tester.pump();
    expect(tapCount, 1);
  });

  testWidgets('renders the compact artists view as rows', (tester) async {
    await _pumpSliver(
      tester,
      LibraryArtistSliver(
        state: const LibraryState(
          status: LibraryStatus.success,
          currentFilter: LibraryFilter.artists,
          artists: [
            MusicArtist(
              id: 'artist',
              name: '超长歌手名称用于验证内容边界',
              artworkUrl: '',
              albumCount: 12,
            ),
          ],
          hasMore: false,
        ),
        horizontalPadding: 20,
      ),
      size: const Size(390, 844),
    );

    expect(find.text('12 张专辑'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('renders the desktop artist directory as a compact avatar grid', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpSliver(
      tester,
      LibraryArtistSliver(
        state: const LibraryState(
          status: LibraryStatus.success,
          currentFilter: LibraryFilter.artists,
          artists: [
            MusicArtist(
              id: 'artist-1',
              name: '(1982) 郑绪岚',
              artworkUrl: '',
              albumCount: 0,
            ),
            MusicArtist(
              id: 'artist-2',
              name: '(1985) 徐小凤',
              artworkUrl: '',
              albumCount: 0,
            ),
            MusicArtist(
              id: 'artist-3',
              name: '(1986) 罗大佑',
              artworkUrl: '',
              albumCount: 0,
            ),
          ],
          hasMore: false,
        ),
        horizontalPadding: 40,
      ),
      size: const Size(1440, 900),
    );

    expect(find.text('#'), findsNothing);
    expect(find.text('(1982) 郑绪岚'), findsOneWidget);
    expect(find.text('暂无统计'), findsNWidgets(3));
    expect(find.byIcon(Icons.person_outline_rounded), findsNWidgets(3));
    final firstArtistCard = find.byType(MusicArtistGridCard).first;
    final hoverContainerFinder = find
        .descendant(
          of: firstArtistCard,
          matching: find.byType(AnimatedContainer),
        )
        .first;
    final hoverContainer = tester.widget<AnimatedContainer>(
      hoverContainerFinder,
    );
    final idleHoverColor = (hoverContainer.decoration! as BoxDecoration).color!;
    final hoverColor = Theme.of(tester.element(firstArtistCard)).hoverWash;
    expect(idleHoverColor.a, 0);
    expect(idleHoverColor.withValues(alpha: 1), hoverColor);
    expect(
      tester.getSize(hoverContainerFinder).height,
      lessThanOrEqualTo(libraryArtistGridMainAxisExtent),
    );
    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      6,
    );
    expect(
      tester
          .widgetList<CachedArtwork>(find.byType(CachedArtwork))
          .every((artwork) => artwork.size == 132),
      isTrue,
    );
    expect(find.bySemanticsLabel(RegExp(r'^打开歌手')), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('renders the playlists view', (tester) async {
    await _pumpSliver(
      tester,
      LibraryPlaylistSliver(
        state: const LibraryState(
          status: LibraryStatus.success,
          currentFilter: LibraryFilter.playlists,
          playlists: [
            MusicPlaylist(
              id: 'playlist',
              name: '我的播放列表',
              artworkUrl: '',
              trackCount: 8,
            ),
          ],
          hasMore: false,
        ),
        horizontalPadding: 20,
      ),
    );

    expect(find.text('我的播放列表'), findsOneWidget);
  });

  testWidgets('captures all required library viewports without overflow', (
    tester,
  ) async {
    for (final size in _viewports) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 1.3]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await _pumpSliver(
            tester,
            LibraryArtistSliver(
              state: const LibraryState(
                status: LibraryStatus.success,
                currentFilter: LibraryFilter.artists,
                artists: [
                  MusicArtist(
                    id: 'a',
                    name: 'Adele',
                    artworkUrl: '',
                    albumCount: 4,
                  ),
                  MusicArtist(
                    id: 'b',
                    name: '用于验证超长歌手名称不会发生横向溢出',
                    artworkUrl: '',
                    albumCount: 12,
                  ),
                ],
                hasMore: false,
              ),
              horizontalPadding: size.width < 768 ? 20 : 40,
            ),
            size: size,
            themeMode: mode,
            capture: true,
          );
          expect(tester.takeException(), isNull, reason: '$size $mode $scale');
          final brightness = mode == ThemeMode.light ? 'light' : 'dark';
          await _capture(
            tester,
            'library-${size.width.toInt()}x${size.height.toInt()}-'
            '$brightness-scale-$scale',
          );
        }
      }
    }
  });
}

Future<void> _pumpSliver(
  WidgetTester tester,
  Widget sliver, {
  Size size = const Size(1080, 900),
  ThemeMode themeMode = ThemeMode.light,
  bool capture = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final resolver = CustomMediaSourceResolver();
  final settingsCubit = AppSettingsCubit(_SettingsRepository(), resolver);
  addTearDown(settingsCubit.close);
  await tester.pumpWidget(
    RepositoryProvider<CustomMediaSourceResolver>.value(
      value: resolver,
      child: BlocProvider<AppSettingsCubit>.value(
        value: settingsCubit,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: RepaintBoundary(
            key: capture ? const ValueKey('library-capture') : null,
            child: Scaffold(body: CustomScrollView(slivers: [sliver])),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_LIBRARY_SCREENSHOTS'] != 'true') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('library-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Unable to encode library screenshot');
    final directory = Directory('design-reference/screenshots/actual');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });
}

class _SettingsRepository implements SettingsRepository {
  @override
  Future<AppSettingsSnapshot> load() async => const AppSettingsSnapshot();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

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
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/search/search_page.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_scope_tabs.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_artist_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SearchPage_initialEmptyState_showsSearchPrompt', (tester) async {
    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('搜索音乐库'), findsOneWidget);
    expect(find.text('热门发现'), findsNothing);
    expect(find.text('周杰伦'), findsNothing);
    expect(find.text('搜索分类'), findsNothing);
    expect(find.text('输入关键词探索音乐库'), findsNothing);
    expect(find.text('继续刚才的搜索'), findsNothing);
    expect(find.byType(AppContentPage), findsOneWidget);
  });

  testWidgets('SearchPage_emptyResults_showsHelpfulMessage', (tester) async {
    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository()),
    );

    await tester.enterText(find.byType(TextField), '不存在');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('没有找到结果，换个关键词试试。'), findsOneWidget);
  });

  testWidgets('SearchPage_results_useSingleV3SectionFlowWithoutScopeTabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository(results: _results())),
    );

    await tester.enterText(find.byType(TextField), '周杰伦');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(AppScopeTabs), findsNothing);
    expect(find.text('全部'), findsNothing);
    expect(find.text('最佳匹配'), findsOneWidget);
    expect(find.text('1 首'), findsWidgets);
    expect(find.text('夜曲'), findsOneWidget);
    expect(find.text('私人雷达'), findsOneWidget);
    expect(find.text('十一月的萧邦'), findsWidgets);
  });

  testWidgets('SearchPage_recentSearchChip_syncsInputAndSearches', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.touchSearchHistory('夜曲');
    final repository = _FakeMusicRepository(results: _results());

    await tester.pumpWidget(
      _buildSearchPage(repository: repository, database: database),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InputChip, '夜曲'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '夜曲');
    expect(repository.queries, contains('夜曲'));
  });

  testWidgets('SearchPage_clearButton_hasTooltipAndTouchTarget', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository()),
    );

    expect(find.byType(TextField), findsOneWidget);
    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.decoration?.hintText, '搜索歌曲、专辑、艺人');

    await tester.enterText(find.byType(TextField), '夜曲');
    await tester.pump();

    final clearButton = find.byTooltip('清空搜索');
    expect(clearButton, findsOneWidget);
    expect(tester.getSize(clearButton).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(clearButton).height, greaterThanOrEqualTo(44));
  });

  testWidgets('SearchPage_loadingState_keepsLightweightFeedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSearchPage(
        repository: _FakeMusicRepository(
          results: _results(),
          delay: const Duration(seconds: 1),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '周杰伦');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('正在搜索…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('SearchPage_failureState_showsRetryAction', (tester) async {
    final repository = _FakeMusicRepository(error: Exception('offline'));

    await tester.pumpWidget(_buildSearchPage(repository: repository));

    await tester.enterText(find.byType(TextField), '失败');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(repository.queries.length, 2);
  });

  testWidgets('SearchPage_wideWidth_usesAlbumAndArtistGridCards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository(results: _results())),
    );

    await tester.enterText(find.byType(TextField), '周杰伦');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(MusicAlbumGridCard), findsOneWidget);
    expect(find.text('十一月的萧邦'), findsWidgets);
    expect(find.byType(MusicArtistGridCard), findsOneWidget);
    expect(find.text('周杰伦'), findsWidgets);
    expect(find.text('夜曲'), findsOneWidget);
  });

  testWidgets('SearchPage_clearRecent_canUndo', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.touchSearchHistory('夜曲');

    await tester.pumpWidget(
      _buildSearchPage(
        repository: _FakeMusicRepository(results: _results()),
        database: database,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();

    expect(find.text('已清空最近搜索'), findsOneWidget);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();

    expect(find.text('夜曲'), findsOneWidget);
  });

  testWidgets('SearchPage_singleRecentDelete_removesOnlySelectedEntry', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.touchSearchHistory('夜曲');
    await database.touchSearchHistory('晴天');

    await tester.pumpWidget(
      _buildSearchPage(
        repository: _FakeMusicRepository(results: _results()),
        database: database,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('删除搜索历史：夜曲'));
    await tester.pumpAndSettle();

    expect(find.text('夜曲'), findsNothing);
    expect(find.text('晴天'), findsOneWidget);
  });

  testWidgets('SearchPage_mobileWidth_rendersResults', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository(results: _results())),
    );

    await tester.enterText(find.byType(TextField), '周杰伦');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(AppScopeTabs), findsNothing);
    expect(find.text('全部'), findsNothing);
    expect(find.text('最佳匹配'), findsOneWidget);
    expect(find.text('1 首'), findsOneWidget);
    expect(find.byTooltip('加入队列'), findsOneWidget);
    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.byType(MusicArtistGridCard), findsOneWidget);
    expect(find.byType(MusicAlbumGridCard), findsOneWidget);
  });

  testWidgets('SearchPage_mobileArtistGrid_fitsLongArtistNames', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildSearchPage(
        repository: _FakeMusicRepository(results: _longArtistResults()),
      ),
    );

    await tester.enterText(find.byType(TextField), '独立音乐');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.byType(MusicArtistGridCard), findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets('SearchPage_wideWidth_rendersResults', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository(results: _results())),
    );

    await tester.enterText(find.byType(TextField), '周杰伦');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(AppScopeTabs), findsNothing);
    expect(find.text('全部'), findsNothing);
    expect(find.text('最佳匹配'), findsOneWidget);
    expect(find.text('1 首'), findsWidgets);
    expect(find.text('播放全部'), findsNothing);
    expect(find.text('加入队列'), findsNothing);
    expect(find.byTooltip('加入队列'), findsOneWidget);
  });

  testWidgets('SearchPage_responsiveSmoke_hasNoLayoutExceptions', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [
      Size(375, 812),
      Size(390, 844),
      Size(768, 900),
      Size(1080, 900),
      Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        _buildSearchPage(repository: _FakeMusicRepository(results: _results())),
      );

      await tester.enterText(find.byType(TextField), '周杰伦');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AppContentPage), findsOneWidget);
      expect(find.byType(AppScopeTabs), findsNothing);
    }
  });

  testWidgets('SearchPage_albumGrid_hasNoOverflowAtRequiredTextScale', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [
      Size(390, 844),
      Size(768, 900),
      Size(1080, 900),
      Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(1.3)),
          child: _buildSearchPage(
            repository: _FakeMusicRepository(results: _results()),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '周杰伦');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$size at 1.3x');
    }
  });
}

Widget _buildSearchPage({
  required _FakeMusicRepository repository,
  AppDatabase? database,
}) {
  final mediaSourceResolver = CustomMediaSourceResolver();
  final settingsCubit = AppSettingsCubit(
    _FakeSettingsRepository(),
    mediaSourceResolver,
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<MusicRepository>.value(value: repository),
      RepositoryProvider<CustomMediaSourceResolver>.value(
        value: mediaSourceResolver,
      ),
      if (database != null)
        RepositoryProvider<AppDatabase>.value(value: database),
    ],
    child: BlocProvider<AppSettingsCubit>(
      create: (_) => settingsCubit,
      child: const MaterialApp(home: SearchPage()),
    ),
  );
}

SearchResults _results() {
  return SearchResults(
    tracks: [_track()],
    albums: [
      const MusicAlbum(
        id: 'album-1',
        title: '十一月的萧邦',
        artistName: '周杰伦',
        artworkUrl: '',
        trackCount: 12,
        year: 2005,
      ),
    ],
    artists: [
      const MusicArtist(
        id: 'artist-1',
        name: '周杰伦',
        artworkUrl: '',
        albumCount: 14,
        trackCount: 120,
      ),
    ],
    playlists: [
      const MusicPlaylist(
        id: 'playlist-1',
        name: '私人雷达',
        artworkUrl: '',
        trackCount: 30,
      ),
    ],
  );
}

SearchResults _longArtistResults() {
  return const SearchResults(
    artists: [
      MusicArtist(
        id: 'artist-long-1',
        name: '声音碎片收集者与漫长夏夜合奏团',
        artworkUrl: '',
        albumCount: 3,
        trackCount: 42,
      ),
      MusicArtist(
        id: 'artist-long-2',
        name: '北方海岸线独立音乐计划',
        artworkUrl: '',
        albumCount: 2,
        trackCount: 28,
      ),
      MusicArtist(
        id: 'artist-long-3',
        name: '雾岛黄昏唱片室',
        artworkUrl: '',
        albumCount: 1,
        trackCount: 16,
      ),
    ],
  );
}

MusicTrack _track() {
  return const MusicTrack(
    id: 'track-1',
    title: '夜曲',
    artistName: '周杰伦',
    albumTitle: '十一月的萧邦',
    artworkUrl: '',
    duration: Duration(minutes: 4),
  );
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

class _FakeMusicRepository implements MusicRepository {
  _FakeMusicRepository({
    this.results = SearchResults.empty,
    this.delay = Duration.zero,
    this.error,
  });

  final SearchResults results;
  final Duration delay;
  final Object? error;
  final queries = <String>[];

  @override
  Future<SearchResults> search(String query) async {
    queries.add(query);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final error = this.error;
    if (error != null) throw error;
    return results;
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => null;

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
}

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

    expect(find.text('输入关键词开始搜索'), findsOneWidget);
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

  testWidgets('SearchPage_results_defaultsToTracksAndShowsScopeTabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository(results: _results())),
    );

    await tester.enterText(find.byType(TextField), '周杰伦');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('歌曲 1'), findsOneWidget);
    expect(find.text('专辑 1'), findsOneWidget);
    expect(find.text('艺术家 1'), findsOneWidget);
    expect(find.text('歌单 1'), findsOneWidget);
    expect(find.text('全部 4'), findsNothing);
    expect(find.text('夜曲'), findsOneWidget);
    expect(find.text('私人雷达'), findsNothing);

    await tester.tap(find.text('歌单 1'));
    await tester.pumpAndSettle();

    expect(find.text('私人雷达'), findsOneWidget);
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

    await tester.tap(find.widgetWithText(ActionChip, '夜曲'));
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
    expect(find.text('搜索音乐库'), findsOneWidget);

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

  testWidgets('SearchPage_scopeFilter_showsSelectedResultType', (tester) async {
    await tester.pumpWidget(
      _buildSearchPage(repository: _FakeMusicRepository(results: _results())),
    );

    await tester.enterText(find.byType(TextField), '周杰伦');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('艺术家 1'));
    await tester.pumpAndSettle();

    expect(find.text('周杰伦'), findsWidgets);
    expect(find.byType(MusicArtistGridCard), findsOneWidget);
    expect(find.text('夜曲'), findsNothing);
    expect(find.text('十一月的萧邦'), findsNothing);
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

    await tester.tap(find.text('专辑 1'));
    await tester.pumpAndSettle();

    expect(find.byType(MusicAlbumGridCard), findsOneWidget);
    expect(find.text('十一月的萧邦'), findsOneWidget);
    expect(find.text('夜曲'), findsNothing);

    await tester.tap(find.text('艺术家 1'));
    await tester.pumpAndSettle();

    expect(find.byType(MusicArtistGridCard), findsOneWidget);
    expect(find.text('周杰伦'), findsWidgets);
    expect(find.text('十一月的萧邦'), findsNothing);
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

    expect(find.widgetWithText(ActionChip, '夜曲'), findsOneWidget);
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

    expect(find.text('歌曲'), findsOneWidget);
    expect(find.text('专辑 1'), findsOneWidget);
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

    expect(find.text('4 项'), findsOneWidget);
    expect(find.text('歌曲 1'), findsOneWidget);
    expect(find.text('全部 4'), findsNothing);
    expect(find.text('1 首'), findsOneWidget);
    expect(find.text('播放全部'), findsOneWidget);
    expect(find.text('加入队列'), findsOneWidget);
  });

  testWidgets('SearchPage_responsiveSmoke_hasNoLayoutExceptions', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [Size(390, 844), Size(1280, 900)]) {
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
      expect(find.text('歌曲 1'), findsOneWidget);
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

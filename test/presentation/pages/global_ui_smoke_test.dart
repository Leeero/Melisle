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
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/downloads/downloads_page.dart';
import 'package:cross_platform_music_player/presentation/pages/settings/settings_page.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/queue_sheet.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SettingsPage_responsiveSmoke_hasNoLayoutExceptions', (
    tester,
  ) async {
    final harness = await _SettingsHarness.create();
    addTearDown(harness.dispose);

    await _pumpForSizes(
      tester,
      build: () => harness.wrap(const SettingsPage()),
      verify: () {
        expect(find.byType(AppContentPage), findsOneWidget);
        expect(find.text('设置'), findsWidgets);
        expect(find.text('外观'), findsOneWidget);
        expect(find.text('播放'), findsOneWidget);
        expect(find.text('媒体来源'), findsOneWidget);
      },
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
      verify: () {
        expect(find.byType(AppContentPage), findsOneWidget);
        expect(find.text('下载管理'), findsWidgets);
        expect(find.text('还没有下载内容'), findsOneWidget);
      },
    );
  });

  testWidgets('QueueSheet_emptyState_keepsResponsiveSheetStructure', (
    tester,
  ) async {
    final harness = _QueueHarness.create();
    addTearDown(harness.dispose);

    await _pumpForSizes(
      tester,
      build: () => harness.wrap(const QueueSheet()),
      verify: () {
        expect(find.text('播放队列'), findsOneWidget);
        expect(find.text('0 首歌曲'), findsOneWidget);
        expect(find.text('当前播放队列为空'), findsOneWidget);
      },
    );
  });
}

Future<void> _pumpForSizes(
  WidgetTester tester, {
  required Widget Function() build,
  required VoidCallback verify,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  for (final size in const [Size(390, 844), Size(1280, 900)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(build());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 320));

    expect(tester.takeException(), isNull);
    verify();
  }
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
  _FakeQueuePlayerCubit() : super(const PlayerViewState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMusicRepository implements MusicRepository {
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

const _session = AuthSession(
  serverUrl: 'https://music.example.test',
  userId: 'user-1',
  userName: '测试用户',
  accessToken: 'token',
  backendType: MusicBackendType.navidrome,
);

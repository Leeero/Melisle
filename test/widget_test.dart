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
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/favorites/favorites_page.dart';
import 'package:cross_platform_music_player/presentation/pages/history/history_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login page when session is missing', (tester) async {
    final repository = _FakeMusicRepository();
    final settingsRepository = _FakeSettingsRepository();
    final mediaSourceResolver = CustomMediaSourceResolver();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final authCubit = AuthCubit(
      loginWithEmby: LoginWithEmby(repository),
      restoreSession: RestoreSession(repository),
      logout: Logout(repository),
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

    expect(find.text('连接你的音乐库'), findsOneWidget);
    expect(find.text('登录并进入乐岛'), findsOneWidget);
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

    expect(find.text('我的收藏'), findsWidgets);
    expect(find.text('还没有收藏歌曲，去媒体库挑几首喜欢的吧。'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
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

    expect(find.text('播放历史'), findsWidgets);
    expect(find.text('还没有播放历史，先放一首歌吧。'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}

class _FakeMusicRepository implements MusicRepository {
  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async => [];

  @override
  Future<List<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async => [];

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
  }) async => [];

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => [];

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async => [];

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(String playlistId) async => [];

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

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
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/dev_login_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthCubit', () {
    test('uses dev credentials when restore has no session', () async {
      final repository = _AuthRepositoryFake();
      final cubit = AuthCubit(
        loginWithEmby: LoginWithEmby(repository),
        restoreSession: RestoreSession(repository),
        logout: Logout(repository),
        fetchPlaylists: FetchPlaylists(repository),
        devLoginCredentials: const AuthDevLoginCredentials(
          serverUrl: 'https://music.example.test',
          username: 'dev-user',
          password: 'dev-token',
        ),
      );

      await expectLater(
        cubit.stream,
        emitsThrough(
          predicate<AuthState>(
            (state) =>
                state.status == AuthStatus.authenticated &&
                state.session?.normalizedServerUrl ==
                    'https://music.example.test' &&
                state.session?.userName == 'dev-user' &&
                state.session?.accessToken == 'dev-token',
          ),
        ),
      );

      expect(repository.loginCalls, 1);
      expect(repository.lastLoginServerUrl, 'https://music.example.test');
      expect(repository.lastLoginUsername, 'dev-user');
      expect(repository.lastLoginPassword, 'dev-token');
      expect(repository.fetchPlaylistsCalls, 1);
      expect(repository.lastPlaylistLimit, FetchPlaylists.defaultPageSize);

      await cubit.close();
    });
  });
}

class _AuthRepositoryFake implements MusicRepository {
  AuthSession? session;
  int loginCalls = 0;
  String? lastLoginServerUrl;
  String? lastLoginUsername;
  String? lastLoginPassword;
  int fetchPlaylistsCalls = 0;
  int? lastPlaylistLimit;

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    loginCalls += 1;
    lastLoginServerUrl = serverUrl;
    lastLoginUsername = username;
    lastLoginPassword = password;
    session = AuthSession(
      serverUrl: serverUrl,
      userId: username,
      userName: username,
      accessToken: password,
    );
    return session!;
  }

  @override
  Future<void> logout() async {
    session = null;
  }

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async => [];

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
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    fetchPlaylistsCalls += 1;
    lastPlaylistLimit = limit;
    return [];
  }

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
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) async => [];

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
  Future<List<Genre>> fetchGenres() async => [];

  @override
  Future<SearchResults> search(String query) async => SearchResults.empty;
}

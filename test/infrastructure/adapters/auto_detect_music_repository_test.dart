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
import 'package:cross_platform_music_player/infrastructure/adapters/auto_detect_music_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoDetectMusicRepository', () {
    test('login 优先使用 Navidrome，当 Subsonic 探测成功时不再回退 Emby', () async {
      final navidrome = _StubMusicRepository(
        loginSession: const AuthSession(
          serverUrl: 'https://music.example.com',
          userId: 'test-user-id',
          userName: 'test-user',
          accessToken: 'secret',
          backendType: MusicBackendType.navidrome,
        ),
      );
      final emby = _StubMusicRepository(
        loginSession: const AuthSession(
          serverUrl: 'https://emby.example.com',
          userId: 'user-1',
          userName: 'test-user',
          accessToken: 'emby-token',
          backendType: MusicBackendType.emby,
        ),
      );
      final repository = AutoDetectMusicRepository(
        embyRepository: emby,
        navidromeRepository: navidrome,
      );

      final session = await repository.login(
        serverUrl: 'https://music.example.com',
        username: 'test-user',
        password: 'secret',
      );

      expect(session.backendType, MusicBackendType.navidrome);
      expect(navidrome.loginCalls, 1);
      expect(emby.loginCalls, 0);
    });

    test('login 在 Navidrome 探测失败时回退到 Emby', () async {
      final navidrome = _StubMusicRepository(
        loginError: StateError('not navidrome'),
      );
      final emby = _StubMusicRepository(
        loginSession: const AuthSession(
          serverUrl: 'https://emby.example.com',
          userId: 'user-1',
          userName: 'test-user',
          accessToken: 'emby-token',
          backendType: MusicBackendType.emby,
        ),
      );
      final repository = AutoDetectMusicRepository(
        embyRepository: emby,
        navidromeRepository: navidrome,
      );

      final session = await repository.login(
        serverUrl: 'https://emby.example.com',
        username: 'test-user',
        password: 'password',
      );

      expect(session.backendType, MusicBackendType.emby);
      expect(navidrome.loginCalls, 1);
      expect(emby.loginCalls, 1);
    });

    test('restoreSession 按会话 backendType 选择正确后端', () async {
      final navidrome = _StubMusicRepository(
        restoreSessionValue: const AuthSession(
          serverUrl: 'https://music.example.com',
          userId: 'test-user-id',
          userName: 'test-user',
          accessToken: 'secret',
          backendType: MusicBackendType.navidrome,
        ),
        tracksToReturn: const [
          MusicTrack(
            id: 'track-nav',
            title: 'Navidrome Song',
            artistName: 'Artist',
            albumTitle: 'Album',
            artworkUrl: '',
            duration: Duration.zero,
          ),
        ],
      );
      final emby = _StubMusicRepository(
        restoreSessionValue: null,
        tracksToReturn: const [
          MusicTrack(
            id: 'track-emby',
            title: 'Emby Song',
            artistName: 'Artist',
            albumTitle: 'Album',
            artworkUrl: '',
            duration: Duration.zero,
          ),
        ],
      );
      final repository = AutoDetectMusicRepository(
        embyRepository: emby,
        navidromeRepository: navidrome,
      );

      final restored = await repository.restoreSession();
      final tracks = await repository.fetchTracks(limit: 1);

      expect(restored?.backendType, MusicBackendType.navidrome);
      expect(tracks.items.single.id, 'track-nav');
      expect(navidrome.fetchTracksCalls, 1);
      expect(emby.fetchTracksCalls, 0);
    });
  });
}

class _StubMusicRepository implements MusicRepository {
  _StubMusicRepository({
    this.loginSession,
    this.restoreSessionValue,
    this.loginError,
    this.tracksToReturn = const [],
  });

  final AuthSession? loginSession;
  final AuthSession? restoreSessionValue;
  final Object? loginError;
  final List<MusicTrack> tracksToReturn;

  int loginCalls = 0;
  int fetchTracksCalls = 0;

  @override
  Future<AuthSession?> restoreSession() async => restoreSessionValue;

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    loginCalls += 1;
    if (loginError != null) {
      throw loginError!;
    }
    return loginSession ??
        AuthSession(
          serverUrl: serverUrl,
          userId: username,
          userName: username,
          accessToken: password,
        );
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    fetchTracksCalls += 1;
    return PaginatedResult(items: tracksToReturn);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async =>
      const [];

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => const [];

  @override
  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) async => const [];

  @override
  Future<List<Genre>> fetchGenres() async => const [];

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => const [];

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async => const [];

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async => const [];

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
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) async =>
      const [];

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) async => const [];

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async => const [];

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) async => const [];

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async => const [];

  @override
  Future<SearchResults> search(String query) async => SearchResults.empty;
}

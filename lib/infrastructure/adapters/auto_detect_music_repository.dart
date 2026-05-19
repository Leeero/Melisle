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

class AutoDetectMusicRepository implements MusicRepository {
  AutoDetectMusicRepository({
    required MusicRepository embyRepository,
    required MusicRepository navidromeRepository,
  }) : _embyRepository = embyRepository,
       _navidromeRepository = navidromeRepository;

  final MusicRepository _embyRepository;
  final MusicRepository _navidromeRepository;

  MusicRepository? _activeRepository;

  @override
  Future<AuthSession?> restoreSession() async {
    final navidromeSession = await _navidromeRepository.restoreSession();
    if (navidromeSession != null) {
      _activeRepository = _navidromeRepository;
      return navidromeSession;
    }

    final embySession = await _embyRepository.restoreSession();
    if (embySession != null) {
      _activeRepository = _embyRepository;
      return embySession;
    }

    _activeRepository = null;
    return null;
  }

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    Object? navidromeError;
    try {
      final session = await _navidromeRepository.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _activeRepository = _navidromeRepository;
      return session;
    } catch (error) {
      navidromeError = error;
    }

    try {
      final session = await _embyRepository.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _activeRepository = _embyRepository;
      return session;
    } catch (embyError) {
      throw StateError(
        '未能识别服务器类型或登录失败。'
        'Navidrome 探测结果：$navidromeError；'
        'Emby 登录结果：$embyError',
      );
    }
  }

  @override
  Future<void> logout() async {
    _activeRepository = null;
    await Future.wait([
      _embyRepository.logout(),
      _navidromeRepository.logout(),
    ]);
  }

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async {
    return (await _requireActiveRepository()).fetchLatestAlbums(limit: limit);
  }

  @override
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) async {
    return (await _requireActiveRepository()).fetchRandomAlbums(limit: limit);
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    return (await _requireActiveRepository()).fetchTracks(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    return (await _requireActiveRepository()).fetchAlbums(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) async {
    return (await _requireActiveRepository()).fetchArtists(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
      genreId: genreId,
    );
  }

  @override
  Future<List<Genre>> fetchGenres() async {
    return (await _requireActiveRepository()).fetchGenres();
  }

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    return (await _requireActiveRepository()).fetchPlaylists(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async {
    return (await _requireActiveRepository()).fetchAlbumTracks(albumId);
  }

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async {
    return (await _requireActiveRepository()).fetchPlaylistTracks(
      playlistId,
      limit: limit,
      startIndex: startIndex,
    );
  }

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) async {
    return (await _requireActiveRepository()).getStreamUrl(
      trackId,
      quality: quality,
    );
  }

  @override
  Future<void> setFavorite(String itemId, bool value) async {
    await (await _requireActiveRepository()).setFavorite(itemId, value);
  }

  @override
  Future<List<LyricLine>?> fetchLyrics(String trackId) async {
    return (await _requireActiveRepository()).fetchLyrics(trackId);
  }

  @override
  Future<void> reportPlaybackStart(String trackId, String playSessionId) async {
    await (await _requireActiveRepository()).reportPlaybackStart(
      trackId,
      playSessionId,
    );
  }

  @override
  Future<void> reportPlaybackProgress(
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  }) async {
    await (await _requireActiveRepository()).reportPlaybackProgress(
      trackId,
      playSessionId,
      position,
      isPaused: isPaused,
    );
  }

  @override
  Future<void> reportPlaybackStopped(
    String trackId,
    String playSessionId,
    Duration position,
  ) async {
    await (await _requireActiveRepository()).reportPlaybackStopped(
      trackId,
      playSessionId,
      position,
    );
  }

  @override
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) async {
    return (await _requireActiveRepository()).fetchRecentlyPlayed(limit: limit);
  }

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) async {
    return (await _requireActiveRepository()).fetchMostPlayed(limit: limit);
  }

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async {
    return (await _requireActiveRepository()).fetchFavoriteTracks(
      limit: limit,
      startIndex: startIndex,
    );
  }

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) async {
    return (await _requireActiveRepository()).fetchArtistAlbums(artistId);
  }

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async {
    return (await _requireActiveRepository()).fetchArtistTopTracks(
      artistId,
      limit: limit,
    );
  }

  @override
  Future<SearchResults> search(String query) async {
    return (await _requireActiveRepository()).search(query);
  }

  Future<MusicRepository> _requireActiveRepository() async {
    final current = _activeRepository;
    if (current != null) {
      return current;
    }

    final restored = await restoreSession();
    if (restored != null && _activeRepository != null) {
      return _activeRepository!;
    }

    throw StateError('当前没有可用的登录会话，请先登录。');
  }
}

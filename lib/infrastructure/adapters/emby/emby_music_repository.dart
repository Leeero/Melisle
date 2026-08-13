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
import 'package:cross_platform_music_player/domain/entities/track_sort_option.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/infrastructure/network/emby_api_client.dart';
import 'package:cross_platform_music_player/infrastructure/persistence/auth_session_store.dart';

class EmbyMusicRepository implements MusicRepository, TrackSortingRepository {
  EmbyMusicRepository({
    required EmbyApiClient client,
    required AuthSessionStore sessionStore,
    required CustomMediaSourceResolver mediaSourceResolver,
  }) : _client = client,
       _sessionStore = sessionStore,
       _mediaSourceResolver = mediaSourceResolver;

  final EmbyApiClient _client;
  final AuthSessionStore _sessionStore;
  final CustomMediaSourceResolver _mediaSourceResolver;

  AuthSession? _cachedSession;

  @override
  Future<AuthSession?> restoreSession() async {
    if (_cachedSession != null) {
      return _cachedSession!.backendType == MusicBackendType.emby
          ? _cachedSession
          : null;
    }

    final session = await _sessionStore.read();
    if (session == null || session.backendType != MusicBackendType.emby) {
      return null;
    }

    _cachedSession = session;
    return session;
  }

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final session = await _client.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    await _sessionStore.save(session);
    _cachedSession = session;
    return session;
  }

  @override
  Future<void> logout() async {
    _cachedSession = null;
    await _sessionStore.clear();
  }

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async {
    return _client.fetchLatestAlbums(await _requireSession(), limit: limit);
  }

  @override
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) async {
    return _client.fetchRandomAlbums(await _requireSession(), limit: limit);
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final result = await _client.fetchTracks(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
    return PaginatedResult(items: result.tracks, totalCount: result.totalCount);
  }

  @override
  Future<Set<TrackSortOption>> fetchSupportedTrackSortOptions() async => const {
    TrackSortOption.title,
    TrackSortOption.artist,
    TrackSortOption.album,
    TrackSortOption.dateAdded,
  };

  @override
  Future<PaginatedResult<MusicTrack>> fetchSortedTracks({
    required TrackSortOption sortOption,
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final result = await _client.fetchTracks(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
      sortOption: sortOption,
    );
    return PaginatedResult(items: result.tracks, totalCount: result.totalCount);
  }

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    return _client.fetchAlbums(
      await _requireSession(),
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
    return _client.fetchArtists(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
      genreId: genreId,
    );
  }

  @override
  Future<List<Genre>> fetchGenres() async {
    return _client.fetchGenres(await _requireSession());
  }

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    return _client.fetchPlaylists(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async {
    return _client.fetchAlbumTracks(await _requireSession(), albumId);
  }

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async {
    return _client.fetchPlaylistTracks(
      await _requireSession(),
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
    final session = await _requireSession();
    if (quality == AudioQuality.auto) {
      return _client.buildStreamUrl(session, trackId);
    }
    return _client.buildUniversalAudioUrl(session, trackId, quality);
  }

  @override
  Future<void> setFavorite(String itemId, bool value) async {
    await _client.setFavorite(await _requireSession(), itemId, value);
  }

  @override
  Future<List<LyricLine>?> fetchLyrics(String trackId) async {
    final session = await _requireSession();
    final detail = await _client.fetchItemDetail(session, trackId);
    return _mediaSourceResolver.fetchLyrics(
      trackId: trackId,
      title: detail?['Name'] as String?,
      artistName: _resolveArtistName(detail),
      albumTitle: detail?['Album'] as String?,
      fallback: () =>
          _client.fetchLyricsFromItemDetail(session, trackId, detail),
    );
  }

  @override
  Future<void> reportPlaybackStart(String trackId, String playSessionId) async {
    await _client.reportPlaybackStart(
      await _requireSession(),
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
    await _client.reportPlaybackProgress(
      await _requireSession(),
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
    await _client.reportPlaybackStopped(
      await _requireSession(),
      trackId,
      playSessionId,
      position,
    );
  }

  @override
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) async {
    return _client.fetchRecentlyPlayed(await _requireSession(), limit: limit);
  }

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) async {
    return _client.fetchMostPlayed(await _requireSession(), limit: limit);
  }

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async {
    return _client.fetchFavoriteTracks(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
    );
  }

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) async {
    return _client.fetchArtistAlbums(await _requireSession(), artistId);
  }

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async {
    return _client.fetchArtistTopTracks(
      await _requireSession(),
      artistId,
      limit: limit,
    );
  }

  @override
  Future<SearchResults> search(String query) async {
    return _client.searchAll(await _requireSession(), query);
  }

  String? _resolveArtistName(Map<String, dynamic>? item) {
    if (item == null) return null;

    final albumArtist = item['AlbumArtist'] as String?;
    if (albumArtist != null && albumArtist.trim().isNotEmpty) {
      return albumArtist;
    }

    final albumArtists = item['AlbumArtists'];
    if (albumArtists is List && albumArtists.isNotEmpty) {
      final first = albumArtists.first;
      if (first is Map<String, dynamic>) {
        final name = first['Name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          return name;
        }
      }
    }

    final artistItems = item['ArtistItems'];
    if (artistItems is List && artistItems.isNotEmpty) {
      final first = artistItems.first;
      if (first is Map<String, dynamic>) {
        final name = first['Name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          return name;
        }
      }
    }

    return null;
  }

  Future<AuthSession> _requireSession() async {
    final session = await restoreSession();

    if (session == null) {
      throw StateError('当前没有可用的 Emby 会话，请先登录。');
    }

    return session;
  }
}

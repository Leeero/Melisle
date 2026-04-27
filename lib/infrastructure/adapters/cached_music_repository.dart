import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class CachedMusicRepository implements MusicRepository {
  CachedMusicRepository({
    required MusicRepository delegate,
    MusicRepositoryCachePolicy policy = const MusicRepositoryCachePolicy(),
    DateTime Function()? now,
  }) : _delegate = delegate,
       _policy = policy,
       _now = now ?? DateTime.now;

  final MusicRepository _delegate;
  final MusicRepositoryCachePolicy _policy;
  final DateTime Function() _now;

  final Map<String, _CacheEntry<Object?>> _memoryCache = {};
  final Map<String, Future<Object?>> _inFlightRequests = {};

  String _sessionScopeKey = 'anonymous';

  @override
  Future<AuthSession?> restoreSession() async {
    final session = await _delegate.restoreSession();
    _syncSessionScope(session);
    return session;
  }

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final session = await _delegate.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    _syncSessionScope(session);
    return session;
  }

  @override
  Future<void> logout() async {
    await _delegate.logout();
    _sessionScopeKey = 'anonymous';
    _clearCache();
  }

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) {
    return _cached(
      'latestAlbums',
      ttl: _policy.homeFeedTtl,
      params: {'limit': limit},
      loader: () => _delegate.fetchLatestAlbums(limit: limit),
    );
  }

  @override
  Future<List<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _cached(
      'tracks',
      ttl: _policy.listTtl,
      params: {
        'limit': limit,
        'startIndex': startIndex,
        'searchQuery': searchQuery,
      },
      loader: () => _delegate.fetchTracks(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      ),
    );
  }

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _cached(
      'albums',
      ttl: _policy.listTtl,
      params: {
        'limit': limit,
        'startIndex': startIndex,
        'searchQuery': searchQuery,
      },
      loader: () => _delegate.fetchAlbums(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      ),
    );
  }

  @override
  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _cached(
      'artists',
      ttl: _policy.listTtl,
      params: {
        'limit': limit,
        'startIndex': startIndex,
        'searchQuery': searchQuery,
      },
      loader: () => _delegate.fetchArtists(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      ),
    );
  }

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _cached(
      'playlists',
      ttl: _policy.listTtl,
      params: {
        'limit': limit,
        'startIndex': startIndex,
        'searchQuery': searchQuery,
      },
      loader: () => _delegate.fetchPlaylists(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      ),
    );
  }

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) {
    return _cached(
      'albumTracks',
      ttl: _policy.detailTtl,
      params: {'albumId': albumId},
      loader: () => _delegate.fetchAlbumTracks(albumId),
    );
  }

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(String playlistId) {
    return _cached(
      'playlistTracks',
      ttl: _policy.detailTtl,
      params: {'playlistId': playlistId},
      loader: () => _delegate.fetchPlaylistTracks(playlistId),
    );
  }

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) {
    return _delegate.getStreamUrl(trackId, quality: quality);
  }

  @override
  Future<void> setFavorite(String itemId, bool value) async {
    await _delegate.setFavorite(itemId, value);
    _clearCache();
  }

  @override
  Future<List<LyricLine>?> fetchLyrics(String trackId) {
    return _delegate.fetchLyrics(trackId);
  }

  @override
  Future<void> reportPlaybackStart(String trackId, String playSessionId) {
    return _delegate.reportPlaybackStart(trackId, playSessionId);
  }

  @override
  Future<void> reportPlaybackProgress(
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  }) {
    return _delegate.reportPlaybackProgress(
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
  ) {
    return _delegate.reportPlaybackStopped(trackId, playSessionId, position);
  }

  @override
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) {
    return _cached(
      'recentlyPlayed',
      ttl: _policy.homeFeedTtl,
      params: {'limit': limit},
      loader: () => _delegate.fetchRecentlyPlayed(limit: limit),
    );
  }

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) {
    return _cached(
      'mostPlayed',
      ttl: _policy.homeFeedTtl,
      params: {'limit': limit},
      loader: () => _delegate.fetchMostPlayed(limit: limit),
    );
  }

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) {
    return _cached(
      'favoriteTracks',
      ttl: _policy.listTtl,
      params: {'limit': limit, 'startIndex': startIndex},
      loader: () =>
          _delegate.fetchFavoriteTracks(limit: limit, startIndex: startIndex),
    );
  }

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) {
    return _cached(
      'artistAlbums',
      ttl: _policy.detailTtl,
      params: {'artistId': artistId},
      loader: () => _delegate.fetchArtistAlbums(artistId),
    );
  }

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) {
    return _cached(
      'artistTopTracks',
      ttl: _policy.detailTtl,
      params: {'artistId': artistId, 'limit': limit},
      loader: () => _delegate.fetchArtistTopTracks(artistId, limit: limit),
    );
  }

  @override
  Future<SearchResults> search(String query) {
    return _cached(
      'search',
      ttl: _policy.searchTtl,
      params: {'query': query.trim()},
      loader: () => _delegate.search(query),
    );
  }

  Future<T> _cached<T>(
    String name, {
    required Duration ttl,
    required Map<String, Object?> params,
    required Future<T> Function() loader,
  }) async {
    final key = _buildCacheKey(name, params);
    final currentTime = _now();
    final cached = _memoryCache[key];
    if (cached != null && cached.expiresAt.isAfter(currentTime)) {
      return cached.value as T;
    }

    final inFlight = _inFlightRequests[key];
    if (inFlight != null) {
      return await inFlight as T;
    }

    final future = loader().then<Object?>(
      (value) {
        _memoryCache[key] = _CacheEntry(
          value: value,
          expiresAt: _now().add(ttl),
        );
        _inFlightRequests.remove(key);
        return value;
      },
      onError: (Object error, StackTrace stackTrace) {
        _inFlightRequests.remove(key);
        if (cached != null) {
          return cached.value;
        }
        throw error;
      },
    );

    _inFlightRequests[key] = future;
    return await future as T;
  }

  void _syncSessionScope(AuthSession? session) {
    final nextScope = session == null
        ? 'anonymous'
        : '${session.normalizedServerUrl}|${session.userId}';
    if (nextScope == _sessionScopeKey) {
      return;
    }
    _sessionScopeKey = nextScope;
    _clearCache();
  }

  String _buildCacheKey(String name, Map<String, Object?> params) {
    final buffer = StringBuffer()
      ..write(_sessionScopeKey)
      ..write('|')
      ..write(name);

    for (final entry in params.entries) {
      buffer
        ..write('|')
        ..write(entry.key)
        ..write('=')
        ..write(Uri.encodeQueryComponent('${entry.value ?? ''}'));
    }

    return buffer.toString();
  }

  void _clearCache() {
    _memoryCache.clear();
    _inFlightRequests.clear();
  }
}

class MusicRepositoryCachePolicy {
  const MusicRepositoryCachePolicy({
    this.listTtl = const Duration(seconds: 45),
    this.detailTtl = const Duration(minutes: 3),
    this.searchTtl = const Duration(seconds: 20),
    this.homeFeedTtl = const Duration(minutes: 2),
  });

  final Duration listTtl;
  final Duration detailTtl;
  final Duration searchTtl;
  final Duration homeFeedTtl;
}

class _CacheEntry<T> {
  const _CacheEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;
}

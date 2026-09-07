import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/artist_sort_option.dart';
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
import 'package:cross_platform_music_player/domain/entities/track_filter_option.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class CachedMusicRepository
    implements
        MusicRepository,
        TrackSortingRepository,
        TrackFilteringRepository,
        ArtistSortingRepository,
        PlaylistFavoritesRepository,
        BackendSelectableLoginRepository {
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

  final LinkedHashMap<String, _CacheEntry<Object?>> _memoryCache =
      LinkedHashMap();
  final Map<String, Future<Object?>> _inFlightRequests = {};

  String _sessionScopeKey = 'anonymous';
  int _cacheEpoch = 0;

  /// Clears only temporary in-memory responses. Downloaded audio is managed
  /// separately and is intentionally retained.
  Future<void> clearTemporaryCache() async {
    _clearCache();
  }

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
  Future<AuthSession> loginWithBackend({
    required String serverUrl,
    required String username,
    required String password,
    required MusicBackendType backendType,
  }) async {
    final delegate = _delegate;
    if (delegate is! BackendSelectableLoginRepository) {
      throw UnsupportedError('当前音乐仓库不支持手动指定服务类型。');
    }
    final session = await (delegate as BackendSelectableLoginRepository)
        .loginWithBackend(
          serverUrl: serverUrl,
          username: username,
          password: password,
          backendType: backendType,
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
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) {
    return _cached(
      'randomAlbums',
      ttl: _policy.homeFeedTtl,
      params: {'limit': limit},
      loader: () => _delegate.fetchRandomAlbums(limit: limit),
    );
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _cached<PaginatedResult<MusicTrack>>(
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
  Future<Set<TrackSortOption>> fetchSupportedTrackSortOptions() {
    final delegate = _delegate;
    return delegate is TrackSortingRepository
        ? (delegate as TrackSortingRepository).fetchSupportedTrackSortOptions()
        : Future.value(const {});
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchSortedTracks({
    required TrackSortOption sortOption,
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    final delegate = _delegate;
    if (delegate is! TrackSortingRepository) {
      return fetchTracks(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      );
    }
    return _cached(
      'sortedTracks',
      ttl: _policy.listTtl,
      params: {
        'sortOption': sortOption.name,
        'limit': limit,
        'startIndex': startIndex,
        'searchQuery': searchQuery,
      },
      loader: () => (delegate as TrackSortingRepository).fetchSortedTracks(
        sortOption: sortOption,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      ),
    );
  }

  @override
  Future<Set<TrackFilterOption>> fetchSupportedTrackFilterOptions() {
    final delegate = _delegate;
    return delegate is TrackFilteringRepository
        ? (delegate as TrackFilteringRepository)
              .fetchSupportedTrackFilterOptions()
        : Future.value(const {});
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchFilteredTracks({
    required Set<TrackFilterOption> filters,
    TrackSortOption? sortOption,
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    final delegate = _delegate;
    if (delegate is! TrackFilteringRepository) {
      return fetchTracks(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      );
    }
    return _cached(
      'filteredTracks',
      ttl: _policy.listTtl,
      params: {
        'filters': filters.map((filter) => filter.name).toList()..sort(),
        'sortOption': sortOption?.name,
        'limit': limit,
        'startIndex': startIndex,
        'searchQuery': searchQuery,
      },
      loader: () => (delegate as TrackFilteringRepository).fetchFilteredTracks(
        filters: filters,
        sortOption: sortOption,
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
    String? genreId,
  }) {
    return _cached(
      'artists',
      ttl: _policy.listTtl,
      params: {
        'limit': limit,
        'startIndex': startIndex,
        'searchQuery': searchQuery,
        'genreId': genreId,
      },
      loader: () => _delegate.fetchArtists(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
        genreId: genreId,
      ),
    );
  }

  @override
  Future<Set<ArtistSortOption>> fetchSupportedArtistSortOptions() {
    final delegate = _delegate;
    return delegate is ArtistSortingRepository
        ? (delegate as ArtistSortingRepository)
              .fetchSupportedArtistSortOptions()
        : Future.value(const {});
  }

  @override
  Future<List<MusicArtist>> fetchSortedArtists({
    required ArtistSortOption sortOption,
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) {
    final delegate = _delegate;
    if (delegate is! ArtistSortingRepository) {
      return fetchArtists(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
        genreId: genreId,
      );
    }
    final sortingDelegate = delegate as ArtistSortingRepository;
    return _cached(
      'sortedArtists',
      ttl: _policy.listTtl,
      params: {
        'sortOption': sortOption.name,
        'limit': limit,
        'startIndex': startIndex,
        'searchQuery': searchQuery,
        'genreId': genreId,
      },
      loader: () => sortingDelegate.fetchSortedArtists(
        sortOption: sortOption,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
        genreId: genreId,
      ),
    );
  }

  @override
  Future<List<Genre>> fetchGenres() {
    return _cached(
      'genres',
      ttl: _policy.listTtl,
      params: const <String, Object?>{},
      loader: () => _delegate.fetchGenres(),
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
  Future<bool> supportsPlaylistFavorites() {
    final delegate = _delegate;
    if (delegate is! PlaylistFavoritesRepository) return Future.value(false);
    final playlistFavoritesDelegate = delegate as PlaylistFavoritesRepository;
    return playlistFavoritesDelegate.supportsPlaylistFavorites();
  }

  @override
  Future<List<MusicPlaylist>> fetchFavoritePlaylists({
    int limit = 60,
    int startIndex = 0,
  }) {
    final delegate = _delegate;
    if (delegate is! PlaylistFavoritesRepository) {
      return Future.error(UnsupportedError('当前服务器不支持收藏歌单。'));
    }
    final playlistFavoritesDelegate = delegate as PlaylistFavoritesRepository;
    return _cached(
      'favoritePlaylists',
      ttl: _policy.listTtl,
      params: {'limit': limit, 'startIndex': startIndex},
      loader: () => playlistFavoritesDelegate.fetchFavoritePlaylists(
        limit: limit,
        startIndex: startIndex,
      ),
    );
  }

  @override
  Future<void> setPlaylistFavorite(String playlistId, bool value) async {
    final delegate = _delegate;
    if (delegate is! PlaylistFavoritesRepository) {
      throw UnsupportedError('当前服务器不支持收藏歌单。');
    }
    final playlistFavoritesDelegate = delegate as PlaylistFavoritesRepository;
    await playlistFavoritesDelegate.setPlaylistFavorite(playlistId, value);
    _clearCache();
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
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) {
    return _cached(
      'playlistTracks',
      ttl: _policy.detailTtl,
      params: {
        'playlistId': playlistId,
        'limit': limit,
        'startIndex': startIndex,
      },
      loader: () => _delegate.fetchPlaylistTracks(
        playlistId,
        limit: limit,
        startIndex: startIndex,
      ),
    );
  }

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) {
    return _cached(
      'streamUrl',
      ttl: _policy.streamUrlTtl,
      params: {'trackId': trackId, 'quality': quality.storageKey},
      loader: () => _delegate.getStreamUrl(trackId, quality: quality),
    );
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
      _touchCacheEntry(key, cached);
      return cached.value as T;
    }

    final inFlight = _inFlightRequests[key];
    if (inFlight != null) {
      return await inFlight as T;
    }

    final future = _loadWithRetry(key, loader, cached, ttl, _cacheEpoch);
    _inFlightRequests[key] = future;

    try {
      final result = await future;
      return result as T;
    } finally {
      _inFlightRequests.remove(key);
    }
  }

  Future<Object?> _loadWithRetry<T>(
    String key,
    Future<T> Function() loader,
    _CacheEntry<Object?>? cached,
    Duration ttl,
    int epoch,
  ) async {
    const maxRetries = 1;
    Object? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final value = await loader();
        if (epoch == _cacheEpoch) {
          _storeCacheEntry(key, value, ttl);
        }
        return value;
      } catch (e) {
        lastError = e;
        if (attempt < maxRetries && _isRetryableTimeout(e)) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        } else {
          break;
        }
      }
    }

    if (cached != null) return cached.value;
    throw lastError!;
  }

  bool _isRetryableTimeout(Object error) {
    if (error is! DioException) return false;
    final type = error.type;
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout;
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
    _cacheEpoch += 1;
    _memoryCache.clear();
    _inFlightRequests.clear();
  }

  void _storeCacheEntry(String key, Object? value, Duration ttl) {
    if (ttl <= Duration.zero || _policy.maxMemoryEntries <= 0) {
      _memoryCache.remove(key);
      return;
    }

    _memoryCache.remove(key);
    _memoryCache[key] = _CacheEntry(value: value, expiresAt: _now().add(ttl));
    _trimMemoryCache();
  }

  void _touchCacheEntry(String key, _CacheEntry<Object?> entry) {
    _memoryCache.remove(key);
    _memoryCache[key] = entry;
  }

  void _trimMemoryCache() {
    while (_memoryCache.length > _policy.maxMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }
}

class MusicRepositoryCachePolicy {
  const MusicRepositoryCachePolicy({
    this.listTtl = const Duration(minutes: 5),
    this.detailTtl = const Duration(minutes: 10),
    this.searchTtl = const Duration(seconds: 20),
    this.homeFeedTtl = const Duration(minutes: 2),
    this.fullListTtl = const Duration(minutes: 5),
    this.streamUrlTtl = const Duration(seconds: 90),
    this.maxMemoryEntries = 240,
  });

  final Duration listTtl;
  final Duration detailTtl;
  final Duration searchTtl;
  final Duration homeFeedTtl;
  final Duration fullListTtl;
  final Duration streamUrlTtl;
  final int maxMemoryEntries;
}

class _CacheEntry<T> {
  const _CacheEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;
}

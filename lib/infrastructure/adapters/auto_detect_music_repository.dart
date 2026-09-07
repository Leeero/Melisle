import 'dart:developer' as developer;

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/artist_sort_option.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/login_failure.dart';
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
import 'package:dio/dio.dart';

class AutoDetectMusicRepository
    implements
        MusicRepository,
        TrackSortingRepository,
        TrackFilteringRepository,
        ArtistSortingRepository,
        PlaylistFavoritesRepository,
        BackendSelectableLoginRepository {
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
    LoginFailure? navidromeFailure;
    try {
      final session = await _navidromeRepository.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _activeRepository = _navidromeRepository;
      return session;
    } catch (error, stackTrace) {
      _logLoginFailure('Navidrome', error, stackTrace);
      navidromeFailure = _classifyLoginFailure(error);
    }

    try {
      final session = await _embyRepository.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _activeRepository = _embyRepository;
      return session;
    } catch (error, stackTrace) {
      _logLoginFailure('Emby', error, stackTrace);
      throw _combineLoginFailures(
        navidromeFailure,
        _classifyLoginFailure(error),
      );
    }
  }

  @override
  Future<AuthSession> loginWithBackend({
    required String serverUrl,
    required String username,
    required String password,
    required MusicBackendType backendType,
  }) async {
    final repository = switch (backendType) {
      MusicBackendType.emby => _embyRepository,
      MusicBackendType.navidrome => _navidromeRepository,
    };
    try {
      final session = await repository.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _activeRepository = repository;
      return session;
    } catch (error, stackTrace) {
      _logLoginFailure(backendType.name, error, stackTrace);
      throw _classifyLoginFailure(error);
    }
  }

  LoginFailure _classifyLoginFailure(Object error) {
    if (error is LoginFailure) return error;

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const LoginFailure(LoginFailureReason.invalidCredentials);
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
        case DioExceptionType.badCertificate:
          return const LoginFailure(LoginFailureReason.serverUnreachable);
        case DioExceptionType.badResponse:
          return const LoginFailure(LoginFailureReason.unsupportedServer);
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
          return const LoginFailure(LoginFailureReason.unknown);
      }
    }

    if (error is FormatException) {
      return const LoginFailure(LoginFailureReason.unsupportedServer);
    }

    return const LoginFailure(LoginFailureReason.unknown);
  }

  LoginFailure _combineLoginFailures(
    LoginFailure navidromeFailure,
    LoginFailure embyFailure,
  ) {
    final reasons = {navidromeFailure.reason, embyFailure.reason};
    if (reasons.contains(LoginFailureReason.invalidCredentials)) {
      return const LoginFailure(LoginFailureReason.invalidCredentials);
    }
    if (reasons.length == 1 &&
        reasons.single == LoginFailureReason.serverUnreachable) {
      return const LoginFailure(LoginFailureReason.serverUnreachable);
    }
    if (reasons.length == 1 && reasons.single == LoginFailureReason.unknown) {
      return const LoginFailure(LoginFailureReason.unknown);
    }
    return const LoginFailure(LoginFailureReason.unsupportedServer);
  }

  void _logLoginFailure(String backend, Object error, StackTrace stackTrace) {
    developer.log(
      '$backend login failed',
      name: 'AutoDetectMusicRepository',
      error: error,
      stackTrace: stackTrace,
    );
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
  Future<Set<TrackSortOption>> fetchSupportedTrackSortOptions() async {
    final repository = await _requireActiveRepository();
    return repository is TrackSortingRepository
        ? (repository as TrackSortingRepository)
              .fetchSupportedTrackSortOptions()
        : const {};
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchSortedTracks({
    required TrackSortOption sortOption,
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final repository = await _requireActiveRepository();
    if (repository is TrackSortingRepository) {
      return (repository as TrackSortingRepository).fetchSortedTracks(
        sortOption: sortOption,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      );
    }
    return repository.fetchTracks(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<Set<TrackFilterOption>> fetchSupportedTrackFilterOptions() async {
    final repository = await _requireActiveRepository();
    return repository is TrackFilteringRepository
        ? (repository as TrackFilteringRepository)
              .fetchSupportedTrackFilterOptions()
        : const {};
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchFilteredTracks({
    required Set<TrackFilterOption> filters,
    TrackSortOption? sortOption,
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final repository = await _requireActiveRepository();
    if (repository is TrackFilteringRepository) {
      return (repository as TrackFilteringRepository).fetchFilteredTracks(
        filters: filters,
        sortOption: sortOption,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      );
    }
    return repository.fetchTracks(
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
  Future<Set<ArtistSortOption>> fetchSupportedArtistSortOptions() async {
    final repository = await _requireActiveRepository();
    return repository is ArtistSortingRepository
        ? (repository as ArtistSortingRepository)
              .fetchSupportedArtistSortOptions()
        : const {};
  }

  @override
  Future<List<MusicArtist>> fetchSortedArtists({
    required ArtistSortOption sortOption,
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) async {
    final repository = await _requireActiveRepository();
    if (repository is ArtistSortingRepository) {
      final sortingRepository = repository as ArtistSortingRepository;
      return sortingRepository.fetchSortedArtists(
        sortOption: sortOption,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
        genreId: genreId,
      );
    }
    return repository.fetchArtists(
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
  Future<bool> supportsPlaylistFavorites() async {
    final repository = await _requireActiveRepository();
    if (repository is! PlaylistFavoritesRepository) return false;
    final playlistFavoritesRepository =
        repository as PlaylistFavoritesRepository;
    return playlistFavoritesRepository.supportsPlaylistFavorites();
  }

  @override
  Future<List<MusicPlaylist>> fetchFavoritePlaylists({
    int limit = 60,
    int startIndex = 0,
  }) async {
    final repository = await _requireActiveRepository();
    if (repository is! PlaylistFavoritesRepository) {
      throw UnsupportedError('当前服务器不支持收藏歌单。');
    }
    final playlistFavoritesRepository =
        repository as PlaylistFavoritesRepository;
    if (!await playlistFavoritesRepository.supportsPlaylistFavorites()) {
      throw UnsupportedError('当前服务器不支持收藏歌单。');
    }
    return playlistFavoritesRepository.fetchFavoritePlaylists(
      limit: limit,
      startIndex: startIndex,
    );
  }

  @override
  Future<void> setPlaylistFavorite(String playlistId, bool value) async {
    final repository = await _requireActiveRepository();
    if (repository is! PlaylistFavoritesRepository) {
      throw UnsupportedError('当前服务器不支持收藏歌单。');
    }
    final playlistFavoritesRepository =
        repository as PlaylistFavoritesRepository;
    if (!await playlistFavoritesRepository.supportsPlaylistFavorites()) {
      throw UnsupportedError('当前服务器不支持收藏歌单。');
    }
    await playlistFavoritesRepository.setPlaylistFavorite(playlistId, value);
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

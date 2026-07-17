import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/adapters/cached_music_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CachedMusicRepository', () {
    test('在 TTL 内复用同一批列表结果，过期后重新回源', () async {
      var currentTime = DateTime(2026, 4, 23, 14, 40);
      final delegate = _CountingMusicRepository(session: _session());
      final repository = CachedMusicRepository(
        delegate: delegate,
        now: () => currentTime,
        policy: const MusicRepositoryCachePolicy(
          listTtl: Duration(seconds: 30),
          detailTtl: Duration(seconds: 30),
          searchTtl: Duration(seconds: 30),
          homeFeedTtl: Duration(seconds: 30),
          streamUrlTtl: Duration(seconds: 30),
        ),
      );

      await repository.restoreSession();
      final first = await repository.fetchTracks(
        limit: 50,
        startIndex: 0,
        searchQuery: 'jay',
      );
      final second = await repository.fetchTracks(
        limit: 50,
        startIndex: 0,
        searchQuery: 'jay',
      );

      expect(delegate.fetchTracksCalls, 1);
      expect(second.items.single.id, first.items.single.id);

      currentTime = currentTime.add(const Duration(seconds: 31));
      final third = await repository.fetchTracks(
        limit: 50,
        startIndex: 0,
        searchQuery: 'jay',
      );

      expect(delegate.fetchTracksCalls, 2);
      expect(third.items.single.id, isNot(first.items.single.id));
    });

    test('过期后回源失败时回退上一份缓存，避免页面直接空掉', () async {
      var currentTime = DateTime(2026, 4, 23, 15, 10);
      final delegate = _CountingMusicRepository(session: _session());
      final repository = CachedMusicRepository(
        delegate: delegate,
        now: () => currentTime,
        policy: const MusicRepositoryCachePolicy(
          listTtl: Duration(seconds: 10),
          detailTtl: Duration(seconds: 10),
          searchTtl: Duration(seconds: 10),
          homeFeedTtl: Duration(seconds: 10),
          streamUrlTtl: Duration(seconds: 10),
        ),
      );

      await repository.restoreSession();
      final first = await repository.fetchTracks(limit: 20);
      delegate.failFetchTracks = true;
      currentTime = currentTime.add(const Duration(seconds: 11));
      final fallback = await repository.fetchTracks(limit: 20);

      expect(delegate.fetchTracksCalls, 2);
      expect(fallback.items.single.id, first.items.single.id);
    });

    test('receiveTimeout 不自动重试，避免慢服务被重复请求放大压力', () async {
      var currentTime = DateTime(2026, 4, 23, 15, 30);
      final delegate = _CountingMusicRepository(session: _session());
      final repository = CachedMusicRepository(
        delegate: delegate,
        now: () => currentTime,
        policy: const MusicRepositoryCachePolicy(
          listTtl: Duration(seconds: 10),
        ),
      );

      await repository.restoreSession();
      final first = await repository.fetchTracks(limit: 20);
      delegate.failFetchTracksWithReceiveTimeout = true;
      currentTime = currentTime.add(const Duration(seconds: 11));
      final fallback = await repository.fetchTracks(limit: 20);

      expect(delegate.fetchTracksCalls, 2);
      expect(fallback.items.single.id, first.items.single.id);
    });

    test('收藏状态变更后清空列表缓存，避免旧数据残留', () async {
      final delegate = _CountingMusicRepository(session: _session());
      final repository = CachedMusicRepository(delegate: delegate);

      await repository.restoreSession();
      final beforeFavorite = await repository.fetchTracks(limit: 20);
      await repository.setFavorite('track-1', true);
      final afterFavorite = await repository.fetchTracks(limit: 20);

      expect(delegate.setFavoriteCalls, 1);
      expect(delegate.fetchTracksCalls, 2);
      expect(
        afterFavorite.items.single.id,
        isNot(beforeFavorite.items.single.id),
      );
    });

    test('在短 TTL 内复用 stream URL，减少切歌前的重复回源', () async {
      var currentTime = DateTime(2026, 4, 23, 16, 20);
      final delegate = _CountingMusicRepository(session: _session());
      final repository = CachedMusicRepository(
        delegate: delegate,
        now: () => currentTime,
        policy: const MusicRepositoryCachePolicy(
          streamUrlTtl: Duration(seconds: 20),
        ),
      );

      await repository.restoreSession();
      final first = await repository.getStreamUrl(
        'track-1',
        quality: AudioQuality.high,
      );
      final second = await repository.getStreamUrl(
        'track-1',
        quality: AudioQuality.high,
      );

      expect(delegate.getStreamUrlCalls, 1);
      expect(second, first);

      currentTime = currentTime.add(const Duration(seconds: 21));
      final third = await repository.getStreamUrl(
        'track-1',
        quality: AudioQuality.high,
      );

      expect(delegate.getStreamUrlCalls, 2);
      expect(third, isNot(first));
    });

    test('超过内存缓存上限时淘汰最久未使用条目', () async {
      final delegate = _CountingMusicRepository(session: _session());
      final repository = CachedMusicRepository(
        delegate: delegate,
        policy: const MusicRepositoryCachePolicy(maxMemoryEntries: 2),
      );

      await repository.restoreSession();
      await repository.fetchTracks(limit: 1, startIndex: 0);
      await repository.fetchTracks(limit: 1, startIndex: 1);
      await repository.fetchTracks(limit: 1, startIndex: 0);
      await repository.fetchTracks(limit: 1, startIndex: 2);
      await repository.fetchTracks(limit: 1, startIndex: 1);

      expect(delegate.fetchTracksCalls, 4);
    });

    test('歌单列表按分页参数缓存，不再回源拉取完整列表', () async {
      final delegate = _CountingMusicRepository(session: _session());
      final repository = CachedMusicRepository(delegate: delegate);

      await repository.restoreSession();
      final first = await repository.fetchPlaylists(limit: 20, startIndex: 0);
      final second = await repository.fetchPlaylists(limit: 20, startIndex: 0);
      final nextPage = await repository.fetchPlaylists(
        limit: 20,
        startIndex: 20,
      );

      expect(delegate.fetchPlaylistsCalls, 2);
      expect(delegate.playlistRequests, [
        (limit: 20, startIndex: 0, searchQuery: null),
        (limit: 20, startIndex: 20, searchQuery: null),
      ]);
      expect(second.single.id, first.single.id);
      expect(nextPage.single.id, isNot(first.single.id));
    });
  });
}

class _CountingMusicRepository extends Fake implements MusicRepository {
  _CountingMusicRepository({AuthSession? session}) : _session = session;

  AuthSession? _session;
  int fetchTracksCalls = 0;
  int fetchPlaylistsCalls = 0;
  int getStreamUrlCalls = 0;
  int setFavoriteCalls = 0;
  final playlistRequests =
      <({int limit, int startIndex, String? searchQuery})>[];
  bool failFetchTracks = false;
  bool failFetchTracksWithReceiveTimeout = false;

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    _session = AuthSession(
      serverUrl: serverUrl,
      userId: username,
      userName: username,
      accessToken: password,
    );
    return _session!;
  }

  @override
  Future<void> logout() async {
    _session = null;
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    fetchTracksCalls += 1;
    if (failFetchTracksWithReceiveTimeout) {
      throw DioException(
        requestOptions: RequestOptions(path: '/tracks'),
        type: DioExceptionType.receiveTimeout,
      );
    }
    if (failFetchTracks) {
      throw Exception('fetch failed');
    }
    return PaginatedResult(items: [_track('track-$fetchTracksCalls')]);
  }

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    fetchPlaylistsCalls += 1;
    playlistRequests.add((
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    ));
    return [
      MusicPlaylist(
        id: 'playlist-$fetchPlaylistsCalls',
        name: 'playlist $fetchPlaylistsCalls',
        artworkUrl: '',
      ),
    ];
  }

  @override
  Future<void> setFavorite(String itemId, bool value) async {
    setFavoriteCalls += 1;
  }

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) async {
    getStreamUrlCalls += 1;
    return 'https://example.com/'
        '$trackId/${quality.storageKey}/$getStreamUrlCalls';
  }
}

AuthSession _session() {
  return const AuthSession(
    serverUrl: 'https://emby.example.com',
    userId: 'user-1',
    userName: 'tester',
    accessToken: 'token',
  );
}

MusicTrack _track(String id) {
  return MusicTrack(
    id: id,
    title: id,
    artistName: 'artist',
    albumTitle: 'album',
    artworkUrl: '',
    duration: Duration.zero,
    isFavorite: false,
  );
}

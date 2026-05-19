import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/adapters/cached_music_repository.dart';
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

    test('收藏状态变更后清空列表缓存，避免旧数据残留', () async {
      final delegate = _CountingMusicRepository(session: _session());
      final repository = CachedMusicRepository(delegate: delegate);

      await repository.restoreSession();
      final beforeFavorite = await repository.fetchTracks(limit: 20);
      await repository.setFavorite('track-1', true);
      final afterFavorite = await repository.fetchTracks(limit: 20);

      expect(delegate.setFavoriteCalls, 1);
      expect(delegate.fetchTracksCalls, 2);
      expect(afterFavorite.items.single.id, isNot(beforeFavorite.items.single.id));
    });
  });
}

class _CountingMusicRepository extends Fake implements MusicRepository {
  _CountingMusicRepository({AuthSession? session}) : _session = session;

  AuthSession? _session;
  int fetchTracksCalls = 0;
  int setFavoriteCalls = 0;
  bool failFetchTracks = false;

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
    if (failFetchTracks) {
      throw Exception('fetch failed');
    }
    return PaginatedResult(items: [_track('track-$fetchTracksCalls')]);
  }

  @override
  Future<void> setFavorite(String itemId, bool value) async {
    setFavoriteCalls += 1;
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

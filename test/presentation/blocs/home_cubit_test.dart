import 'package:cross_platform_music_player/application/usecases/fetch_latest_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_random_albums.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_state.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeCubit randomPicks', () {
    test('加载成功后 randomPicks 出现在 state 中', () async {
      final fakeRepo = _FakeRepo(albums: _fakeAlbums(count: 6));
      final cubit = HomeCubit(
        FetchLatestAlbums(fakeRepo),
        FetchRandomAlbums(fakeRepo),
        fakeRepo,
      );

      await cubit.load();

      expect(cubit.state.randomPicks.length, 6);
      expect(cubit.state.randomPicks.first.title, '随机专辑_0');
      expect(cubit.state.status, HomeStatus.success);
    });

    test('randomPicks 加载失败时不影响其他区块', () async {
      final fakeRepo = _FakeRepo(
        albums: _fakeAlbums(count: 6),
        randomFails: true,
      );
      final cubit = HomeCubit(
        FetchLatestAlbums(fakeRepo),
        FetchRandomAlbums(fakeRepo),
        fakeRepo,
      );

      await cubit.load();

      // randomPicks 为空（失败），但其他区块正常
      expect(cubit.state.randomPicks, isEmpty);
      expect(cubit.state.albums.length, 4);
      expect(cubit.state.recentlyPlayed, isNotEmpty);
      expect(cubit.state.status, HomeStatus.success);
    });

    test('全部失败且无数据时状态为 failure', () async {
      final fakeRepo = _FakeRepo(allFail: true);
      final cubit = HomeCubit(
        FetchLatestAlbums(fakeRepo),
        FetchRandomAlbums(fakeRepo),
        fakeRepo,
      );

      await cubit.load();

      expect(cubit.state.status, HomeStatus.failure);
      expect(cubit.state.randomPicks, isEmpty);
      expect(cubit.state.errorMessage, isNotNull);
    });

    test('渐进式 emit — 中间状态包含 randomPicks', () async {
      final fakeRepo = _FakeRepo(albums: _fakeAlbums(count: 6));
      final states = <HomeState>[];
      final cubit = HomeCubit(
        FetchLatestAlbums(fakeRepo),
        FetchRandomAlbums(fakeRepo),
        fakeRepo,
      );
      cubit.stream.listen(states.add);

      await cubit.load();

      // 至少有一个中间状态包含 randomPicks 且不是最终 complete
      final intermediateWithRandom = states.any(
        (s) =>
            s.randomPicks.isNotEmpty &&
            s.status == HomeStatus.success &&
            s.albums.isEmpty,
      );
      expect(intermediateWithRandom, isTrue);
    });

    test('本地最近播放保留歌曲时长', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      const duration = Duration(minutes: 3, seconds: 42);
      await database.insertPlayHistory(
        PlayHistoryCompanion.insert(
          trackId: 'local-track',
          title: '本地播放记录',
          artistName: const Value('测试艺术家'),
          albumTitle: const Value('测试专辑'),
          playedAtMs: DateTime(2026, 1, 1, 9, 30).millisecondsSinceEpoch,
          durationPlayedMs: Value(duration.inMilliseconds),
        ),
      );
      final fakeRepo = _FakeRepo(albums: _fakeAlbums(count: 6));
      final cubit = HomeCubit(
        FetchLatestAlbums(fakeRepo),
        FetchRandomAlbums(fakeRepo),
        fakeRepo,
        database: database,
      );

      await cubit.load();

      expect(cubit.state.recentlyPlayed.single.duration, duration);
    });
  });

  group('HomeState copyWith', () {
    test('copyWith 保留 randomPicks 字段', () {
      const state = HomeState(
        status: HomeStatus.success,
        randomPicks: [
          MusicAlbum(
            id: 'a1',
            title: '推荐专辑',
            artistName: '艺术家',
            artworkUrl: '',
            trackCount: 12,
          ),
        ],
      );

      final updated = state.copyWith(status: HomeStatus.loading);

      expect(updated.status, HomeStatus.loading);
      expect(updated.randomPicks.length, 1);
      expect(updated.randomPicks.first.title, '推荐专辑');
    });

    test('copyWith 可更新 randomPicks', () {
      const state = HomeState.initial();

      final updated = state.copyWith(
        randomPicks: [
          MusicAlbum(
            id: 'a1',
            title: '新推荐',
            artistName: '艺术家',
            artworkUrl: '',
            trackCount: 5,
          ),
        ],
      );

      expect(updated.randomPicks.length, 1);
    });
  });
}

List<MusicAlbum> _fakeAlbums({int count = 1}) {
  return List.generate(
    count,
    (i) => MusicAlbum(
      id: 'ra_$i',
      title: '随机专辑_$i',
      artistName: '随机艺术家_$i',
      artworkUrl: '',
      trackCount: 8 + i,
    ),
  );
}

List<MusicAlbum> _latestAlbums() {
  return List.generate(
    4,
    (i) => MusicAlbum(
      id: 'la_$i',
      title: '最新专辑_$i',
      artistName: '最新艺术家_$i',
      artworkUrl: '',
      trackCount: 10,
    ),
  );
}

class _FakeRepo implements MusicRepository {
  _FakeRepo({
    this.albums = const [],
    this.randomFails = false,
    this.allFail = false,
  });

  final List<MusicAlbum> albums;
  final bool randomFails;
  final bool allFail;

  @override
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) async {
    if (randomFails || allFail) throw Exception('模拟失败');
    return albums;
  }

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async {
    if (allFail) throw Exception('模拟失败');
    return albums.isNotEmpty ? _latestAlbums() : const [];
  }

  @override
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) async {
    if (allFail) throw Exception('模拟失败');
    return [
      MusicTrack(
        id: 't1',
        title: '最近播放曲目',
        artistName: '艺术家',
        albumTitle: '专辑',
        artworkUrl: '',
        duration: Duration.zero,
      ),
    ];
  }

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) async {
    if (allFail) throw Exception('模拟失败');
    return [
      MusicTrack(
        id: 't2',
        title: '常听曲目',
        artistName: '艺术家',
        albumTitle: '专辑',
        artworkUrl: '',
        duration: Duration.zero,
        playCount: 42,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:cross_platform_music_player/application/usecases/fetch_random_albums.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FetchRandomAlbums', () {
    test('委托给 MusicRepository.fetchRandomAlbums 并透传 limit 参数', () async {
      final fake = _FakeMusicRepository();
      final useCase = FetchRandomAlbums(fake);

      final result = await useCase(limit: 6);

      expect(fake.fetchRandomAlbumsCallCount, 1);
      expect(fake.lastLimit, 6);
      expect(result.length, 1);
      expect(result.first.title, '随机专辑');
    });

    test('不传 limit 时使用默认值', () async {
      final fake = _FakeMusicRepository();
      final useCase = FetchRandomAlbums(fake);

      await useCase();

      expect(fake.fetchRandomAlbumsCallCount, 1);
    });

    test('空结果正常返回', () async {
      final fake = _FakeMusicRepository(returnsEmpty: true);
      final useCase = FetchRandomAlbums(fake);

      final result = await useCase(limit: 6);

      expect(result, isEmpty);
    });
  });
}

class _FakeMusicRepository implements MusicRepository {
  _FakeMusicRepository({this.returnsEmpty = false});

  final bool returnsEmpty;
  int fetchRandomAlbumsCallCount = 0;
  int? lastLimit;

  @override
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) async {
    fetchRandomAlbumsCallCount++;
    lastLimit = limit;
    if (returnsEmpty) return const [];
    return [
      MusicAlbum(
        id: 'r1',
        title: '随机专辑',
        artistName: '随机艺术家',
        artworkUrl: '',
        trackCount: 10,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

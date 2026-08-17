import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FavoritesCubit', () {
    test('切换成功时保留乐观收藏状态并返回 true', () async {
      final repository = _FavoritesRepository();
      final cubit = FavoritesCubit(repository);

      final result = await cubit.toggle('track-1', currentValue: true);

      expect(result, isTrue);
      expect(repository.requests, [('track-1', false)]);
      expect(cubit.isFavorite('track-1'), isFalse);
      expect(cubit.state.pending, isEmpty);
    });

    test('切换失败时回滚状态并返回 false', () async {
      final cubit = FavoritesCubit(_FavoritesRepository(shouldFail: true));
      cubit.seed('track-1', true);

      final result = await cubit.toggle('track-1', currentValue: true);

      expect(result, isFalse);
      expect(cubit.isFavorite('track-1'), isTrue);
      expect(cubit.state.pending, isEmpty);
    });
  });
}

class _FavoritesRepository implements MusicRepository {
  _FavoritesRepository({this.shouldFail = false});

  final bool shouldFail;
  final List<(String, bool)> requests = [];

  @override
  Future<void> setFavorite(String itemId, bool value) async {
    requests.add((itemId, value));
    if (shouldFail) throw Exception('network failure');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

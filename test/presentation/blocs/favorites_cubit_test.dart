import 'dart:async';

import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reset prevents an old session toggle from restoring favorite state',
    () async {
      final repository = _FavoritesRepository();
      final cubit = FavoritesCubit(repository);
      addTearDown(cubit.close);

      final toggle = cubit.toggle('old-track', currentValue: false);
      expect(cubit.state.pending, contains('old-track'));

      cubit.reset();
      repository.pendingRequest.complete();

      expect(await toggle, isFalse);
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.pending, isEmpty);
    },
  );
}

class _FavoritesRepository extends Fake implements MusicRepository {
  final pendingRequest = Completer<void>();

  @override
  Future<void> setFavorite(String itemId, bool isFavorite) {
    return pendingRequest.future;
  }
}

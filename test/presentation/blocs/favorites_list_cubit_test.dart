import 'package:cross_platform_music_player/application/usecases/fetch_favorite_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('按 40 首一页加载收藏，并在尾页停止分页', () async {
    final repository = _PagedFavoritesRepository(total: 41);
    final cubit = FavoritesListCubit(
      FetchFavoriteTracks(repository),
      FavoritesCubit(repository),
    );

    await cubit.load();
    expect(cubit.state.status, FavoritesListStatus.success);
    expect(cubit.state.tracks, hasLength(40));
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();
    expect(cubit.state.tracks, hasLength(41));
    expect(cubit.state.hasMore, isFalse);
    expect(repository.startIndexes, [0, 40]);

    await cubit.loadMore();
    expect(repository.startIndexes, [0, 40]);
  });
}

class _PagedFavoritesRepository implements MusicRepository {
  _PagedFavoritesRepository({required this.total});

  final int total;
  final List<int> startIndexes = [];

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async {
    startIndexes.add(startIndex);
    final end = (startIndex + limit).clamp(0, total);
    return List.generate(
      end - startIndex,
      (index) => MusicTrack(
        id: 'track-${startIndex + index}',
        title: '收藏歌曲 ${startIndex + index}',
        artistName: '艺术家',
        albumTitle: '专辑',
        artworkUrl: '',
        duration: const Duration(minutes: 3),
        isFavorite: true,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

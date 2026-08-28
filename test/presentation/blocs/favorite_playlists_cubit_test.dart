import 'package:cross_platform_music_player/application/usecases/fetch_favorite_playlists.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorite_playlists_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorite_playlists_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('收藏歌单分页使用已加载数量作为偏移量', () async {
    final repository = _PlaylistFavoritesRepository();
    final cubit = FavoritePlaylistsCubit(FetchFavoritePlaylists(repository));
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.loadMore();

    expect(repository.startIndexes, [0, 40]);
    expect(cubit.state.status, FavoritePlaylistsStatus.success);
    expect(cubit.state.playlists, hasLength(41));
  });
}

class _PlaylistFavoritesRepository implements PlaylistFavoritesRepository {
  final startIndexes = <int>[];

  @override
  Future<List<MusicPlaylist>> fetchFavoritePlaylists({
    int limit = 60,
    int startIndex = 0,
  }) async {
    startIndexes.add(startIndex);
    if (startIndex == 0) {
      return List.generate(
        40,
        (index) => MusicPlaylist(
          id: 'playlist-$index',
          name: '歌单 $index',
          artworkUrl: '',
        ),
      );
    }
    return const [MusicPlaylist(id: 'playlist-40', name: '四十', artworkUrl: '')];
  }

  @override
  Future<void> setPlaylistFavorite(String playlistId, bool value) async {}

  @override
  Future<bool> supportsPlaylistFavorites() async => true;
}

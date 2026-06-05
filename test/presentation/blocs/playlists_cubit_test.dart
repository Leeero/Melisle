import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search_filtersLoadedPlaylistsWithoutRemoteQuery', () async {
    final repository = _FakePlaylistRepository([
      const MusicPlaylist(id: 'playlist-1', name: '深夜独处', artworkUrl: ''),
      const MusicPlaylist(id: 'playlist-2', name: '通勤路上', artworkUrl: ''),
      const MusicPlaylist(id: 'playlist-3', name: '工作专注', artworkUrl: ''),
    ]);
    final cubit = PlaylistsCubit(FetchPlaylists(repository));
    addTearDown(cubit.close);

    await cubit.load();
    cubit.search('通勤');

    expect(repository.searchQueries, [isNull]);
    expect(cubit.state.status, PlaylistsStatus.success);
    expect(cubit.state.allPlaylists.length, 3);
    expect(cubit.state.playlists.single.name, '通勤路上');
  });
}

class _FakePlaylistRepository implements MusicRepository {
  _FakePlaylistRepository(this.playlists);

  final List<MusicPlaylist> playlists;
  final searchQueries = <String?>[];

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    searchQueries.add(searchQuery);
    return playlists.skip(startIndex).take(limit).toList(growable: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load_fetchesOnlyFirstPage', () async {
    final repository = _FakePlaylistRepository(
      List.generate(
        250,
        (index) => MusicPlaylist(
          id: 'playlist-$index',
          name: '歌单 $index',
          artworkUrl: '',
        ),
      ),
    );
    final cubit = PlaylistsCubit(FetchPlaylists(repository));
    addTearDown(cubit.close);

    await cubit.load();

    expect(repository.requests, [
      const _PlaylistRequest(limit: 100, startIndex: 0),
    ]);
    expect(cubit.state.status, PlaylistsStatus.success);
    expect(cubit.state.allPlaylists.length, 100);
    expect(cubit.state.hasMore, isTrue);
  });

  test('loadMore_fetchesNextPage', () async {
    final repository = _FakePlaylistRepository(
      List.generate(
        250,
        (index) => MusicPlaylist(
          id: 'playlist-$index',
          name: '歌单 $index',
          artworkUrl: '',
        ),
      ),
    );
    final cubit = PlaylistsCubit(FetchPlaylists(repository));
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.loadMore();

    expect(repository.requests, [
      const _PlaylistRequest(limit: 100, startIndex: 0),
      const _PlaylistRequest(limit: 100, startIndex: 100),
    ]);
    expect(cubit.state.allPlaylists.length, 200);
    expect(cubit.state.hasMore, isTrue);
  });

  test('search_fetchesFirstPageFromRepository', () async {
    final repository = _FakePlaylistRepository([
      const MusicPlaylist(id: 'playlist-1', name: '深夜独处', artworkUrl: ''),
      const MusicPlaylist(id: 'playlist-2', name: '通勤路上', artworkUrl: ''),
      const MusicPlaylist(id: 'playlist-3', name: '工作专注', artworkUrl: ''),
    ]);
    final cubit = PlaylistsCubit(FetchPlaylists(repository));
    addTearDown(cubit.close);

    await cubit.load();
    cubit.search('通勤');
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(repository.requests, [
      const _PlaylistRequest(limit: 100, startIndex: 0),
      const _PlaylistRequest(limit: 100, startIndex: 0, searchQuery: '通勤'),
    ]);
    expect(cubit.state.status, PlaylistsStatus.success);
    expect(cubit.state.searchQuery, '通勤');
    expect(cubit.state.allPlaylists.length, 1);
    expect(cubit.state.playlists.single.name, '通勤路上');
  });
}

class _PlaylistRequest {
  const _PlaylistRequest({
    required this.limit,
    required this.startIndex,
    this.searchQuery,
  });

  final int limit;
  final int startIndex;
  final String? searchQuery;

  @override
  bool operator ==(Object other) {
    return other is _PlaylistRequest &&
        other.limit == limit &&
        other.startIndex == startIndex &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(limit, startIndex, searchQuery);

  @override
  String toString() {
    return '_PlaylistRequest(limit: $limit, '
        'startIndex: $startIndex, searchQuery: $searchQuery)';
  }
}

class _FakePlaylistRepository implements MusicRepository {
  _FakePlaylistRepository(this.playlists);

  final List<MusicPlaylist> playlists;
  final requests = <_PlaylistRequest>[];

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    requests.add(
      _PlaylistRequest(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      ),
    );
    final filtered = searchQuery == null || searchQuery.trim().isEmpty
        ? playlists
        : playlists
              .where((playlist) => playlist.name.contains(searchQuery.trim()))
              .toList(growable: false);
    return filtered.skip(startIndex).take(limit).toList(growable: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

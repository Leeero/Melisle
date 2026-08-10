import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newer filter request ignores the older track response', () async {
    final repository = _DelayedLibraryRepository();
    final cubit = LibraryCubit(
      FetchLibraryTracks(repository),
      FetchLibraryAlbums(repository),
      FetchLibraryArtists(repository),
      repository,
    );
    addTearDown(cubit.close);

    final initialLoad = cubit.load();
    await repository.trackRequestStarted.future;

    await cubit.changeFilter(LibraryFilter.albums);
    expect(cubit.state.currentFilter, LibraryFilter.albums);
    expect(cubit.state.albums.single.title, '新专辑');

    repository.trackResponse.complete(
      PaginatedResult(items: [_track(title: '旧歌曲')]),
    );
    await initialLoad;

    expect(cubit.state.currentFilter, LibraryFilter.albums);
    expect(cubit.state.albums.single.title, '新专辑');
    expect(cubit.state.tracks, isEmpty);
  });
}

MusicTrack _track({required String title}) {
  return MusicTrack(
    id: title,
    title: title,
    artistName: '艺术家',
    albumTitle: '专辑',
    artworkUrl: '',
    duration: const Duration(minutes: 3),
  );
}

class _DelayedLibraryRepository implements MusicRepository {
  final trackRequestStarted = Completer<void>();
  final trackResponse = Completer<PaginatedResult<MusicTrack>>();

  @override
  Future<List<Genre>> fetchGenres() async => [];

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    if (!trackRequestStarted.isCompleted) trackRequestStarted.complete();
    return trackResponse.future;
  }

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    return const [
      MusicAlbum(
        id: 'album-1',
        title: '新专辑',
        artistName: '艺术家',
        artworkUrl: '',
        trackCount: 1,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/track_sort_option.dart';
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

  test('loadMore appends tracks and marks the final page complete', () async {
    final repository = _PagedLibraryRepository();
    final cubit = LibraryCubit(
      FetchLibraryTracks(repository),
      FetchLibraryAlbums(repository),
      FetchLibraryArtists(repository),
      repository,
    );
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.tracks, hasLength(30));
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();

    expect(cubit.state.tracks, hasLength(31));
    expect(cubit.state.hasMore, isFalse);
    expect(cubit.state.appendErrorMessage, isNull);
  });

  test('append failure preserves items and retry continues the page', () async {
    final repository = _PagedLibraryRepository(failFirstAppend: true);
    final cubit = LibraryCubit(
      FetchLibraryTracks(repository),
      FetchLibraryAlbums(repository),
      FetchLibraryArtists(repository),
      repository,
    );
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.loadMore();

    expect(cubit.state.status, LibraryStatus.success);
    expect(cubit.state.tracks, hasLength(30));
    expect(cubit.state.appendErrorMessage, isNotNull);

    await cubit.loadMore();

    expect(cubit.state.tracks, hasLength(31));
    expect(cubit.state.appendErrorMessage, isNull);
    expect(cubit.state.hasMore, isFalse);
  });

  test('concurrent loadMore calls issue only one repository request', () async {
    final repository = _PagedLibraryRepository();
    final cubit = LibraryCubit(
      FetchLibraryTracks(repository),
      FetchLibraryAlbums(repository),
      FetchLibraryArtists(repository),
      repository,
    );
    addTearDown(cubit.close);

    await cubit.load();
    await Future.wait([cubit.loadMore(), cubit.loadMore(), cubit.loadMore()]);

    expect(repository.trackRequests, 2);
    expect(cubit.state.tracks, hasLength(31));
  });

  test('supported server sort resets pagination and reloads tracks', () async {
    final repository = _PagedLibraryRepository();
    final cubit = LibraryCubit(
      FetchLibraryTracks(repository),
      FetchLibraryAlbums(repository),
      FetchLibraryArtists(repository),
      repository,
    );
    addTearDown(cubit.close);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.supportedTrackSortOptions,
      contains(TrackSortOption.artist),
    );

    cubit.changeTrackSort(TrackSortOption.artist);
    await Future<void>.delayed(Duration.zero);

    expect(repository.lastSortOption, TrackSortOption.artist);
    expect(cubit.state.trackSortOption, TrackSortOption.artist);
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

class _PagedLibraryRepository
    implements MusicRepository, TrackSortingRepository {
  _PagedLibraryRepository({this.failFirstAppend = false});

  final bool failFirstAppend;
  int trackRequests = 0;
  bool _appendFailed = false;
  TrackSortOption? lastSortOption;

  @override
  Future<Set<TrackSortOption>> fetchSupportedTrackSortOptions() async => const {
    TrackSortOption.title,
    TrackSortOption.artist,
  };

  @override
  Future<PaginatedResult<MusicTrack>> fetchSortedTracks({
    required TrackSortOption sortOption,
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    lastSortOption = sortOption;
    return fetchTracks(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<Genre>> fetchGenres() async => [];

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    trackRequests += 1;
    if (startIndex == 0) {
      return PaginatedResult(
        items: List.generate(limit, (index) => _track(title: '歌曲 $index')),
      );
    }
    if (failFirstAppend && !_appendFailed) {
      _appendFailed = true;
      throw Exception('network unavailable');
    }
    return PaginatedResult(items: [_track(title: '最后一首')]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

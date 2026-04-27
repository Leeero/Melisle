import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(
    this._fetchLibraryTracks,
    this._fetchLibraryAlbums,
    this._fetchLibraryArtists,
  ) : super(const LibraryState.initial());

  static const _pageSize = 30;
  static const _requestTimeout = Duration(seconds: 30);

  final FetchLibraryTracks _fetchLibraryTracks;
  final FetchLibraryAlbums _fetchLibraryAlbums;
  final FetchLibraryArtists _fetchLibraryArtists;

  Timer? _searchDebounce;

  Future<void> load() async {
    await _loadCurrentFilter(reset: true);
  }

  Future<void> loadMore() async {
    if (state.status != LibraryStatus.success || state.isLoadingMore || !state.hasMore) {
      return;
    }

    await _loadCurrentFilter(reset: false);
  }

  Future<void> changeFilter(LibraryFilter filter) async {
    if (filter == state.currentFilter) {
      return;
    }

    emit(
      state.copyWith(
        currentFilter: filter,
        searchQuery: '',
        hasMore: true,
        isLoadingMore: false,
        errorMessage: null,
      ),
    );

    await _loadCurrentFilter(reset: true);
  }

  void search(String query) {
    _searchDebounce?.cancel();

    emit(state.copyWith(searchQuery: query, errorMessage: null));

    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_loadCurrentFilter(reset: true));
    });
  }

  Future<void> _loadCurrentFilter({required bool reset}) async {
    final query = state.searchQuery.trim();
    final searchQuery = query.isEmpty ? null : query;

    if (reset) {
      emit(
        state.copyWith(
          status: LibraryStatus.loading,
          hasMore: true,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } else {
      emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    }

    try {
      switch (state.currentFilter) {
        case LibraryFilter.tracks:
          final startIndex = reset ? 0 : state.tracks.length;
          final tracks = await _fetchLibraryTracks(
            limit: _pageSize,
            startIndex: startIndex,
            searchQuery: searchQuery,
          ).timeout(_requestTimeout);
          emit(
            state.copyWith(
              status: LibraryStatus.success,
              tracks: reset ? tracks : [...state.tracks, ...tracks],
              hasMore: tracks.length == _pageSize,
              isLoadingMore: false,
              errorMessage: null,
            ),
          );
          break;
        case LibraryFilter.albums:
          final startIndex = reset ? 0 : state.albums.length;
          final albums = await _fetchLibraryAlbums(
            limit: _pageSize,
            startIndex: startIndex,
            searchQuery: searchQuery,
          ).timeout(_requestTimeout);
          emit(
            state.copyWith(
              status: LibraryStatus.success,
              albums: reset ? albums : [...state.albums, ...albums],
              hasMore: albums.length == _pageSize,
              isLoadingMore: false,
              errorMessage: null,
            ),
          );
          break;
        case LibraryFilter.artists:
          final startIndex = reset ? 0 : state.artists.length;
          final artists = await _fetchLibraryArtists(
            limit: _pageSize,
            startIndex: startIndex,
            searchQuery: searchQuery,
          ).timeout(_requestTimeout);
          emit(
            state.copyWith(
              status: LibraryStatus.success,
              artists: reset ? artists : [...state.artists, ...artists],
              hasMore: artists.length == _pageSize,
              isLoadingMore: false,
              errorMessage: null,
            ),
          );
          break;
      }
    } on TimeoutException {
      emit(
        state.copyWith(
          status: LibraryStatus.failure,
          isLoadingMore: false,
          errorMessage: '加载媒体库超时，请稍后重试。',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LibraryStatus.failure,
          isLoadingMore: false,
          errorMessage: '加载媒体库失败：$error',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    _searchDebounce?.cancel();
    return super.close();
  }
}

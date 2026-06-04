import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(
    this._fetchLibraryTracks,
    this._fetchLibraryAlbums,
    this._fetchLibraryArtists,
    this._musicRepository,
  ) : super(const LibraryState.initial());

  static const _pageSize = 30;
  static const _requestTimeout = Duration(seconds: 30);

  final FetchLibraryTracks _fetchLibraryTracks;
  final FetchLibraryAlbums _fetchLibraryAlbums;
  final FetchLibraryArtists _fetchLibraryArtists;
  final MusicRepository _musicRepository;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: LibraryStatus.loading,
        hasMore: true,
        isLoadingMore: false,
        errorMessage: null,
      ),
    );
    await _loadGenres();
    await _loadCurrentFilter(reset: true);
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _musicRepository.fetchGenres();
      emit(state.copyWith(genres: genres));
    } catch (_) {
      // 加载风格列表失败不影响主要内容展示
    }
  }

  Future<void> loadMore() async {
    if (state.status != LibraryStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) {
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
        status: LibraryStatus.loading,
        currentFilter: filter,
        searchQuery: '',
        hasMore: true,
        isLoadingMore: false,
        errorMessage: null,
      ),
    );

    await _loadCurrentFilter(reset: true);
  }

  void changeGenre(String? genreId) {
    if (genreId == state.selectedGenreId) return;
    emit(
      state.copyWith(
        selectedGenreId: genreId,
        hasMore: true,
        isLoadingMore: false,
        errorMessage: null,
      ),
    );
    unawaited(_loadCurrentFilter(reset: true));
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query, errorMessage: null));
    unawaited(_loadCurrentFilter(reset: true));
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
          final result = await _fetchLibraryTracks(
            limit: _pageSize,
            startIndex: startIndex,
            searchQuery: searchQuery,
          ).timeout(_requestTimeout);
          emit(
            state.copyWith(
              status: LibraryStatus.success,
              tracks: reset ? result.items : [...state.tracks, ...result.items],
              totalTrackCount: result.totalCount,
              hasMore: _hasMore(
                loadedCount: reset
                    ? result.items.length
                    : state.tracks.length + result.items.length,
                loadedPageSize: result.items.length,
                totalCount: result.totalCount,
              ),
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
            genreId: state.selectedGenreId,
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
        case LibraryFilter.playlists:
          final startIndex = reset ? 0 : state.playlists.length;
          final playlists = await _musicRepository
              .fetchPlaylists(
                limit: _pageSize,
                startIndex: startIndex,
                searchQuery: searchQuery,
              )
              .timeout(_requestTimeout);
          emit(
            state.copyWith(
              status: LibraryStatus.success,
              playlists: reset ? playlists : [...state.playlists, ...playlists],
              hasMore: playlists.length == _pageSize,
              isLoadingMore: false,
              errorMessage: null,
            ),
          );
          break;
        case LibraryFilter.favorites:
          emit(
            state.copyWith(
              status: LibraryStatus.success,
              isLoadingMore: false,
              errorMessage: null,
            ),
          );
          break;
      }
    } on TimeoutException {
      if (reset) {
        emit(
          state.copyWith(
            status: LibraryStatus.failure,
            isLoadingMore: false,
            errorMessage: '加载媒体库超时，请稍后重试。',
          ),
        );
      } else {
        emit(state.copyWith(isLoadingMore: false, errorMessage: '加载超时，请稍后重试。'));
      }
    } catch (error) {
      if (reset) {
        emit(
          state.copyWith(
            status: LibraryStatus.failure,
            isLoadingMore: false,
            errorMessage: '加载媒体库失败：$error',
          ),
        );
      } else {
        emit(state.copyWith(isLoadingMore: false, errorMessage: '加载失败：$error'));
      }
    }
  }

  bool _hasMore({
    required int loadedCount,
    required int loadedPageSize,
    required int? totalCount,
  }) {
    if (totalCount != null) return loadedCount < totalCount;
    // 没有 totalCount（如 Navidrome），回退到判断本次是否装满了整页
    return loadedPageSize == _pageSize;
  }

  Future<void> toggleTrackFavorite(String trackId) async {
    final trackIndex = state.tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex == -1) return;

    final track = state.tracks[trackIndex];
    final newStatus = !track.isFavorite;

    // Optimistic update
    final newTracks = List<MusicTrack>.from(state.tracks);
    newTracks[trackIndex] = track.copyWith(isFavorite: newStatus);
    emit(state.copyWith(tracks: newTracks));

    try {
      await _musicRepository.setFavorite(trackId, newStatus);
    } catch (e) {
      // Revert on failure
      final revertedTracks = List<MusicTrack>.from(state.tracks);
      revertedTracks[trackIndex] = track;
      emit(state.copyWith(tracks: revertedTracks));
      rethrow;
    }
  }
}

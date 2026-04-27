import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  PlaylistsCubit(this._fetchPlaylists) : super(const PlaylistsState.initial());

  static const _pageSize = 40;

  final FetchPlaylists _fetchPlaylists;

  Timer? _searchDebounce;

  Future<void> load() async {
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.status != PlaylistsStatus.success || state.isLoadingMore || !state.hasMore) {
      return;
    }

    await _loadPage(reset: false);
  }

  void search(String query) {
    _searchDebounce?.cancel();
    emit(state.copyWith(searchQuery: query, errorMessage: null));
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_loadPage(reset: true));
    });
  }

  Future<void> _loadPage({required bool reset}) async {
    final query = state.searchQuery.trim();

    if (reset) {
      emit(
        state.copyWith(
          status: PlaylistsStatus.loading,
          hasMore: true,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } else {
      emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    }

    try {
      final playlists = await _fetchPlaylists(
        limit: _pageSize,
        startIndex: reset ? 0 : state.playlists.length,
        searchQuery: query.isEmpty ? null : query,
      );
      emit(
        state.copyWith(
          status: PlaylistsStatus.success,
          playlists: reset ? playlists : [...state.playlists, ...playlists],
          hasMore: playlists.length == _pageSize,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PlaylistsStatus.failure,
          isLoadingMore: false,
          errorMessage: '加载歌单失败：$error',
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

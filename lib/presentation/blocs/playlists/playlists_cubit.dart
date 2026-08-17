import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  PlaylistsCubit(this._fetchPlaylists) : super(const PlaylistsState.initial());

  static const _pageSize = FetchPlaylists.defaultPageSize;
  static const _searchDebounce = Duration(milliseconds: 300);

  final FetchPlaylists _fetchPlaylists;
  Timer? _searchTimer;
  int _loadToken = 0;

  Future<void> load() async {
    _searchTimer?.cancel();
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    final canLoadMore =
        state.status == PlaylistsStatus.success ||
        (state.status == PlaylistsStatus.failure &&
            state.allPlaylists.isNotEmpty);
    if (!canLoadMore || state.isLoadingMore || !state.hasMore) {
      return;
    }

    await _loadPage(reset: false);
  }

  void search(String query) {
    if (query == state.searchQuery) return;

    _searchTimer?.cancel();
    _loadToken += 1;
    emit(
      state.copyWith(
        status: PlaylistsStatus.loading,
        searchQuery: query,
        hasMore: false,
        isLoadingMore: false,
        errorMessage: null,
      ),
    );
    _searchTimer = Timer(_searchDebounce, () {
      _loadPage(reset: true, searchQuery: query);
    });
  }

  Future<void> _loadPage({required bool reset, String? searchQuery}) async {
    final query = searchQuery ?? state.searchQuery;
    final token = ++_loadToken;

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
        startIndex: reset ? 0 : state.allPlaylists.length,
        searchQuery: query.trim().isEmpty ? null : query.trim(),
      );
      if (token != _loadToken || isClosed) return;

      final allPlaylists = reset
          ? playlists
          : _appendUniquePlaylists(state.allPlaylists, playlists);
      final hasNewItems = allPlaylists.length > state.allPlaylists.length;
      emit(
        state.copyWith(
          status: PlaylistsStatus.success,
          allPlaylists: allPlaylists,
          playlists: allPlaylists,
          hasMore: playlists.length == _pageSize && (reset || hasNewItems),
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      if (token != _loadToken || isClosed) return;

      emit(
        state.copyWith(
          status: PlaylistsStatus.failure,
          isLoadingMore: false,
          errorMessage: '加载歌单失败：$error',
        ),
      );
    }
  }

  List<MusicPlaylist> _appendUniquePlaylists(
    List<MusicPlaylist> existing,
    List<MusicPlaylist> incoming,
  ) {
    final seenIds = existing.map((playlist) => playlist.id).toSet();
    final merged = <MusicPlaylist>[...existing];
    for (final playlist in incoming) {
      if (seenIds.add(playlist.id)) {
        merged.add(playlist);
      }
    }
    return merged;
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}

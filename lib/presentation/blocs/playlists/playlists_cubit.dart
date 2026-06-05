import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  PlaylistsCubit(this._fetchPlaylists) : super(const PlaylistsState.initial());

  static const _pageSize = 100;

  final FetchPlaylists _fetchPlaylists;

  Future<void> load() async {
    await _loadPage(reset: true);
    while (state.status == PlaylistsStatus.success && state.hasMore) {
      await _loadPage(reset: false);
    }
  }

  Future<void> loadMore() async {
    if (state.status != PlaylistsStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    await _loadPage(reset: false);
  }

  void search(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        playlists: _filterPlaylists(state.allPlaylists, query),
        errorMessage: null,
      ),
    );
  }

  Future<void> _loadPage({required bool reset}) async {
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
      );
      final allPlaylists = reset
          ? playlists
          : _appendUniquePlaylists(state.allPlaylists, playlists);
      final hasNewItems = allPlaylists.length > state.allPlaylists.length;
      emit(
        state.copyWith(
          status: PlaylistsStatus.success,
          allPlaylists: allPlaylists,
          playlists: _filterPlaylists(allPlaylists, state.searchQuery),
          hasMore: playlists.length == _pageSize && (reset || hasNewItems),
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

  List<MusicPlaylist> _filterPlaylists(
    List<MusicPlaylist> playlists,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return playlists;

    return playlists
        .where(
          (playlist) => playlist.name.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }
}

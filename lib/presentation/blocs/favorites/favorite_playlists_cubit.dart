import 'package:cross_platform_music_player/application/usecases/fetch_favorite_playlists.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorite_playlists_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritePlaylistsCubit extends Cubit<FavoritePlaylistsState> {
  FavoritePlaylistsCubit(this._fetchFavoritePlaylists)
    : super(const FavoritePlaylistsState.initial());

  static const _pageSize = 40;
  final FetchFavoritePlaylists _fetchFavoritePlaylists;

  Future<void> load() => _loadPage(reset: true);

  Future<void> loadMore() async {
    if (state.status != FavoritePlaylistsStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) return;
    await _loadPage(reset: false);
  }

  void remove(String playlistId) {
    emit(state.copyWith(
      playlists: state.playlists.where((item) => item.id != playlistId).toList(),
    ));
  }

  Future<void> _loadPage({required bool reset}) async {
    if (reset) {
      emit(state.copyWith(
        status: FavoritePlaylistsStatus.loading,
        playlists: const [],
        loadedCount: 0,
        hasMore: true,
        isLoadingMore: false,
        errorMessage: null,
      ));
    } else {
      emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    }
    try {
      final page = await _fetchFavoritePlaylists(
        limit: _pageSize,
        startIndex: reset ? 0 : state.loadedCount,
      );
      emit(state.copyWith(
        status: FavoritePlaylistsStatus.success,
        playlists: reset ? page : [...state.playlists, ...page],
        loadedCount: reset ? page.length : state.loadedCount + page.length,
        hasMore: page.length == _pageSize,
        isLoadingMore: false,
        errorMessage: null,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: FavoritePlaylistsStatus.failure,
        isLoadingMore: false,
        errorMessage: '加载收藏歌单失败：$error',
      ));
    }
  }
}

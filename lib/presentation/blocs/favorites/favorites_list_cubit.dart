import 'package:cross_platform_music_player/application/usecases/fetch_favorite_tracks.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritesListCubit extends Cubit<FavoritesListState> {
  FavoritesListCubit(this._fetchFavoriteTracks, this._favoritesCubit)
    : super(const FavoritesListState.initial());

  static const _pageSize = 40;

  final FetchFavoriteTracks _fetchFavoriteTracks;
  final FavoritesCubit _favoritesCubit;

  Future<void> load() async {
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.status != FavoritesListStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    await _loadPage(reset: false);
  }

  void removeTrack(String trackId) {
    final next = state.tracks.where((track) => track.id != trackId).toList();
    emit(state.copyWith(tracks: next));
  }

  Future<void> _loadPage({required bool reset}) async {
    if (reset) {
      emit(
        state.copyWith(
          status: FavoritesListStatus.loading,
          tracks: const [],
          loadedCount: 0,
          hasMore: true,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } else {
      emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    }

    try {
      final tracks = await _fetchFavoriteTracks(
        limit: _pageSize,
        startIndex: reset ? 0 : state.loadedCount,
      );
      _favoritesCubit.seedAll({
        for (final track in tracks) track.id: track.isFavorite,
      });
      emit(
        state.copyWith(
          status: FavoritesListStatus.success,
          tracks: reset ? tracks : [...state.tracks, ...tracks],
          loadedCount: reset
              ? tracks.length
              : state.loadedCount + tracks.length,
          hasMore: tracks.length == _pageSize,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FavoritesListStatus.failure,
          isLoadingMore: false,
          errorMessage: '加载收藏失败：$error',
        ),
      );
    }
  }
}

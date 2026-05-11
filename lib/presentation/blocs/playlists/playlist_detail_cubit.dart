import 'package:cross_platform_music_player/application/usecases/fetch_playlist_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlist_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistDetailCubit extends Cubit<PlaylistDetailState> {
  PlaylistDetailCubit(this._fetchPlaylistTracks)
    : super(const PlaylistDetailState.initial());

  static const _pageSize = 80;

  final FetchPlaylistTracks _fetchPlaylistTracks;
  String? _playlistId;

  Future<void> load(String playlistId) async {
    _playlistId = playlistId;
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.status != PlaylistDetailStatus.success ||
        state.isLoadingMore ||
        !state.hasMore ||
        _playlistId == null) {
      return;
    }

    await _loadPage(reset: false);
  }

  Future<List<MusicTrack>> ensureAllTracksLoaded() async {
    while (state.status == PlaylistDetailStatus.success &&
        state.hasMore &&
        !state.isLoadingMore) {
      await loadMore();
    }
    return state.tracks;
  }

  Future<void> _loadPage({required bool reset}) async {
    final playlistId = _playlistId;
    if (playlistId == null) return;

    if (reset) {
      emit(
        state.copyWith(
          status: PlaylistDetailStatus.loading,
          tracks: const [],
          hasMore: true,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } else {
      emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    }

    try {
      final tracks = await _fetchPlaylistTracks(
        playlistId,
        limit: _pageSize,
        startIndex: reset ? 0 : state.tracks.length,
      );
      emit(
        state.copyWith(
          status: PlaylistDetailStatus.success,
          tracks: reset ? tracks : [...state.tracks, ...tracks],
          hasMore: tracks.length == _pageSize,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: reset ? PlaylistDetailStatus.failure : state.status,
          isLoadingMore: false,
          errorMessage: '加载歌单详情失败：$error',
        ),
      );
    }
  }
}

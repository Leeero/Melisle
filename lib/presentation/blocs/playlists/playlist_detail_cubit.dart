import 'package:cross_platform_music_player/application/usecases/fetch_playlist_tracks.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlist_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistDetailCubit extends Cubit<PlaylistDetailState> {
  PlaylistDetailCubit(this._fetchPlaylistTracks)
    : super(const PlaylistDetailState.initial());

  final FetchPlaylistTracks _fetchPlaylistTracks;

  Future<void> load(String playlistId) async {
    emit(
      state.copyWith(status: PlaylistDetailStatus.loading, errorMessage: null),
    );

    try {
      final tracks = await _fetchPlaylistTracks(playlistId);
      emit(
        state.copyWith(status: PlaylistDetailStatus.success, tracks: tracks),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PlaylistDetailStatus.failure,
          errorMessage: '加载歌单详情失败：$error',
        ),
      );
    }
  }
}

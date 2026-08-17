import 'package:cross_platform_music_player/application/usecases/fetch_album_tracks.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumCubit extends Cubit<AlbumState> {
  AlbumCubit(this._fetchAlbumTracks) : super(const AlbumState.initial());

  final FetchAlbumTracks _fetchAlbumTracks;

  Future<void> load(String albumId) async {
    emit(state.copyWith(status: AlbumStatus.loading, clearErrorMessage: true));

    try {
      final tracks = await _fetchAlbumTracks(albumId);
      emit(
        state.copyWith(
          status: AlbumStatus.success,
          tracks: tracks,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AlbumStatus.failure,
          errorMessage: '加载专辑失败：$error',
        ),
      );
    }
  }
}

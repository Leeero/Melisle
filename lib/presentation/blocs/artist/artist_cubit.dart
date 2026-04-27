import 'package:cross_platform_music_player/application/usecases/fetch_artist_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_artist_top_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArtistCubit extends Cubit<ArtistState> {
  ArtistCubit({
    required FetchArtistAlbums fetchArtistAlbums,
    required FetchArtistTopTracks fetchArtistTopTracks,
  }) : _fetchArtistAlbums = fetchArtistAlbums,
       _fetchArtistTopTracks = fetchArtistTopTracks,
       super(const ArtistState.initial());

  final FetchArtistAlbums _fetchArtistAlbums;
  final FetchArtistTopTracks _fetchArtistTopTracks;

  Future<void> load(String artistId, {MusicArtist? seed}) async {
    emit(
      state.copyWith(
        status: ArtistStatus.loading,
        artist: seed ?? state.artist,
        errorMessage: null,
      ),
    );

    try {
      final albumsFuture = _fetchArtistAlbums(artistId);
      final tracksFuture = _fetchArtistTopTracks(artistId);
      final albums = await albumsFuture;
      final topTracks = await tracksFuture;

      emit(
        state.copyWith(
          status: ArtistStatus.success,
          albums: albums,
          topTracks: topTracks,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ArtistStatus.failure,
          errorMessage: '加载艺术家失败：$error',
        ),
      );
    }
  }
}

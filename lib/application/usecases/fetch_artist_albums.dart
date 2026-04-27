import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchArtistAlbums {
  const FetchArtistAlbums(this._repository);

  final MusicRepository _repository;

  Future<List<MusicAlbum>> call(String artistId) {
    return _repository.fetchArtistAlbums(artistId);
  }
}

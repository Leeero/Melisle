import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchArtistTopTracks {
  const FetchArtistTopTracks(this._repository);

  final MusicRepository _repository;

  Future<List<MusicTrack>> call(String artistId, {int limit = 20}) {
    return _repository.fetchArtistTopTracks(artistId, limit: limit);
  }
}

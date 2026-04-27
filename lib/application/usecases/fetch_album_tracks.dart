import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchAlbumTracks {
  const FetchAlbumTracks(this._repository);

  final MusicRepository _repository;

  Future<List<MusicTrack>> call(String albumId) {
    return _repository.fetchAlbumTracks(albumId);
  }
}

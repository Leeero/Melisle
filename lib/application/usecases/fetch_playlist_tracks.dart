import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchPlaylistTracks {
  const FetchPlaylistTracks(this._repository);

  final MusicRepository _repository;

  Future<List<MusicTrack>> call(String playlistId) {
    return _repository.fetchPlaylistTracks(playlistId);
  }
}

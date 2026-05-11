import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchPlaylistTracks {
  const FetchPlaylistTracks(this._repository);

  final MusicRepository _repository;

  Future<List<MusicTrack>> call(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) {
    return _repository.fetchPlaylistTracks(
      playlistId,
      limit: limit,
      startIndex: startIndex,
    );
  }
}

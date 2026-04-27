import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchFavoriteTracks {
  const FetchFavoriteTracks(this._repository);

  final MusicRepository _repository;

  Future<List<MusicTrack>> call({int limit = 100, int startIndex = 0}) {
    return _repository.fetchFavoriteTracks(
      limit: limit,
      startIndex: startIndex,
    );
  }
}

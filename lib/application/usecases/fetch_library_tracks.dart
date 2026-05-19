import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchLibraryTracks {
  const FetchLibraryTracks(this._repository);

  final MusicRepository _repository;

  Future<PaginatedResult<MusicTrack>> call({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _repository.fetchTracks(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }
}

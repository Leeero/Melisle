import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/domain/entities/track_sort_option.dart';
import 'package:cross_platform_music_player/domain/entities/track_filter_option.dart';

class FetchLibraryTracks {
  const FetchLibraryTracks(this._repository);

  final MusicRepository _repository;

  Future<PaginatedResult<MusicTrack>> call({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
    TrackSortOption? sortOption,
    Set<TrackFilterOption> filters = const {},
  }) {
    final repository = _repository;
    if (filters.isNotEmpty && repository is TrackFilteringRepository) {
      return (repository as TrackFilteringRepository).fetchFilteredTracks(
        filters: filters,
        sortOption: sortOption,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      );
    }
    if (sortOption != null && repository is TrackSortingRepository) {
      return (repository as TrackSortingRepository).fetchSortedTracks(
        sortOption: sortOption,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      );
    }
    return _repository.fetchTracks(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  Future<Set<TrackSortOption>> supportedSortOptions() {
    final repository = _repository;
    if (repository is TrackSortingRepository) {
      return (repository as TrackSortingRepository)
          .fetchSupportedTrackSortOptions();
    }
    return Future.value(const {});
  }

  Future<Set<TrackFilterOption>> supportedFilterOptions() {
    final repository = _repository;
    if (repository is TrackFilteringRepository) {
      return (repository as TrackFilteringRepository)
          .fetchSupportedTrackFilterOptions();
    }
    return Future.value(const {});
  }
}

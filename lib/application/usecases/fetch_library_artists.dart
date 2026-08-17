import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/artist_sort_option.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchLibraryArtists {
  const FetchLibraryArtists(this._repository);

  final MusicRepository _repository;

  Future<List<MusicArtist>> call({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
    ArtistSortOption? sortOption,
  }) {
    final repository = _repository;
    if (sortOption != null && repository is ArtistSortingRepository) {
      final sortingRepository = repository as ArtistSortingRepository;
      return sortingRepository.fetchSortedArtists(
        sortOption: sortOption,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
        genreId: genreId,
      );
    }
    return _repository.fetchArtists(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
      genreId: genreId,
    );
  }

  Future<Set<ArtistSortOption>> supportedSortOptions() {
    final repository = _repository;
    return repository is ArtistSortingRepository
        ? (repository as ArtistSortingRepository)
              .fetchSupportedArtistSortOptions()
        : Future.value(const {});
  }
}

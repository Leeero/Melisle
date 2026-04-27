import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchLibraryArtists {
  const FetchLibraryArtists(this._repository);

  final MusicRepository _repository;

  Future<List<MusicArtist>> call({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _repository.fetchArtists(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }
}

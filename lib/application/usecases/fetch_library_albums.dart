import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchLibraryAlbums {
  const FetchLibraryAlbums(this._repository);

  final MusicRepository _repository;

  Future<List<MusicAlbum>> call({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _repository.fetchAlbums(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }
}

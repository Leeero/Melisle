import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchRandomAlbums {
  const FetchRandomAlbums(this._repository);

  final MusicRepository _repository;

  Future<List<MusicAlbum>> call({int limit = 6}) {
    return _repository.fetchRandomAlbums(limit: limit);
  }
}

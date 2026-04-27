import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchLatestAlbums {
  const FetchLatestAlbums(this._repository);

  final MusicRepository _repository;

  Future<List<MusicAlbum>> call({int limit = 12}) {
    return _repository.fetchLatestAlbums(limit: limit);
  }
}

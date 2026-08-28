import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchFavoritePlaylists {
  const FetchFavoritePlaylists(this._repository);

  final PlaylistFavoritesRepository _repository;

  Future<List<MusicPlaylist>> call({int limit = 60, int startIndex = 0}) {
    return _repository.fetchFavoritePlaylists(
      limit: limit,
      startIndex: startIndex,
    );
  }
}

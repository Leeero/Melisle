import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class FetchPlaylists {
  const FetchPlaylists(this._repository);

  final MusicRepository _repository;

  Future<List<MusicPlaylist>> call({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) {
    return _repository.fetchPlaylists(
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }
}

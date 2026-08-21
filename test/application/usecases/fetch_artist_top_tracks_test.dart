import 'package:cross_platform_music_player/application/usecases/fetch_artist_top_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'FetchArtistTopTracks delegates artist id and limit to the repository',
    () async {
      final repository = _FakeMusicRepository();

      final tracks = await FetchArtistTopTracks(repository)(
        'artist-1',
        limit: 6,
      );

      expect(repository.artistId, 'artist-1');
      expect(repository.limit, 6);
      expect(tracks, hasLength(1));
    },
  );
}

class _FakeMusicRepository implements MusicRepository {
  String? artistId;
  int? limit;

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String value, {
    int limit = 20,
  }) async {
    artistId = value;
    this.limit = limit;
    return const [
      MusicTrack(
        id: 'track-1',
        title: '曲目',
        artistName: '歌手',
        albumTitle: '专辑',
        artworkUrl: '',
        duration: Duration(minutes: 3),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:cross_platform_music_player/application/usecases/fetch_artist_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_artist_top_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ArtistCubit createCubit(_FakeMusicRepository repository) => ArtistCubit(
    fetchArtistAlbums: FetchArtistAlbums(repository),
    fetchArtistTopTracks: FetchArtistTopTracks(repository),
  );

  test(
    'load exposes albums and top tracks from the same artist request',
    () async {
      final cubit = createCubit(_FakeMusicRepository());

      await cubit.load('artist-1');

      expect(cubit.state.status, ArtistStatus.success);
      expect(cubit.state.albums, hasLength(1));
      expect(cubit.state.topTracks, hasLength(1));
      expect(cubit.state.errorMessage, isNull);
    },
  );

  test('load exposes a retryable error when either request fails', () async {
    final cubit = createCubit(_FakeMusicRepository(fails: true));

    await cubit.load('artist-1');

    expect(cubit.state.status, ArtistStatus.failure);
    expect(cubit.state.errorMessage, contains('加载艺术家失败'));
  });
}

class _FakeMusicRepository implements MusicRepository {
  _FakeMusicRepository({this.fails = false});

  final bool fails;

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) async {
    if (fails) throw StateError('offline');
    return const [
      MusicAlbum(
        id: 'album-1',
        title: '专辑',
        artistName: '艺术家',
        artworkUrl: '',
        trackCount: 1,
      ),
    ];
  }

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async {
    if (fails) throw StateError('offline');
    return const [
      MusicTrack(
        id: 'track-1',
        title: '曲目',
        artistName: '艺术家',
        albumTitle: '专辑',
        artworkUrl: '',
        duration: Duration(minutes: 3),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

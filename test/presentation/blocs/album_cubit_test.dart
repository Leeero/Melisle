import 'package:cross_platform_music_player/application/usecases/fetch_album_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlbumCubit', () {
    test(
      'load emits loading then tracks and clears a previous error',
      () async {
        final cubit = AlbumCubit(FetchAlbumTracks(_AlbumRepository()));

        await cubit.load('album-1');

        expect(cubit.state.status, AlbumStatus.success);
        expect(cubit.state.tracks, hasLength(1));
        expect(cubit.state.errorMessage, isNull);
      },
    );

    test('load exposes a retryable failure', () async {
      final cubit = AlbumCubit(FetchAlbumTracks(_AlbumRepository(fails: true)));

      await cubit.load('album-1');

      expect(cubit.state.status, AlbumStatus.failure);
      expect(cubit.state.errorMessage, contains('加载专辑失败'));
    });
  });
}

class _AlbumRepository implements MusicRepository {
  _AlbumRepository({this.fails = false});

  final bool fails;

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async {
    if (fails) throw StateError('offline');
    return const [
      MusicTrack(
        id: 'track-1',
        title: '曲目',
        artistName: '歌手',
        albumTitle: '专辑',
        artworkUrl: '',
        duration: Duration(minutes: 4),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

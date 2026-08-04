import 'package:cross_platform_music_player/application/usecases/fetch_playlist_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlist_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaylistDetailCubit', () {
    test('ensureAllTracksLoaded 遇到空批次后终止', () async {
      final repo = _FakePlaylistRepository((_, {limit, startIndex = 0}) async {
        if (startIndex == 0) return _tracks(20);
        return const [];
      });
      final cubit = PlaylistDetailCubit(FetchPlaylistTracks(repo));

      await cubit.load('playlist_1');

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.limit, 20);
      expect(repo.calls.single.startIndex, 0);

      final tracks = await cubit.ensureAllTracksLoaded();

      expect(tracks.length, 20);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.isLoadingAll, isFalse);
      expect(repo.calls.length, 5);
    });

    test('fetchPlaybackQueueTracks 不修改页面状态', () async {
      final repo = _FakePlaylistRepository((_, {limit, startIndex = 0}) async {
        if (startIndex >= 60) return const [];
        return _tracks(limit ?? 20, offset: startIndex);
      });
      final cubit = PlaylistDetailCubit(FetchPlaylistTracks(repo));

      await cubit.load('playlist_1');
      final before = cubit.state;
      final emittedStates = <Object>[];
      final subscription = cubit.stream.listen(emittedStates.add);

      final tracks = await cubit.fetchPlaybackQueueTracks(maxTracks: 45);
      await subscription.cancel();

      expect(tracks.length, 45);
      expect(cubit.state, same(before));
      expect(emittedStates, isEmpty);
      expect(
        repo.calls.map((call) => call.startIndex),
        containsAll([0, 20, 40]),
      );
    });

    test('fetchPlaybackQueueTracks 遇到短页后终止', () async {
      final repo = _FakePlaylistRepository((_, {limit, startIndex = 0}) async {
        if (startIndex == 0) return _tracks(20);
        if (startIndex == 20) return _tracks(6, offset: 20);
        return const [];
      });
      final cubit = PlaylistDetailCubit(FetchPlaylistTracks(repo));

      await cubit.load('playlist_1');
      final tracks = await cubit.fetchPlaybackQueueTracks();

      expect(tracks.length, 26);
      expect(repo.calls.any((call) => call.startIndex >= 40), isFalse);
    });
  });
}

List<MusicTrack> _tracks(int count, {int offset = 0}) {
  return List.generate(count, (index) {
    final id = offset + index;
    return MusicTrack(
      id: 'track_$id',
      title: '歌曲 $id',
      artistName: '艺术家',
      albumTitle: '专辑',
      artworkUrl: '',
      duration: Duration.zero,
    );
  });
}

class _PlaylistFetchCall {
  const _PlaylistFetchCall({required this.limit, required this.startIndex});

  final int? limit;
  final int startIndex;
}

class _FakePlaylistRepository implements MusicRepository {
  _FakePlaylistRepository(this._fetchPlaylistTracks);

  final Future<List<MusicTrack>> Function(
    String playlistId, {
    int? limit,
    int startIndex,
  })
  _fetchPlaylistTracks;

  final calls = <_PlaylistFetchCall>[];

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) {
    calls.add(_PlaylistFetchCall(limit: limit, startIndex: startIndex));
    return _fetchPlaylistTracks(
      playlistId,
      limit: limit,
      startIndex: startIndex,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

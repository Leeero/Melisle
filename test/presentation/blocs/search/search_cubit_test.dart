import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/search/search_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/search/search_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onQueryChanged_emptyQuery_returnsIdleWithEmptyResults', () async {
    final repository = _FakeMusicRepository();
    final cubit = SearchCubit(repository);
    addTearDown(cubit.close);

    cubit.onQueryChanged('');

    expect(cubit.state.status, SearchStatus.idle);
    expect(cubit.state.results, SearchResults.empty);
  });

  test('submit_success_emitsSuccessWithResults', () async {
    final results = SearchResults(tracks: [_track()]);
    final repository = _FakeMusicRepository(results: results);
    final cubit = SearchCubit(repository);
    addTearDown(cubit.close);

    await cubit.submit('夜曲');

    expect(repository.queries, ['夜曲']);
    expect(cubit.state.status, SearchStatus.success);
    expect(cubit.state.results.tracks.single.title, '夜曲');
  });

  test('submit_failure_emitsFailureWithMessage', () async {
    final repository = _FakeMusicRepository(error: Exception('offline'));
    final cubit = SearchCubit(repository);
    addTearDown(cubit.close);

    await cubit.submit('失败');

    expect(cubit.state.status, SearchStatus.failure);
    expect(cubit.state.errorMessage, contains('搜索失败'));
  });

  test('submit_newerRequestWins_ignoresOlderResult', () async {
    final repository = _SlowFirstSearchRepository();
    final cubit = SearchCubit(repository);
    addTearDown(cubit.close);

    final first = cubit.submit('first');
    await cubit.submit('second');
    await first;

    expect(cubit.state.status, SearchStatus.success);
    expect(cubit.state.results.tracks.single.title, 'second');
  });

  test('retry_usesCurrentQuery', () async {
    final repository = _FakeMusicRepository(
      results: SearchResults(tracks: [_track()]),
    );
    final cubit = SearchCubit(repository);
    addTearDown(cubit.close);

    await cubit.submit('重试');
    await cubit.retry();

    expect(repository.queries, ['重试', '重试']);
    expect(cubit.state.status, SearchStatus.success);
  });

  test('restoreRecent_withDatabase_restoresNormalizedHistory', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final cubit = SearchCubit(_FakeMusicRepository(), database: database);
    addTearDown(cubit.close);

    await cubit.restoreRecent([' 夜曲 ', '', '晴天']);

    expect(cubit.state.recentQueries, ['夜曲', '晴天']);
  });
}

MusicTrack _track({String id = 'track-1', String title = '夜曲'}) {
  return MusicTrack(
    id: id,
    title: title,
    artistName: '周杰伦',
    albumTitle: '十一月的萧邦',
    artworkUrl: '',
    duration: const Duration(minutes: 4),
  );
}

class _FakeMusicRepository implements MusicRepository {
  _FakeMusicRepository({this.results = SearchResults.empty, this.error});

  final SearchResults results;
  final Object? error;
  final queries = <String>[];

  @override
  Future<SearchResults> search(String query) async {
    queries.add(query);
    final error = this.error;
    if (error != null) throw error;
    return results;
  }

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async => [];

  @override
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) async => [];

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async => const PaginatedResult(items: []);

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => [];

  @override
  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) async => [];

  @override
  Future<List<Genre>> fetchGenres() async => [];

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => [];

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async => [];

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async => [];

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) async => '';

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<void> setFavorite(String itemId, bool value) async {}

  @override
  Future<List<LyricLine>?> fetchLyrics(String trackId) async => null;

  @override
  Future<void> reportPlaybackStart(
    String trackId,
    String playSessionId,
  ) async {}

  @override
  Future<void> reportPlaybackProgress(
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  }) async {}

  @override
  Future<void> reportPlaybackStopped(
    String trackId,
    String playSessionId,
    Duration position,
  ) async {}

  @override
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) async => [];

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) async => [];

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async => [];

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) async => [];

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async => [];
}

class _SlowFirstSearchRepository extends _FakeMusicRepository {
  @override
  Future<SearchResults> search(String query) async {
    queries.add(query);
    if (query == 'first') {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return SearchResults(
      tracks: [_track(id: query, title: query)],
    );
  }
}

import 'package:cross_platform_music_player/application/usecases/fetch_playlist_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlist_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistDetailCubit extends Cubit<PlaylistDetailState> {
  PlaylistDetailCubit(this._fetchPlaylistTracks)
    : super(const PlaylistDetailState.initial());

  static const _pageSize = 20;

  final FetchPlaylistTracks _fetchPlaylistTracks;
  String? _playlistId;

  Future<void> load(String playlistId) async {
    _playlistId = playlistId;
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.status != PlaylistDetailStatus.success ||
        state.isLoadingMore ||
        !state.hasMore ||
        _playlistId == null) {
      return;
    }

    await _loadPage(reset: false);
  }

  Future<List<MusicTrack>> ensureAllTracksLoaded() async {
    final playlistId = _playlistId;
    if (playlistId == null) return state.tracks;

    emit(state.copyWith(isLoadingAll: true));
    var offset = state.tracks.length;
    var hasMore = state.hasMore;

    while (hasMore && offset < 10000) {
      final batch = await _fetchTrackBatch(playlistId, offset: offset);
      if (batch.tracks.isEmpty) {
        hasMore = false;
        break;
      }

      final combined = [...state.tracks, ...batch.tracks];
      offset = combined.length;
      hasMore = batch.hasMore;
      emit(state.copyWith(tracks: combined, hasMore: hasMore));
    }

    emit(state.copyWith(isLoadingAll: false, hasMore: hasMore));
    return state.tracks;
  }

  Future<List<MusicTrack>> fetchPlaybackQueueTracks({
    int maxTracks = 500,
  }) async {
    final playlistId = _playlistId;
    if (playlistId == null || maxTracks <= 0) return const [];

    final tracks = <MusicTrack>[];
    var offset = 0;
    var hasMore = true;

    while (hasMore && tracks.length < maxTracks) {
      final limit = maxTracks - tracks.length < _pageSize
          ? maxTracks - tracks.length
          : _pageSize;
      final page = await _fetchPlaylistTracks(
        playlistId,
        limit: limit,
        startIndex: offset,
      );
      if (page.isEmpty) break;

      tracks.addAll(page);
      offset = tracks.length;
      hasMore = page.length == limit && limit == _pageSize;
    }

    return tracks;
  }

  Future<_PlaylistTrackBatch> _fetchTrackBatch(
    String playlistId, {
    required int offset,
    int remainingLimit = 10000,
  }) async {
    final futures = <Future<List<MusicTrack>>>[];
    var requested = 0;
    for (var i = 0; i < 4 && requested < remainingLimit; i++) {
      final limit = remainingLimit - requested < _pageSize
          ? remainingLimit - requested
          : _pageSize;
      futures.add(
        _fetchPlaylistTracks(
          playlistId,
          limit: limit,
          startIndex: offset + requested,
        ),
      );
      requested += limit;
    }

    final results = await Future.wait(futures);
    final tracks = <MusicTrack>[];
    var hasMore = true;
    for (final page in results) {
      if (page.isEmpty) {
        hasMore = false;
        break;
      }
      tracks.addAll(page);
      if (page.length < _pageSize) {
        hasMore = false;
        break;
      }
    }

    return _PlaylistTrackBatch(tracks: tracks, hasMore: hasMore);
  }

  Future<void> _loadPage({required bool reset}) async {
    final playlistId = _playlistId;
    if (playlistId == null) return;

    if (reset) {
      emit(
        state.copyWith(
          status: PlaylistDetailStatus.loading,
          tracks: const [],
          hasMore: true,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } else {
      emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    }

    try {
      final tracks = await _fetchPlaylistTracks(
        playlistId,
        limit: _pageSize,
        startIndex: reset ? 0 : state.tracks.length,
      );
      emit(
        state.copyWith(
          status: PlaylistDetailStatus.success,
          tracks: reset ? tracks : [...state.tracks, ...tracks],
          hasMore: tracks.length == _pageSize,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: reset ? PlaylistDetailStatus.failure : state.status,
          isLoadingMore: false,
          errorMessage: '加载歌单详情失败：$error',
        ),
      );
    }
  }
}

class _PlaylistTrackBatch {
  const _PlaylistTrackBatch({required this.tracks, required this.hasMore});

  final List<MusicTrack> tracks;
  final bool hasMore;
}

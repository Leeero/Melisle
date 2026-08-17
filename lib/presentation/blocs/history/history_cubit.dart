import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._database) : super(const HistoryState.initial());

  static const _pageSize = 30;

  final AppDatabase _database;
  final Set<String> _seenTrackIds = <String>{};
  int _offset = 0;

  Future<void> load() async {
    _seenTrackIds.clear();
    _offset = 0;
    emit(
      state.copyWith(
        status: HistoryStatus.loading,
        tracks: const [],
        errorMessage: null,
        isLoadingMore: false,
        hasMore: false,
      ),
    );

    await _loadPage(replace: true);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    await _loadPage(replace: false);
  }

  Future<void> _loadPage({required bool replace}) async {
    final previousTracks = replace ? const <MusicTrack>[] : state.tracks;

    try {
      var hasMore = false;
      final additions = <MusicTrack>[];

      while (additions.length < _pageSize) {
        final rows = await _database.recentPlays(
          limit: _pageSize,
          offset: _offset,
        );
        _offset += rows.length;
        for (final row in rows) {
          if (_seenTrackIds.add(row.trackId)) additions.add(_toTrack(row));
        }
        if (rows.length < _pageSize) break;
        hasMore = true;
      }
      emit(
        state.copyWith(
          status: HistoryStatus.success,
          tracks: [...previousTracks, ...additions],
          errorMessage: null,
          isLoadingMore: false,
          hasMore: hasMore,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          tracks: previousTracks,
          errorMessage: '加载历史失败：$error',
          isLoadingMore: false,
        ),
      );
    }
  }

  MusicTrack _toTrack(PlayHistoryData row) {
    return MusicTrack(
      id: row.trackId,
      title: row.title,
      artistName: row.artistName ?? '未知艺术家',
      albumTitle: row.albumTitle ?? '',
      artworkUrl: row.artworkUrl ?? '',
      albumId: row.albumId,
      artistId: row.artistId,
      duration: _durationFromStoredMs(row.durationPlayedMs),
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(row.playedAtMs),
    );
  }

  Duration _durationFromStoredMs(int milliseconds) {
    if (milliseconds <= 0) return Duration.zero;
    return Duration(milliseconds: milliseconds);
  }
}

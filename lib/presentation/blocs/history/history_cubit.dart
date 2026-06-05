import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._database) : super(const HistoryState.initial());

  final AppDatabase _database;

  Future<void> load() async {
    emit(state.copyWith(status: HistoryStatus.loading, errorMessage: null));

    try {
      final rows = await _database.recentPlays(limit: 80);
      final seen = <String>{};
      final tracks = <MusicTrack>[];
      for (final row in rows) {
        if (!seen.add(row.trackId)) {
          continue;
        }
        tracks.add(_toTrack(row));
      }
      emit(
        state.copyWith(
          status: HistoryStatus.success,
          tracks: tracks,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          errorMessage: '加载历史失败：$error',
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

import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum HistoryStatus { initial, loading, success, failure }

class HistoryState {
  const HistoryState({
    required this.status,
    this.tracks = const [],
    this.errorMessage,
  });

  const HistoryState.initial() : this(status: HistoryStatus.initial);

  static const _sentinel = Object();

  final HistoryStatus status;
  final List<MusicTrack> tracks;
  final String? errorMessage;

  HistoryState copyWith({
    HistoryStatus? status,
    List<MusicTrack>? tracks,
    Object? errorMessage = _sentinel,
  }) {
    return HistoryState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

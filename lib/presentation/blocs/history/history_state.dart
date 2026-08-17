import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum HistoryStatus { initial, loading, success, failure }

class HistoryState {
  const HistoryState({
    required this.status,
    this.tracks = const [],
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  const HistoryState.initial() : this(status: HistoryStatus.initial);

  static const _sentinel = Object();

  final HistoryStatus status;
  final List<MusicTrack> tracks;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasMore;

  HistoryState copyWith({
    HistoryStatus? status,
    List<MusicTrack>? tracks,
    Object? errorMessage = _sentinel,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return HistoryState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

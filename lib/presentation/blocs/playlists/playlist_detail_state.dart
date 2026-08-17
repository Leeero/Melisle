import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum PlaylistDetailStatus { initial, loading, success, failure }

class PlaylistDetailState {
  const PlaylistDetailState({
    required this.status,
    this.tracks = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isLoadingAll = false,
    this.errorMessage,
  });

  const PlaylistDetailState.initial()
    : this(status: PlaylistDetailStatus.initial);

  static const _sentinel = Object();

  final PlaylistDetailStatus status;
  final List<MusicTrack> tracks;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isLoadingAll;
  final String? errorMessage;

  PlaylistDetailState copyWith({
    PlaylistDetailStatus? status,
    List<MusicTrack>? tracks,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isLoadingAll,
    Object? errorMessage = _sentinel,
  }) {
    return PlaylistDetailState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingAll: isLoadingAll ?? this.isLoadingAll,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

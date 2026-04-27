import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum PlaylistDetailStatus { initial, loading, success, failure }

class PlaylistDetailState {
  const PlaylistDetailState({
    required this.status,
    this.tracks = const [],
    this.errorMessage,
  });

  const PlaylistDetailState.initial()
    : this(status: PlaylistDetailStatus.initial);

  final PlaylistDetailStatus status;
  final List<MusicTrack> tracks;
  final String? errorMessage;

  PlaylistDetailState copyWith({
    PlaylistDetailStatus? status,
    List<MusicTrack>? tracks,
    String? errorMessage,
  }) {
    return PlaylistDetailState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      errorMessage: errorMessage,
    );
  }
}

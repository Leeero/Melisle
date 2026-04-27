import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum AlbumStatus { initial, loading, success, failure }

class AlbumState {
  const AlbumState({
    required this.status,
    this.tracks = const [],
    this.errorMessage,
  });

  const AlbumState.initial() : this(status: AlbumStatus.initial);

  final AlbumStatus status;
  final List<MusicTrack> tracks;
  final String? errorMessage;

  AlbumState copyWith({
    AlbumStatus? status,
    List<MusicTrack>? tracks,
    String? errorMessage,
  }) {
    return AlbumState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      errorMessage: errorMessage,
    );
  }
}

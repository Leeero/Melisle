import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  const HomeState({
    required this.status,
    this.albums = const [],
    this.recentlyPlayed = const [],
    this.mostPlayed = const [],
    this.errorMessage,
  });

  const HomeState.initial() : this(status: HomeStatus.initial);

  final HomeStatus status;
  final List<MusicAlbum> albums;
  final List<MusicTrack> recentlyPlayed;
  final List<MusicTrack> mostPlayed;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    List<MusicAlbum>? albums,
    List<MusicTrack>? recentlyPlayed,
    List<MusicTrack>? mostPlayed,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      albums: albums ?? this.albums,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      mostPlayed: mostPlayed ?? this.mostPlayed,
      errorMessage: errorMessage,
    );
  }
}

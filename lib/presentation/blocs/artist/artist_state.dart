import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum ArtistStatus { initial, loading, success, failure }

class ArtistState {
  const ArtistState({
    required this.status,
    this.artist,
    this.albums = const [],
    this.topTracks = const [],
    this.errorMessage,
  });

  const ArtistState.initial() : this(status: ArtistStatus.initial);

  final ArtistStatus status;
  final MusicArtist? artist;
  final List<MusicAlbum> albums;
  final List<MusicTrack> topTracks;
  final String? errorMessage;

  ArtistState copyWith({
    ArtistStatus? status,
    MusicArtist? artist,
    List<MusicAlbum>? albums,
    List<MusicTrack>? topTracks,
    String? errorMessage,
  }) {
    return ArtistState(
      status: status ?? this.status,
      artist: artist ?? this.artist,
      albums: albums ?? this.albums,
      topTracks: topTracks ?? this.topTracks,
      errorMessage: errorMessage,
    );
  }
}

import 'music_album.dart';
import 'music_artist.dart';
import 'music_playlist.dart';
import 'music_track.dart';

/// 跨类型搜索结果聚合。
class SearchResults {
  const SearchResults({
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  final List<MusicTrack> tracks;
  final List<MusicAlbum> albums;
  final List<MusicArtist> artists;
  final List<MusicPlaylist> playlists;

  bool get isEmpty =>
      tracks.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get totalCount =>
      tracks.length + albums.length + artists.length + playlists.length;

  SearchResults copyWith({
    List<MusicTrack>? tracks,
    List<MusicAlbum>? albums,
    List<MusicArtist>? artists,
    List<MusicPlaylist>? playlists,
  }) {
    return SearchResults(
      tracks: tracks ?? this.tracks,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
    );
  }

  static const empty = SearchResults();
}

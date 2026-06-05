import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum LibraryStatus { initial, loading, success, failure }

enum LibraryFilter { tracks, albums, artists, playlists, favorites }

class LibraryState {
  const LibraryState({
    required this.status,
    this.currentFilter = LibraryFilter.tracks,
    this.searchQuery = '',
    this.tracks = const [],
    this.totalTrackCount,
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.genres = const [],
    this.selectedGenreId,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  const LibraryState.initial({
    LibraryFilter currentFilter = LibraryFilter.tracks,
  }) : this(status: LibraryStatus.initial, currentFilter: currentFilter);

  static const _sentinel = Object();

  final LibraryStatus status;
  final LibraryFilter currentFilter;
  final String searchQuery;
  final List<MusicTrack> tracks;
  final int? totalTrackCount;
  final List<MusicAlbum> albums;
  final List<MusicArtist> artists;
  final List<MusicPlaylist> playlists;
  final List<Genre> genres;
  final String? selectedGenreId;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isCurrentFilterEmpty {
    return switch (currentFilter) {
      LibraryFilter.tracks => tracks.isEmpty,
      LibraryFilter.albums => albums.isEmpty,
      LibraryFilter.artists => artists.isEmpty,
      LibraryFilter.playlists => playlists.isEmpty,
      LibraryFilter.favorites => true,
    };
  }

  int get currentFilterCount {
    return switch (currentFilter) {
      LibraryFilter.tracks => tracks.length,
      LibraryFilter.albums => albums.length,
      LibraryFilter.artists => artists.length,
      LibraryFilter.playlists => playlists.length,
      LibraryFilter.favorites => 0,
    };
  }

  LibraryState copyWith({
    LibraryStatus? status,
    LibraryFilter? currentFilter,
    String? searchQuery,
    List<MusicTrack>? tracks,
    int? totalTrackCount,
    List<MusicAlbum>? albums,
    List<MusicArtist>? artists,
    List<MusicPlaylist>? playlists,
    List<Genre>? genres,
    Object? selectedGenreId = _sentinel,
    bool? hasMore,
    bool? isLoadingMore,
    Object? errorMessage = _sentinel,
  }) {
    return LibraryState(
      status: status ?? this.status,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      tracks: tracks ?? this.tracks,
      totalTrackCount: totalTrackCount ?? this.totalTrackCount,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
      genres: genres ?? this.genres,
      selectedGenreId: identical(selectedGenreId, _sentinel)
          ? this.selectedGenreId
          : selectedGenreId as String?,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

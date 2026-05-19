import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum LibraryStatus { initial, loading, success, failure }

enum LibraryFilter { tracks, albums, artists }

class LibraryState {
  const LibraryState({
    required this.status,
    this.currentFilter = LibraryFilter.tracks,
    this.searchQuery = '',
    this.tracks = const [],
    this.totalTrackCount,
    this.albums = const [],
    this.artists = const [],
    this.genres = const [],
    this.selectedGenreId,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  const LibraryState.initial() : this(status: LibraryStatus.initial);

  static const _sentinel = Object();

  final LibraryStatus status;
  final LibraryFilter currentFilter;
  final String searchQuery;
  final List<MusicTrack> tracks;
  final int? totalTrackCount;
  final List<MusicAlbum> albums;
  final List<MusicArtist> artists;
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
    };
  }

  int get currentFilterCount {
    return switch (currentFilter) {
      LibraryFilter.tracks => tracks.length,
      LibraryFilter.albums => albums.length,
      LibraryFilter.artists => artists.length,
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

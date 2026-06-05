import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';

enum PlaylistsStatus { initial, loading, success, failure }

class PlaylistsState {
  const PlaylistsState({
    required this.status,
    this.searchQuery = '',
    this.allPlaylists = const [],
    this.playlists = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  const PlaylistsState.initial() : this(status: PlaylistsStatus.initial);

  static const _sentinel = Object();

  final PlaylistsStatus status;
  final String searchQuery;
  final List<MusicPlaylist> allPlaylists;
  final List<MusicPlaylist> playlists;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isFiltering => searchQuery.trim().isNotEmpty;

  PlaylistsState copyWith({
    PlaylistsStatus? status,
    String? searchQuery,
    List<MusicPlaylist>? allPlaylists,
    List<MusicPlaylist>? playlists,
    bool? hasMore,
    bool? isLoadingMore,
    Object? errorMessage = _sentinel,
  }) {
    return PlaylistsState(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      allPlaylists: allPlaylists ?? this.allPlaylists,
      playlists: playlists ?? this.playlists,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

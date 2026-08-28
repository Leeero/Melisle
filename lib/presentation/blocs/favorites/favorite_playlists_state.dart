import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';

enum FavoritePlaylistsStatus { initial, loading, success, failure }

class FavoritePlaylistsState {
  const FavoritePlaylistsState({
    required this.status,
    this.playlists = const [],
    this.loadedCount = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  const FavoritePlaylistsState.initial()
    : this(status: FavoritePlaylistsStatus.initial);

  static const _sentinel = Object();

  final FavoritePlaylistsStatus status;
  final List<MusicPlaylist> playlists;
  final int loadedCount;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  FavoritePlaylistsState copyWith({
    FavoritePlaylistsStatus? status,
    List<MusicPlaylist>? playlists,
    int? loadedCount,
    bool? hasMore,
    bool? isLoadingMore,
    Object? errorMessage = _sentinel,
  }) => FavoritePlaylistsState(
    status: status ?? this.status,
    playlists: playlists ?? this.playlists,
    loadedCount: loadedCount ?? this.loadedCount,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: identical(errorMessage, _sentinel)
        ? this.errorMessage
        : errorMessage as String?,
  );
}

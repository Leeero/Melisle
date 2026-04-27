import 'package:cross_platform_music_player/domain/entities/music_track.dart';

enum FavoritesListStatus { initial, loading, success, failure }

class FavoritesListState {
  const FavoritesListState({
    required this.status,
    this.tracks = const [],
    this.loadedCount = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  const FavoritesListState.initial()
    : this(status: FavoritesListStatus.initial);

  static const _sentinel = Object();

  final FavoritesListStatus status;
  final List<MusicTrack> tracks;
  final int loadedCount;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  FavoritesListState copyWith({
    FavoritesListStatus? status,
    List<MusicTrack>? tracks,
    int? loadedCount,
    bool? hasMore,
    bool? isLoadingMore,
    Object? errorMessage = _sentinel,
  }) {
    return FavoritesListState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      loadedCount: loadedCount ?? this.loadedCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

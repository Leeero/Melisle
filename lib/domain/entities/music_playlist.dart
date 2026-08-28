class MusicPlaylist {
  const MusicPlaylist({
    required this.id,
    required this.name,
    required this.artworkUrl,
    this.trackCount = 0,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String artworkUrl;
  final int trackCount;
  final bool isFavorite;

  MusicPlaylist copyWith({
    String? id,
    String? name,
    String? artworkUrl,
    int? trackCount,
    bool? isFavorite,
  }) {
    return MusicPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      trackCount: trackCount ?? this.trackCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

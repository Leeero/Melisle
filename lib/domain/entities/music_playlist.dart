class MusicPlaylist {
  const MusicPlaylist({
    required this.id,
    required this.name,
    required this.artworkUrl,
    this.trackCount = 0,
  });

  final String id;
  final String name;
  final String artworkUrl;
  final int trackCount;
}

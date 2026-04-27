class MusicArtist {
  const MusicArtist({
    required this.id,
    required this.name,
    required this.artworkUrl,
    this.albumCount = 0,
    this.trackCount = 0,
  });

  final String id;
  final String name;
  final String artworkUrl;
  final int albumCount;
  final int trackCount;
}

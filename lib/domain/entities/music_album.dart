class MusicAlbum {
  const MusicAlbum({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artworkUrl,
    required this.trackCount,
    this.year,
    this.artistId,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String artistName;
  final String artworkUrl;
  final int trackCount;
  final int? year;

  /// 主歌手 ID（用于跳转歌手页）。
  final String? artistId;

  /// 当前用户是否收藏此专辑。
  final bool isFavorite;

  MusicAlbum copyWith({
    String? id,
    String? title,
    String? artistName,
    String? artworkUrl,
    int? trackCount,
    int? year,
    String? artistId,
    bool? isFavorite,
  }) {
    return MusicAlbum(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      trackCount: trackCount ?? this.trackCount,
      year: year ?? this.year,
      artistId: artistId ?? this.artistId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.artworkUrl,
    required this.duration,
    this.albumId,
    this.artistId,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayedAt,
    this.bitRate,
    this.codec,
    this.container,
  });

  final String id;
  final String title;
  final String artistName;
  final String albumTitle;
  final String artworkUrl;
  final Duration duration;

  /// 所属专辑 ID（用于跳转专辑详情页）。
  final String? albumId;

  /// 主歌手 ID（用于跳转歌手页）。
  final String? artistId;

  /// 当前用户是否将此歌曲加入收藏。
  final bool isFavorite;

  /// 当前用户播放次数（来自 Emby UserData.PlayCount）。
  final int playCount;

  /// 最后一次播放时间（来自 Emby UserData.LastPlayedDate）。
  final DateTime? lastPlayedAt;

  /// 原始比特率（bps），来自 MediaSources[0].Bitrate 或 MediaStreams。
  final int? bitRate;

  /// 编码，例如 flac / aac / mp3。
  final String? codec;

  /// 容器格式，例如 flac / m4a / mp3。
  final String? container;

  MusicTrack copyWith({
    String? id,
    String? title,
    String? artistName,
    String? albumTitle,
    String? artworkUrl,
    Duration? duration,
    String? albumId,
    String? artistId,
    bool? isFavorite,
    int? playCount,
    DateTime? lastPlayedAt,
    int? bitRate,
    String? codec,
    String? container,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumTitle: albumTitle ?? this.albumTitle,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      duration: duration ?? this.duration,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      bitRate: bitRate ?? this.bitRate,
      codec: codec ?? this.codec,
      container: container ?? this.container,
    );
  }
}

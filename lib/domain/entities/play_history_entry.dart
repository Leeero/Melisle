/// 本地播放历史记录条目。
class PlayHistoryEntry {
  const PlayHistoryEntry({
    required this.trackId,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.artworkUrl,
    required this.playedAt,
    required this.durationPlayed,
  });

  final String trackId;
  final String title;
  final String artistName;
  final String albumTitle;
  final String artworkUrl;
  final DateTime playedAt;

  /// 实际播放时长（用于播放上报 / 本地统计）。
  final Duration durationPlayed;
}

import 'package:cross_platform_music_player/domain/entities/music_track.dart';

/// 一个下载任务的实时状态。
enum DownloadJobStatus { pending, running, completed, failed, canceled }

class DownloadJob {
  const DownloadJob({
    required this.track,
    required this.status,
    this.received = 0,
    this.total = 0,
    this.errorMessage,
  });

  final MusicTrack track;
  final DownloadJobStatus status;
  final int received;
  final int total;
  final String? errorMessage;

  double? get progress {
    if (total <= 0) return null;
    return (received / total).clamp(0, 1).toDouble();
  }

  DownloadJob copyWith({
    DownloadJobStatus? status,
    int? received,
    int? total,
    String? errorMessage,
  }) {
    return DownloadJob(
      track: track,
      status: status ?? this.status,
      received: received ?? this.received,
      total: total ?? this.total,
      errorMessage: errorMessage,
    );
  }
}

class DownloadsState {
  const DownloadsState({
    this.jobs = const {},
    this.completedTrackIds = const {},
  });

  /// 目前在进行中的任务（按 trackId 索引）。
  final Map<String, DownloadJob> jobs;

  /// 已经下载完毕（落在 drift Downloads 表里）的 trackId 集合，供 UI 快速查询。
  final Set<String> completedTrackIds;

  DownloadsState copyWith({
    Map<String, DownloadJob>? jobs,
    Set<String>? completedTrackIds,
  }) {
    return DownloadsState(
      jobs: jobs ?? this.jobs,
      completedTrackIds: completedTrackIds ?? this.completedTrackIds,
    );
  }
}

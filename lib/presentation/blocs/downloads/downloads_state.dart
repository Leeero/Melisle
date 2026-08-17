import 'package:cross_platform_music_player/domain/entities/music_track.dart';

/// 一个下载任务的实时状态。
enum DownloadJobStatus { pending, running, completed, failed, canceled }

enum DownloadDirectoryValidation { idle, saving, valid, invalid }

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
    this.missingTrackIds = const {},
    this.downloadDirectoryPath = '',
    this.customDownloadDirectoryPath = '',
    this.cachedBytes = 0,
    this.removedStaleRecords = 0,
    this.removedPartialFiles = 0,
    this.directoryValidation = DownloadDirectoryValidation.idle,
    this.directoryValidationMessage,
  });

  /// 目前在进行中的任务（按 trackId 索引）。
  final Map<String, DownloadJob> jobs;

  /// 已经下载完毕（落在 drift Downloads 表里）的 trackId 集合，供 UI 快速查询。
  final Set<String> completedTrackIds;

  /// 已存在记录但本地文件不可用的曲目；保留记录以便界面说明并允许删除。
  final Set<String> missingTrackIds;

  /// 当前有效下载目录。为空表示尚未加载完成。
  final String downloadDirectoryPath;

  /// 用户自定义下载目录。为空表示使用默认目录。
  final String customDownloadDirectoryPath;

  /// 已核验下载目录内的实际文件占用。
  final int cachedBytes;

  /// 最近一次加载时清理掉的失效数据库下载记录数量。
  final int removedStaleRecords;

  /// 最近一次加载时清理掉的残留临时下载文件数量。
  final int removedPartialFiles;

  final DownloadDirectoryValidation directoryValidation;
  final String? directoryValidationMessage;

  bool get usesDefaultDownloadDirectory => customDownloadDirectoryPath.isEmpty;

  DownloadsState copyWith({
    Map<String, DownloadJob>? jobs,
    Set<String>? completedTrackIds,
    Set<String>? missingTrackIds,
    String? downloadDirectoryPath,
    String? customDownloadDirectoryPath,
    int? cachedBytes,
    int? removedStaleRecords,
    int? removedPartialFiles,
    DownloadDirectoryValidation? directoryValidation,
    String? directoryValidationMessage,
  }) {
    return DownloadsState(
      jobs: jobs ?? this.jobs,
      completedTrackIds: completedTrackIds ?? this.completedTrackIds,
      missingTrackIds: missingTrackIds ?? this.missingTrackIds,
      downloadDirectoryPath:
          downloadDirectoryPath ?? this.downloadDirectoryPath,
      customDownloadDirectoryPath:
          customDownloadDirectoryPath ?? this.customDownloadDirectoryPath,
      cachedBytes: cachedBytes ?? this.cachedBytes,
      removedStaleRecords: removedStaleRecords ?? this.removedStaleRecords,
      removedPartialFiles: removedPartialFiles ?? this.removedPartialFiles,
      directoryValidation: directoryValidation ?? this.directoryValidation,
      directoryValidationMessage:
          directoryValidationMessage ?? this.directoryValidationMessage,
    );
  }
}

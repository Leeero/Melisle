import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/cache/audio_cache_manager.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

/// 串行下载队列：同一时刻只跑一个任务，失败继续下一个。
///
/// 不处理断点续传、不做并发；定位为最小可用的离线缓存。
class DownloadsCubit extends Cubit<DownloadsState> {
  DownloadsCubit({
    required MusicRepository repository,
    required AppDatabase database,
    required AudioCacheManager cacheManager,
  }) : _repository = repository,
       _database = database,
       _cacheManager = cacheManager,
       super(const DownloadsState());

  final MusicRepository _repository;
  final AppDatabase _database;
  final AudioCacheManager _cacheManager;

  final Queue<MusicTrack> _pending = Queue();
  final Map<String, CancelToken> _cancelTokens = {};
  bool _running = false;

  static const _kDownloadDirectoryPath = 'download_directory_path';

  /// 初始化：从数据库加载已有下载。
  Future<void> load() async {
    try {
      final customDirectoryPath = _normalizeDirectoryPath(
        await _database.readSetting(_kDownloadDirectoryPath),
      );
      _cacheManager.setCustomDirectoryPath(customDirectoryPath);
      final effectiveDirectory = await _resolveCurrentDirectory();
      final removedPartialFiles = await _cacheManager.deletePartialFiles();
      final cleanup = await _cleanupDownloads();
      emit(
        state.copyWith(
          downloadDirectoryPath: effectiveDirectory.path,
          customDownloadDirectoryPath: customDirectoryPath ?? '',
          cachedBytes: cleanup.cachedBytes,
          removedStaleRecords: cleanup.removedStaleRecords,
          removedPartialFiles: removedPartialFiles,
          completedTrackIds: {
            for (final r in cleanup.rows)
              if (r.status == 0 && !cleanup.missingTrackIds.contains(r.trackId))
                r.trackId,
          },
          missingTrackIds: cleanup.missingTrackIds,
        ),
      );
    } catch (error, stack) {
      developer.log(
        'DownloadsCubit.load failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  bool isDownloaded(String trackId) =>
      state.completedTrackIds.contains(trackId);

  /// 把一个曲目加入队列。
  Future<void> enqueue(MusicTrack track) async {
    if (state.completedTrackIds.contains(track.id)) return;
    if (state.jobs.containsKey(track.id)) return;

    _pending.add(track);
    final jobs = Map<String, DownloadJob>.from(state.jobs);
    jobs[track.id] = DownloadJob(
      track: track,
      status: DownloadJobStatus.pending,
    );
    emit(state.copyWith(jobs: jobs));

    if (!_running) {
      unawaited(_runLoop());
    }
  }

  Future<void> cancel(String trackId) async {
    _cancelTokens[trackId]?.cancel('canceled by user');
    _pending.removeWhere((t) => t.id == trackId);

    final jobs = Map<String, DownloadJob>.from(state.jobs);
    final job = jobs[trackId];
    if (job != null && job.status != DownloadJobStatus.running) {
      jobs.remove(trackId);
      emit(state.copyWith(jobs: jobs));
    }
  }

  Future<void> retry(String trackId) async {
    final job = state.jobs[trackId];
    if (job == null || job.status != DownloadJobStatus.failed) return;
    final jobs = Map<String, DownloadJob>.from(state.jobs)..remove(trackId);
    emit(state.copyWith(jobs: jobs));
    await enqueue(job.track);
  }

  Future<void> remove(String trackId) async {
    final record = await _database.findDownload(trackId);
    var removedBytes = 0;
    if (record != null) {
      removedBytes = await _cacheManager.fileSize(record.filePath);
      await _cacheManager.delete(record.filePath);
      await _database.deleteDownload(trackId);
    }

    final completed = Set<String>.from(state.completedTrackIds)
      ..remove(trackId);
    final missing = Set<String>.from(state.missingTrackIds)..remove(trackId);
    final jobs = Map<String, DownloadJob>.from(state.jobs)..remove(trackId);
    emit(
      state.copyWith(
        completedTrackIds: completed,
        missingTrackIds: missing,
        jobs: jobs,
        cachedBytes: (state.cachedBytes - removedBytes)
            .clamp(0, 1 << 62)
            .toInt(),
      ),
    );
  }

  Future<void> setDownloadDirectoryPath(String rawPath) async {
    final customDirectoryPath = _normalizeDirectoryPath(rawPath);
    if (customDirectoryPath != null && !p.isAbsolute(customDirectoryPath)) {
      throw ArgumentError('请输入绝对路径');
    }

    final previousPath = state.customDownloadDirectoryPath;
    emit(
      state.copyWith(
        directoryValidation: DownloadDirectoryValidation.saving,
        directoryValidationMessage: null,
      ),
    );
    if (customDirectoryPath != null) {
      try {
        await _validateDirectory(customDirectoryPath);
      } on Object catch (error) {
        emit(
          state.copyWith(
            directoryValidation: DownloadDirectoryValidation.invalid,
            directoryValidationMessage: _directoryErrorMessage(error),
          ),
        );
        rethrow;
      }
    }
    _cacheManager.setCustomDirectoryPath(customDirectoryPath);

    try {
      final dir = await _cacheManager.resolveDirectory();
      await _database.writeSetting(
        _kDownloadDirectoryPath,
        customDirectoryPath ?? '',
      );
      final removedPartialFiles = await _cacheManager.deletePartialFiles();
      final cleanup = await _cleanupDownloads();
      emit(
        state.copyWith(
          downloadDirectoryPath: dir.path,
          customDownloadDirectoryPath: customDirectoryPath ?? '',
          cachedBytes: cleanup.cachedBytes,
          removedStaleRecords: cleanup.removedStaleRecords,
          removedPartialFiles: removedPartialFiles,
          completedTrackIds: {
            for (final r in cleanup.rows)
              if (r.status == 0 && !cleanup.missingTrackIds.contains(r.trackId))
                r.trackId,
          },
          missingTrackIds: cleanup.missingTrackIds,
          directoryValidation: DownloadDirectoryValidation.valid,
        ),
      );
    } catch (_) {
      _cacheManager.setCustomDirectoryPath(
        previousPath.isEmpty ? null : previousPath,
      );
      emit(
        state.copyWith(
          directoryValidation: DownloadDirectoryValidation.invalid,
          directoryValidationMessage: '目录不可写或当前平台不支持该位置',
        ),
      );
      rethrow;
    }
  }

  /// 查询某曲目的本地文件路径（若存在）。
  Future<String?> resolveLocalPath(String trackId) async {
    final record = await _database.findDownload(trackId);
    if (record == null || record.status != 0) return null;
    if (!await File(record.filePath).exists()) {
      final completed = Set<String>.from(state.completedTrackIds)
        ..remove(trackId);
      final missing = Set<String>.from(state.missingTrackIds)..add(trackId);
      emit(
        state.copyWith(
          completedTrackIds: completed,
          missingTrackIds: missing,
          cachedBytes: await _cacheManager.directorySize(),
        ),
      );
      return null;
    }
    return record.filePath;
  }

  Future<void> _runLoop() async {
    if (_running) return;
    _running = true;

    try {
      while (_pending.isNotEmpty) {
        final track = _pending.removeFirst();
        await _runOne(track);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _runOne(MusicTrack track) async {
    final cancelToken = CancelToken();
    _cancelTokens[track.id] = cancelToken;

    _updateJob(track.id, (j) => j.copyWith(status: DownloadJobStatus.running));

    try {
      final url = await _repository.getStreamUrl(
        track.id,
        quality: AudioQuality.auto,
      );

      final container = (track.container ?? '').isNotEmpty
          ? track.container!
          : _guessContainer(url);

      final file = await _cacheManager.download(
        trackId: track.id,
        url: url,
        container: container,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          _updateJob(
            track.id,
            (j) => j.copyWith(received: received, total: total),
          );
        },
      );

      final size = await file.length();
      await _database.upsertDownload(
        DownloadsCompanion.insert(
          trackId: track.id,
          filePath: file.path,
          fileSize: Value(size),
          container: Value(container),
          bitrate: Value(track.bitRate),
          title: track.title,
          artistName: Value(track.artistName),
          albumTitle: Value(track.albumTitle),
          artworkUrl: Value(track.artworkUrl),
          downloadedAtMs: DateTime.now().millisecondsSinceEpoch,
          status: const Value(0),
        ),
      );

      final completed = Set<String>.from(state.completedTrackIds)
        ..add(track.id);
      final missing = Set<String>.from(state.missingTrackIds)..remove(track.id);
      final jobs = Map<String, DownloadJob>.from(state.jobs)..remove(track.id);
      emit(
        state.copyWith(
          jobs: jobs,
          completedTrackIds: completed,
          missingTrackIds: missing,
          cachedBytes: state.cachedBytes + size,
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _updateJob(
          track.id,
          (j) => j.copyWith(status: DownloadJobStatus.canceled),
          removeAfter: true,
        );
      } else {
        _updateJob(
          track.id,
          (j) => j.copyWith(
            status: DownloadJobStatus.failed,
            errorMessage: e.message,
          ),
        );
      }
    } catch (error) {
      _updateJob(
        track.id,
        (j) => j.copyWith(
          status: DownloadJobStatus.failed,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _cancelTokens.remove(track.id);
    }
  }

  void _updateJob(
    String trackId,
    DownloadJob Function(DownloadJob) mutate, {
    bool removeAfter = false,
  }) {
    final jobs = Map<String, DownloadJob>.from(state.jobs);
    final existing = jobs[trackId];
    if (existing == null) return;
    final updated = mutate(existing);
    if (removeAfter) {
      jobs.remove(trackId);
    } else {
      jobs[trackId] = updated;
    }
    emit(state.copyWith(jobs: jobs));
  }

  Future<_DownloadCleanupResult> _cleanupDownloads() async {
    final rows = await _database.allDownloads();
    final verifiedRows = <Download>[];
    final missingTrackIds = <String>{};
    var removedStaleRecords = 0;
    var cachedBytes = 0;

    for (final row in rows) {
      if (row.status != 0) {
        verifiedRows.add(row);
        continue;
      }
      final size = await _cacheManager.fileSize(row.filePath);
      if (size <= 0) {
        missingTrackIds.add(row.trackId);
        verifiedRows.add(row);
        continue;
      }
      cachedBytes += size;
      var verifiedRow = row;
      if (row.fileSize != size) {
        await _database.upsertDownload(
          DownloadsCompanion.insert(
            trackId: row.trackId,
            filePath: row.filePath,
            fileSize: Value(size),
            container: Value(row.container),
            bitrate: Value(row.bitrate),
            title: row.title,
            artistName: Value(row.artistName),
            albumTitle: Value(row.albumTitle),
            artworkUrl: Value(row.artworkUrl),
            downloadedAtMs: row.downloadedAtMs,
            status: Value(row.status),
          ),
        );
        final updated = await _database.findDownload(row.trackId);
        if (updated != null) {
          verifiedRow = updated;
        }
      }
      verifiedRows.add(verifiedRow);
    }

    return _DownloadCleanupResult(
      rows: verifiedRows,
      cachedBytes: cachedBytes,
      removedStaleRecords: removedStaleRecords,
      missingTrackIds: missingTrackIds,
    );
  }

  String _guessContainer(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot < 0) return 'bin';
    final ext = path.substring(dot + 1);
    return ext.isEmpty ? 'bin' : ext.toLowerCase();
  }

  Future<Directory> _resolveCurrentDirectory() async {
    try {
      return await _cacheManager.resolveDirectory();
    } catch (error, stack) {
      developer.log(
        'DownloadsCubit.resolveDirectory failed',
        error: error,
        stackTrace: stack,
      );
      _cacheManager.setCustomDirectoryPath(null);
      await _database.writeSetting(_kDownloadDirectoryPath, '');
      return _cacheManager.resolveDirectory();
    }
  }

  String? _normalizeDirectoryPath(String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return p.normalize(trimmed);
  }

  Future<void> _validateDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw ArgumentError('目录不存在');
    }
    final probe = File(p.join(path, '.melisle-write-probe'));
    try {
      await probe.writeAsBytes(const [0], flush: true);
    } on FileSystemException {
      throw ArgumentError('目录没有写入权限');
    } finally {
      if (await probe.exists()) await probe.delete();
    }
  }

  String _directoryErrorMessage(Object error) {
    if (error is ArgumentError) return error.message?.toString() ?? '目录无效';
    return '目录不可用，请确认路径和写入权限';
  }

  @override
  Future<void> close() {
    for (final token in _cancelTokens.values) {
      if (!token.isCancelled) token.cancel();
    }
    return super.close();
  }
}

class _DownloadCleanupResult {
  const _DownloadCleanupResult({
    required this.rows,
    required this.cachedBytes,
    required this.removedStaleRecords,
    required this.missingTrackIds,
  });

  final List<Download> rows;
  final int cachedBytes;
  final int removedStaleRecords;
  final Set<String> missingTrackIds;
}

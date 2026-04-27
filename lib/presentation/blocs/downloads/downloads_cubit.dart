import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/cache/audio_cache_manager.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  /// 初始化：从数据库加载已有下载。
  Future<void> load() async {
    try {
      final rows = await _database.allDownloads();
      emit(
        state.copyWith(
          completedTrackIds: {
            for (final r in rows)
              if (r.status == 0) r.trackId,
          },
        ),
      );
    } catch (error, stack) {
      debugPrint('DownloadsCubit.load 失败：$error\n$stack');
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

  Future<void> remove(String trackId) async {
    final record = await _database.findDownload(trackId);
    if (record != null) {
      await _cacheManager.delete(record.filePath);
      await _database.deleteDownload(trackId);
    }

    final completed = Set<String>.from(state.completedTrackIds)
      ..remove(trackId);
    final jobs = Map<String, DownloadJob>.from(state.jobs)..remove(trackId);
    emit(state.copyWith(completedTrackIds: completed, jobs: jobs));
  }

  /// 查询某曲目的本地文件路径（若存在）。
  Future<String?> resolveLocalPath(String trackId) async {
    final record = await _database.findDownload(trackId);
    if (record == null || record.status != 0) return null;
    if (!await File(record.filePath).exists()) {
      // 文件被外部清理，顺手清理记录。
      await _database.deleteDownload(trackId);
      final completed = Set<String>.from(state.completedTrackIds)
        ..remove(trackId);
      emit(state.copyWith(completedTrackIds: completed));
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
      final jobs = Map<String, DownloadJob>.from(state.jobs)..remove(track.id);
      emit(state.copyWith(jobs: jobs, completedTrackIds: completed));
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

  String _guessContainer(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot < 0) return 'bin';
    final ext = path.substring(dot + 1);
    return ext.isEmpty ? 'bin' : ext.toLowerCase();
  }

  @override
  Future<void> close() {
    for (final token in _cancelTokens.values) {
      if (!token.isCancelled) token.cancel();
    }
    return super.close();
  }
}

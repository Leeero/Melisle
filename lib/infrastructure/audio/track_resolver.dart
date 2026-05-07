import 'dart:io';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:just_audio/just_audio.dart';

/// 把 [MusicTrack] 解析为可供 `just_audio` 消费的 [AudioSource]。
///
/// 解析顺序：
/// 1. 若本地下载库有该 track 的已完成下载文件，优先返回 `file://` 源。
/// 2. 否则走 [MusicRepository.getStreamUrl] 拿到流媒体 URL。
///
/// 这里刻意不缓存 [AudioSource] —— just_audio 的 AudioSource 一旦被加载进 player，
/// 再次复用同一个实例在某些平台会触发奇怪的状态（例如 duration 为 null）。每次播放
/// 时现做现用更安全，也更符合主流播放器的做法。
final class TrackResolver {
  TrackResolver({required MusicRepository repository, AppDatabase? database})
    : _repository = repository,
      _database = database;

  final MusicRepository _repository;
  final AppDatabase? _database;

  Future<AudioSource> resolve(
    MusicTrack track, {
    AudioQuality quality = AudioQuality.auto,
  }) async {
    final localPath = await _resolveLocalDownload(track.id);
    if (localPath != null) {
      return AudioSource.uri(Uri.file(localPath), tag: track);
    }
    final streamUrl = await _repository.getStreamUrl(
      track.id,
      quality: quality,
    );
    return AudioSource.uri(
      Uri.parse(streamUrl),
      // Emby / Subsonic 的鉴权信息已经内嵌在 URL 中，额外 headers 只会让
      // just_audio 走本地代理链路，提升 HTTPS / 重定向场景下的握手失败概率。
      tag: track,
    );
  }

  Future<String?> _resolveLocalDownload(String trackId) async {
    final db = _database;
    if (db == null) return null;
    try {
      final record = await db.findDownload(trackId);
      if (record == null || record.status != 0) return null;
      if (!await File(record.filePath).exists()) {
        await db.deleteDownload(trackId);
        return null;
      }
      return record.filePath;
    } catch (_) {
      return null;
    }
  }
}

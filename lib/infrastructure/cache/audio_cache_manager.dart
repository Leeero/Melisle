import 'dart:io';

import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 负责把一个 stream URL 下载到本地文件。
///
/// 单例无状态：不维护队列，不负责重试；上层 DownloadsCubit 控制并发与失败策略。
class AudioCacheManager {
  AudioCacheManager({Dio? dio, Future<Directory> Function()? defaultDirectory})
    : _dio = dio ?? Dio(),
      _defaultDirectory = defaultDirectory;

  final Dio _dio;
  final Future<Directory> Function()? _defaultDirectory;
  String? _customDirectoryPath;

  void setCustomDirectoryPath(String? path) {
    final normalized = path?.trim();
    _customDirectoryPath = normalized == null || normalized.isEmpty
        ? null
        : normalized;
  }

  /// 返回默认下载目录（应用支持目录下的 `downloads/`）。
  Future<Directory> resolveDefaultDirectory() async {
    final injected = _defaultDirectory;
    if (injected != null) return injected();
    final root = await getApplicationSupportDirectory();
    return Directory(p.join(root.path, 'downloads'));
  }

  /// 返回下载目录。若用户配置了自定义目录，优先使用自定义目录。
  Future<Directory> resolveDirectory() async {
    final dir = _customDirectoryPath == null
        ? await resolveDefaultDirectory()
        : Directory(_customDirectoryPath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<int> fileSize(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return 0;
    return file.length();
  }

  Future<int> directorySize() async {
    final dir = await resolveDirectory();
    var totalBytes = 0;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes;
  }

  Future<int> deletePartialFiles() async {
    final dir = await resolveDirectory();
    var deleted = 0;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.part')) continue;
      await entity.delete();
      deleted += 1;
    }
    return deleted;
  }

  /// 下载一个 URL 到 `trackId.container` 文件。
  ///
  /// [onProgress] 接收 [received, total]；total 可能为 -1（服务端未给 Content-Length）。
  /// 返回最终文件。
  Future<File> download({
    required String trackId,
    required String url,
    required String container,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await resolveDirectory();
    final ext = container.isEmpty ? 'bin' : container;
    final filePath = p.join(dir.path, '$trackId.$ext');
    final tmpPath = '$filePath.part';

    await _dio.download(
      url,
      tmpPath,
      cancelToken: cancelToken,
      options: Options(
        headers: const {'User-Agent': AppConstants.httpUserAgent},
        responseType: ResponseType.stream,
      ),
      onReceiveProgress: onProgress,
    );

    final tmp = File(tmpPath);
    final finalFile = File(filePath);
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await tmp.rename(filePath);
    return finalFile;
  }

  Future<void> delete(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

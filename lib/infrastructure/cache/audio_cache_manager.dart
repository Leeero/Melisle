import 'dart:io';

import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 负责把一个 stream URL 下载到本地文件。
///
/// 单例无状态：不维护队列，不负责重试；上层 DownloadsCubit 控制并发与失败策略。
class AudioCacheManager {
  AudioCacheManager({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// 返回下载目录（应用支持目录下的 `downloads/`）。首次调用时会创建。
  Future<Directory> resolveDirectory() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'downloads'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
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

/// 播放音质档位。
///
/// - [auto]：按服务器配置透传原文件（不做转码）。
/// - [lossless]：无损，限定 FLAC/ALAC 容器，允许最高码率。
/// - [high]：320kbps 左右的有损。
/// - [medium]：192kbps 左右的有损。
/// - [low]：128kbps 以内，适合弱网或流量受限场景。
enum AudioQuality {
  auto,
  lossless,
  high,
  medium,
  low;

  /// UI 标签（简体中文）。
  String get label {
    switch (this) {
      case AudioQuality.auto:
        return '原始音质';
      case AudioQuality.lossless:
        return '无损';
      case AudioQuality.high:
        return '高品质 (320 kbps)';
      case AudioQuality.medium:
        return '标准 (192 kbps)';
      case AudioQuality.low:
        return '省流 (128 kbps)';
    }
  }

  /// 用于在 drift / settings 中持久化的字符串 key。
  String get storageKey {
    switch (this) {
      case AudioQuality.auto:
        return 'auto';
      case AudioQuality.lossless:
        return 'lossless';
      case AudioQuality.high:
        return 'high';
      case AudioQuality.medium:
        return 'medium';
      case AudioQuality.low:
        return 'low';
    }
  }

  static AudioQuality fromStorageKey(String? key) {
    switch (key) {
      case 'lossless':
        return AudioQuality.lossless;
      case 'high':
        return AudioQuality.high;
      case 'medium':
        return AudioQuality.medium;
      case 'low':
        return AudioQuality.low;
      case 'auto':
      default:
        return AudioQuality.auto;
    }
  }
}

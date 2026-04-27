import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';

/// 音质档位对应的 Emby /Audio/{id}/universal 查询参数。
class AudioQualityProfile {
  const AudioQualityProfile({
    required this.container,
    required this.audioCodec,
    required this.maxBitrate,
  });

  final String container;
  final String audioCodec;

  /// 单位 bps（不是 kbps）。
  final int maxBitrate;

  static AudioQualityProfile forQuality(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.lossless:
        return const AudioQualityProfile(
          container: 'flac',
          audioCodec: 'flac',
          maxBitrate: 1411000,
        );
      case AudioQuality.high:
        return const AudioQualityProfile(
          container: 'mp3',
          audioCodec: 'mp3',
          maxBitrate: 320000,
        );
      case AudioQuality.medium:
        return const AudioQualityProfile(
          container: 'mp3',
          audioCodec: 'mp3',
          maxBitrate: 192000,
        );
      case AudioQuality.low:
        return const AudioQualityProfile(
          container: 'mp3',
          audioCodec: 'mp3',
          maxBitrate: 128000,
        );
      case AudioQuality.auto:
        return const AudioQualityProfile(
          container: 'mp3',
          audioCodec: 'mp3',
          maxBitrate: 320000,
        );
    }
  }
}

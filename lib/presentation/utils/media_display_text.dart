import 'package:cross_platform_music_player/domain/entities/music_artist.dart';

abstract final class MediaDisplayText {
  static final RegExp _invisibleCharacters = RegExp(
    r'[\u200B-\u200D\u2060-\u2064\uFEFF]',
  );
  static final RegExp _whitespace = RegExp(r'\s+');

  static String trackTitle(String? value) => _clean(value, '未知歌曲');

  static String albumTitle(String? value) => _clean(value, '未知专辑');

  static String artistName(String? value) => _clean(value, '未知艺术家');

  static String playlistName(String? value) => _clean(value, '未命名歌单');

  static String artistItemCount(MusicArtist artist) {
    if (artist.albumCount > 0) return '${artist.albumCount} 张专辑';
    if (artist.trackCount > 0) return '${artist.trackCount} 首歌曲';
    return '暂无统计';
  }

  static String metadata(String? value, {String fallback = '未知信息'}) =>
      _clean(value, fallback);

  static String year(int? value) =>
      value == null || value <= 0 ? '未知年份' : value.toString();

  static String _clean(String? value, String fallback) {
    final normalized = (value ?? '')
        .replaceAll(_invisibleCharacters, '')
        .replaceAll(_whitespace, ' ')
        .trim();
    if (normalized.isEmpty ||
        normalized.contains('\uFFFD') ||
        _looksLikeLatin1Mojibake(normalized)) {
      return fallback;
    }
    return normalized;
  }

  static bool _looksLikeLatin1Mojibake(String value) {
    var latin1ExtendedCount = 0;
    var commonLetterOrDigitCount = 0;
    for (final rune in value.runes) {
      if (rune >= 0x00C0 && rune <= 0x00FF) {
        latin1ExtendedCount++;
      }
      if ((rune >= 0x30 && rune <= 0x39) ||
          (rune >= 0x41 && rune <= 0x5A) ||
          (rune >= 0x61 && rune <= 0x7A) ||
          (rune >= 0x3400 && rune <= 0x9FFF)) {
        commonLetterOrDigitCount++;
      }
    }
    return latin1ExtendedCount >= 2 && commonLetterOrDigitCount < 3;
  }
}

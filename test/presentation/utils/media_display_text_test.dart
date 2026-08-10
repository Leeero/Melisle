import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaDisplayText', () {
    test('清除零宽字符并合并空白', () {
      expect(MediaDisplayText.trackTitle('  夜\u200B曲\n Live  '), '夜曲 Live');
    });

    test('空内容使用对应中文占位文案', () {
      expect(MediaDisplayText.trackTitle(' \uFEFF '), '未知歌曲');
      expect(MediaDisplayText.trackTitle('\u2062'), '未知歌曲');
      expect(MediaDisplayText.albumTitle(''), '未知专辑');
      expect(MediaDisplayText.artistName(null), '未知艺术家');
      expect(MediaDisplayText.playlistName('  '), '未命名播放列表');
    });

    test('包含 Unicode 替换字符的损坏文本不进入界面', () {
      expect(MediaDisplayText.trackTitle('歌曲���标题'), '未知歌曲');
      expect(MediaDisplayText.albumTitle('专辑�名称'), '未知专辑');
      expect(MediaDisplayText.trackTitle('¿¦ÄÉË¹'), '未知歌曲');
      expect(
        MediaDisplayText.artistName('Yannick Nézet-Séguin'),
        'Yannick Nézet-Séguin',
      );
    });

    test('未知或非法年份使用稳定文案', () {
      expect(MediaDisplayText.year(null), '未知年份');
      expect(MediaDisplayText.year(0), '未知年份');
      expect(MediaDisplayText.year(2026), '2026');
    });
  });
}

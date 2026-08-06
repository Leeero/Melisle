import 'package:cross_platform_music_player/shared/theme/app_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBreakpoints', () {
    test('classifies boundary widths', () {
      expect(AppBreakpoints.fromWidth(767), AppLayoutSize.compact);
      expect(AppBreakpoints.fromWidth(768), AppLayoutSize.medium);
      expect(AppBreakpoints.fromWidth(1079), AppLayoutSize.medium);
      expect(AppBreakpoints.fromWidth(1080), AppLayoutSize.desktop);
      expect(AppBreakpoints.fromWidth(1439), AppLayoutSize.desktop);
      expect(AppBreakpoints.fromWidth(1440), AppLayoutSize.largeDesktop);
    });

    test('desktop-only capabilities start at 1080', () {
      expect(AppBreakpoints.usesDesktopShellWidth(1079), isFalse);
      expect(AppBreakpoints.usesTrackTableWidth(1079), isFalse);
      expect(AppBreakpoints.usesDesktopShellWidth(1080), isTrue);
      expect(AppBreakpoints.usesTrackTableWidth(1080), isTrue);
    });

    test('album grid density scales without affecting compact widths', () {
      expect(AppBreakpoints.adaptiveAlbumGridCount(390), 2);
      expect(AppBreakpoints.adaptiveAlbumGridCount(768), 3);
      expect(AppBreakpoints.adaptiveAlbumGridCount(1080), 5);
      expect(AppBreakpoints.adaptiveAlbumGridCount(1440), 7);
    });
  });
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['STITCH_GOLDEN_TESTS'] == 'true';

  test('收藏 Stitch 基准归档字节保持一致', () async {
    if (!enabled) return;
    for (final entry in _referenceHashes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(sha256.convert(await file.readAsBytes()).toString(), entry.value);
    }
  });

  test('收藏实际截图覆盖五个固定视口', () async {
    if (!enabled) return;
    for (final size in _viewports) {
      for (final brightness in ['light', 'dark']) {
        for (final scale in [1.0, 1.3]) {
          final path =
              'design-reference/screenshots/actual/'
              'favorites-${size.width.toInt()}x${size.height.toInt()}-'
              '$brightness-scale-$scale.png';
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: path);
          expect(await _imageSize(file), size, reason: path);
        }
      }
    }
  });
}

Future<ui.Size> _imageSize(File file) async {
  final codec = await ui.instantiateImageCodec(await file.readAsBytes());
  final frame = await codec.getNextFrame();
  final size = ui.Size(
    frame.image.width.toDouble(),
    frame.image.height.toDouble(),
  );
  frame.image.dispose();
  codec.dispose();
  return size;
}

const _referenceHashes = {
  'design-reference/screenshots/reference/favorites/V3-13.png':
      'e5b3c5f5a2d5b42a3661f46ea14c0fb78fd3449f93453651ca567a6a2c0762ad',
  'design-reference/screenshots/reference/favorites/V3-37.png':
      '763e7d85733e0112a60f6a3d2d3cace1cd88b2cd879018988f1cb9784430b212',
  'design-reference/screenshots/reference/favorites/V3-42.png':
      'eb7fa64eef591f150731c6fa5a67df60e91fc253cd15a4e401c22d4c494a4e49',
  'design-reference/screenshots/reference/favorites/V3-47.png':
      'f78ebaa3af1c8c6705fa511affe58378baac1bdfdb7a3742fd3754b7dd8feb6b',
  'design-reference/screenshots/reference/favorites/V3-56.png':
      'e5f53a0f4b775f07d10c687307d787665c00440b6f935f201fd48b9fe41b6bf4',
};

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

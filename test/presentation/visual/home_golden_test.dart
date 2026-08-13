import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['STITCH_GOLDEN_TESTS'] == 'true';
  test('首页 Stitch 基准归档字节保持一致', () async {
    if (!enabled) return;
    for (final entry in _referenceHashes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(sha256.convert(await file.readAsBytes()).toString(), entry.value);
    }
  });
  test('首页实际截图覆盖五个固定视口', () async {
    if (!enabled) return;
    for (final size in _viewports) {
      for (final brightness in ['light', 'dark']) {
        for (final scale in [1.0, 1.3]) {
          final path =
              'design-reference/screenshots/actual/'
              'home-${size.width.toInt()}x${size.height.toInt()}-'
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
  'design-reference/screenshots/reference/v3-02-original-2560x2048.png':
      'f182435bdf9f0e3684a3a5e2f884d0d0850877e56b3f20a93eb2ee69843ec983',
  'design-reference/screenshots/reference/v3-03-original-780x1802.png':
      '4291fd876caaf523d1844c8bebee57c2a02cc7c59a1d9f09f14d8175ecc577e8',
  'design-reference/screenshots/reference/v3-27-original-2560x2048.png':
      '237182dfc2480320f19a0f2a85ad9cb4e1886670b6fd881547c4e66d7912d49b',
  'design-reference/screenshots/reference/v3-28-original-780x1768.png':
      '26c59293f85faaed3eff68b2b2f3de2d4bf2c65c3ec98fd0aedda1636ae9509d',
  'design-reference/screenshots/reference/v3-46-original-2560x4068.png':
      'e9cd662fa5025bd4b82ffd8fb9cfcdd7a59aafe3d1ba8a4b219ed360574386f2',
  'design-reference/screenshots/reference/v3-56-original-2560x2510.png':
      'e5f53a0f4b775f07d10c687307d787665c00440b6f935f201fd48b9fe41b6bf4',
};

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

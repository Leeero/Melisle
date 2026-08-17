import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['STITCH_GOLDEN_TESTS'] == 'true';

  test('播放历史 Stitch 基准归档字节保持一致', () async {
    if (!enabled) return;
    for (final entry in _referenceHashes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(sha256.convert(await file.readAsBytes()).toString(), entry.value);
    }
  });

  test('播放历史实际截图覆盖五个固定视口', () async {
    if (!enabled) return;
    for (final size in _viewports) {
      for (final brightness in ['light', 'dark']) {
        for (final scale in [1.0, 1.3]) {
          final path =
              'design-reference/screenshots/actual/'
              'history-${size.width.toInt()}x${size.height.toInt()}-'
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
  'design-reference/screenshots/reference/V3-14.png':
      'f5f79a9dfb1374397db28a5dd5b9928577f656547a06416b9cbd244faec578b6',
  'design-reference/screenshots/reference/V3-38.png':
      '08f48efe81466121c5783df930cac50e3d3ba9a4dad616ca23009b37ba9a0360',
  'design-reference/screenshots/reference/V3-42.png':
      'eb7fa64eef591f150731c6fa5a67df60e91fc253cd15a4e401c22d4c494a4e49',
  'design-reference/screenshots/reference/V3-47.png':
      'f78ebaa3af1c8c6705fa511affe58378baac1bdfdb7a3742fd3754b7dd8feb6b',
  'design-reference/screenshots/reference/V3-56.png':
      'e5f53a0f4b775f07d10c687307d787665c00440b6f935f201fd48b9fe41b6bf4',
};

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['STITCH_GOLDEN_TESTS'] == 'true';

  test('自定义媒体来源 Stitch 基准归档字节保持一致', () async {
    if (!enabled) return;
    for (final entry in _referenceHashes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(sha256.convert(await file.readAsBytes()).toString(), entry.value);
    }
  });

  test('自定义媒体来源实际截图覆盖固定视口', () async {
    if (!enabled) return;
    for (final size in _viewports) {
      for (final brightness in ['light', 'dark']) {
        for (final scale in [1.0, 1.3]) {
          final path =
              'design-reference/screenshots/actual/'
              'custom-media-sources-${size.width.toInt()}x${size.height.toInt()}-'
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
  'design-reference/screenshots/reference/v3-25-original-2560x2048.png':
      'a7d21f0aa067ecc525bb6f1b4c2c9af17b29d88157432eac345897cfabb645be',
  'design-reference/screenshots/reference/v3-26-original-780x1768.png':
      'c95f516cd78952f15859aca5a309ea560c81d46c001488aa87d6d71758d76121',
  'design-reference/screenshots/reference/v3-53-original-2560x2048.png':
      'c1ea3faddcf5ec3b0c5c74f63c51184d5a47df02eede8f2619d623d97d8a96d3',
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

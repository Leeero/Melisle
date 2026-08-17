import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['STITCH_GOLDEN_TESTS'] == 'true';

  test('播放队列 Stitch 基准归档字节保持一致', () async {
    if (!enabled) return;
    for (final entry in _referenceHashes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(sha256.convert(await file.readAsBytes()).toString(), entry.value);
    }
  });

  test('播放队列桌面与移动截图覆盖固定视口和主题', () async {
    if (!enabled) return;
    for (final size in _viewports) {
      for (final brightness in ['light', 'dark']) {
        for (final scale in [1.0, 1.3]) {
          final layout = size.width < 768 ? 'mobile' : 'desktop';
          final path =
              'design-reference/screenshots/actual/'
              'queue-$layout-${size.width.toInt()}x${size.height.toInt()}-'
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
  'design-reference/screenshots/reference/v3-19.png':
      'af610f413b36c341e7ba08fb2278f72de8df085f559be9caf5f3aebb6c10d598',
  'design-reference/screenshots/reference/v3-20.png':
      'f3a898ac2c5652fc816eea24b4bbd3cd7445cfec0c9b56494a7df8c80a6347b2',
  'design-reference/screenshots/reference/v3-41.png':
      'b840fdd79a33fa8cf5f5355ff2fa5e2328f603aa4ac91daa21b77b16c8946ba5',
  'design-reference/screenshots/reference/v3-56.png':
      'e5f53a0f4b775f07d10c687307d787665c00440b6f935f201fd48b9fe41b6bf4',
};

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

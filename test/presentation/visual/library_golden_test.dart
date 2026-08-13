import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['STITCH_GOLDEN_TESTS'] == 'true';

  test('媒体库 Stitch 基准归档字节保持一致', () async {
    if (!enabled) return;
    for (final entry in _referenceHashes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(sha256.convert(await file.readAsBytes()).toString(), entry.value);
    }
  });

  test('媒体库实际截图覆盖五个固定视口', () async {
    if (!enabled) return;
    for (final size in _viewports) {
      for (final brightness in ['light', 'dark']) {
        for (final scale in [1.0, 1.3]) {
          final path =
              'design-reference/screenshots/actual/'
              'library-${size.width.toInt()}x${size.height.toInt()}-'
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
  'design-reference/screenshots/reference/v3-07-original-2560x2048.png':
      '6f3ba3c515d9b30fbfdc7a3624045cf5f619d1d6346a419bdd4fc2c450dc2907',
  'design-reference/screenshots/reference/v3-08-original-780x1768.png':
      '0dc764ee72db07ced65ab683ee21ecfc26eb1f3ad1b8a87965f05a94c4202b03',
  'design-reference/screenshots/reference/v3-29-original-2560x2048.png':
      '411d9ffafbfaa8d2d577d6324bdd6b74083d53507ae22119c089a19d2b91fc14',
  'design-reference/screenshots/reference/v3-30-original-780x1768.png':
      'c009c0db622e99a308be44fb76358d93ed1effc689911a3893c7035de9bdde6a',
  'design-reference/screenshots/reference/v3-31-original-2560x2048.png':
      'ac80ce563f9caaa1f4326f8095cb279154743ffbd3ef4c9fe4d6fbb2baafba35',
  'design-reference/screenshots/reference/v3-32-original-780x1768.png':
      '2192fa86a1745bd65ff7face63831372c25ca847a9452723ecfda1aeb8ab1c27',
  'design-reference/screenshots/reference/v3-42-original-2560x2550.png':
      'f25e281d59a29a1ccb36a1c7bc1ea95ce0b0b3ee9648d37e70cfbd832a95f6c8',
  'design-reference/screenshots/reference/v3-56-original-2560x2510.png':
      'e5f53a0f4b775f07d10c687307d787665c00440b6f935f201fd48b9fe41b6bf4',
  'design-reference/screenshots/reference/v3-57-original-2560x2048.png':
      'a8d501105ce8f35f06c182c82eb6a23d15673a4a2e82a542db0ba52657d84837',
};

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

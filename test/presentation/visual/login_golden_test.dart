import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['STITCH_GOLDEN_TESTS'] == 'true';

  test('login Stitch reference archives keep their verified bytes', () async {
    if (!enabled) return;

    for (final entry in _referenceHashes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(
        sha256.convert(await file.readAsBytes()).toString(),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('login Light and Dark captures use fixed viewports', () async {
    if (!enabled) return;

    for (final entry in _actualSizes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(await _imageSize(file), entry.value, reason: entry.key);
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
  'design-reference/screenshots/reference/v3-04-original-780x1768.png':
      '93b8749f0ec8b612f3ab4e6a68393e482c6e2e0bff1c2829d1d1eb2802fe6ccb',
  'design-reference/screenshots/reference/v3-33-original-2560x2048.png':
      '1f5c04c9f7f4fc7f20cf379f5b42aabf62c622e61990373fdb87d7512e7efdc2',
  'design-reference/screenshots/reference/v3-34-original-2560x2048.png':
      '99c02605d039ce706df6d597ed3b1f9abc53f317ce36d64e93852dd96d887f26',
  'design-reference/screenshots/reference/v3-53-original-2560x2048.png':
      '611202ce8b1dde859a4a2bbc40ca7334e256007baa22d9dd73a9178de0dbbbef',
  'design-reference/screenshots/reference/v3-56-original-2560x2510.png':
      'e5f53a0f4b775f07d10c687307d787665c00440b6f935f201fd48b9fe41b6bf4',
};

const _actualSizes = {
  'design-reference/screenshots/actual/login-desktop-light-1440x900.png':
      ui.Size(1440, 900),
  'design-reference/screenshots/actual/login-desktop-dark-1440x900.png':
      ui.Size(1440, 900),
  'design-reference/screenshots/actual/login-mobile-light-390x844-scale-1.3.png':
      ui.Size(390, 844),
  'design-reference/screenshots/actual/login-mobile-dark-390x844-scale-1.3.png':
      ui.Size(390, 844),
};

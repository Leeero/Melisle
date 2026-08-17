import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['STITCH_GOLDEN_TESTS'] == 'true';

  test(
    'Stitch App Shell reference archives keep their verified bytes',
    () async {
      if (!enabled) return;

      for (final entry in _referenceHashes.entries) {
        final file = File(entry.key);
        expect(file.existsSync(), isTrue, reason: entry.key);
        expect(
          sha256.convert(await file.readAsBytes()).toString(),
          entry.value,
        );
      }
    },
  );

  test('App Shell fixed viewport captures have canonical dimensions', () async {
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
  'design-reference/screenshots/reference/v3-43-perfected-original-2560x3558.png':
      '853bffae8e385a9a058dd164dd3c1531c8f639d43239c29e6bb00e3c4748c29b',
  'design-reference/screenshots/reference/v3-44-original-2560x2960.png':
      'eda7916c7121cff567248e93293ebc708b37486b82922c7cf9a07951e7cea858',
  'design-reference/screenshots/reference/v3-45-original-2560x2048.png':
      'e30926322c186dff2a63777bbb9e04aebbaa1f0c6fe2c28fb695aa4fc49eeb99',
  'design-reference/screenshots/reference/v3-46-original-2560x4068.png':
      'e9cd662fa5025bd4b82ffd8fb9cfcdd7a59aafe3d1ba8a4b219ed360574386f2',
  'design-reference/screenshots/reference/v3-56-original-2560x2510.png':
      'e5f53a0f4b775f07d10c687307d787665c00440b6f935f201fd48b9fe41b6bf4',
  'design-reference/screenshots/reference/v3-52-original-2560x2048.png':
      '61cd598d26012bdb53a2da73a58ef283a0010582e73701572983d757d96fe4b3',
};

const _actualSizes = {
  'design-reference/screenshots/actual/app-shell-375x812-visible.png': ui.Size(
    375,
    812,
  ),
  'design-reference/screenshots/actual/app-shell-390x844-hidden.png': ui.Size(
    390,
    844,
  ),
  'design-reference/screenshots/actual/app-shell-390x844-visible.png': ui.Size(
    390,
    844,
  ),
  'design-reference/screenshots/actual/app-shell-768x900.png': ui.Size(
    768,
    900,
  ),
  'design-reference/screenshots/actual/app-shell-1080x900-expanded.png':
      ui.Size(1080, 900),
  'design-reference/screenshots/actual/app-shell-1080x900-collapsed.png':
      ui.Size(1080, 900),
  'design-reference/screenshots/actual/app-shell-1440x900-collapsed.png':
      ui.Size(1440, 900),
};

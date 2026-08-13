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
      'c07c95fbd11c4538e15945ff895e2614fe4a3a592b7f8bead57ec1042104138f',
  'design-reference/screenshots/reference/v3-44-original-2560x2960.png':
      'fbc6ca8abe618e70b96866f8fdb3c8d39512a6fc3b6bc9af7fca5a620a5df5a2',
  'design-reference/screenshots/reference/v3-45-original-2560x2048.png':
      'e8b84523ff641a887dc1fa45730a3edce49668b720fe4f3a350cffb433d294f3',
  'design-reference/screenshots/reference/v3-46-original-2560x4068.png':
      'e9cd662fa5025bd4b82ffd8fb9cfcdd7a59aafe3d1ba8a4b219ed360574386f2',
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

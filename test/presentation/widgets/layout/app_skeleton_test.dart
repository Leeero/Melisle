import 'package:cross_platform_music_player/presentation/widgets/layout/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('骨架屏切换减少动态效果时复用同一个 ticker', (tester) async {
    Future<void> pumpSkeleton({required bool disableAnimations}) {
      return tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(
              disableAnimations: disableAnimations,
            ),
            child: Scaffold(body: AppSkeleton.grid(count: 1)),
          ),
        ),
      );
    }

    await pumpSkeleton(disableAnimations: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await pumpSkeleton(disableAnimations: true);
    expect(tester.takeException(), isNull);

    await pumpSkeleton(disableAnimations: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}

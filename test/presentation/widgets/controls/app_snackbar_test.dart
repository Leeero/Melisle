import 'dart:ui' as ui;

import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('移动端操作提示紧凑显示在底部导航上方并支持撤销', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const ui.Size(390, 844);
    tester.view.devicePixelRatio = 1;
    var undone = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => AppSnackBar.show(
                  context,
                  '已取消收藏',
                  actionLabel: '撤销',
                  onAction: () => undone = true,
                ),
                child: const Text('显示提示'),
              ),
            ),
          ),
          bottomNavigationBar: const SizedBox(
            key: ValueKey('bottom-navigation'),
            height: 80,
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示提示'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('已取消收藏'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('撤销'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byType(SnackBar)).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const ValueKey('bottom-navigation'))).dy,
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, '撤销'));
    await tester.pump();
    expect(undone, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已取消收藏'), findsNothing);
  });

  testWidgets('移动端失败提示使用错误状态而不是成功状态', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const ui.Size(390, 844);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => AppSnackBar.show(
                context,
                '操作失败，请重试',
                tone: AppSnackBarTone.error,
              ),
              child: const Text('显示错误'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示错误'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).elevation, 0);
  });
}

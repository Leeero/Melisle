import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';

void main() {
  testWidgets('AppOptionTile keeps touch target and handles disabled state', (
    tester,
  ) async {
    var selected = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppOptionTile<String>(
                title: '播放音质',
                value: 'quality',
                groupValue: 'none',
                showRadio: false,
                onSelected: (value) => selected = value,
              ),
              AppOptionTile<String>(
                title: '已下载',
                value: 'downloaded',
                groupValue: 'none',
                showRadio: false,
                enabled: false,
                onSelected: (value) => selected = value,
              ),
            ],
          ),
        ),
      ),
    );

    final enabledTile = find.text('播放音质');
    final disabledTile = find.text('已下载');

    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: enabledTile,
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          )
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(enabledTile);
    expect(selected, 'quality');

    await tester.tap(disabledTile);
    expect(selected, 'quality');
  });
}

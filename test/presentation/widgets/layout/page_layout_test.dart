import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('桌面窄内容区将较宽的头部操作区堆叠到标题下方', (tester) async {
    const trailingKey = Key('header-trailing');

    tester.view.physicalSize = const Size(960, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 684,
              child: AppPageHeader(
                title: '歌单',
                description: '30 个歌单',
                titleMaxWidth: 260,
                trailing: SizedBox(
                  key: trailingKey,
                  width: 420,
                  height: 46,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final titleBottom = tester.getBottomRight(find.text('歌单')).dy;
    final trailingTop = tester.getTopLeft(find.byKey(trailingKey)).dy;
    expect(trailingTop, greaterThan(titleBottom));
  });
}

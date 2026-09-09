import 'dart:ui';

import 'package:cross_platform_music_player/presentation/widgets/controls/app_text_tabs.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/continue_listening.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/mobile_track_row.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile track row keeps selection semantics and 48dp action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        MobileTrackRow(
          title: '一首名字非常非常长的中文歌曲用于验证布局不会溢出',
          subtitle: '一个同样很长的艺术家与专辑信息',
          selected: true,
          onTap: () async {},
          leading: const SizedBox.square(dimension: 24),
          trailing: SizedBox.square(
            dimension: 48,
            child: IconButton(
              tooltip: '更多操作',
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ),
        ),
      ),
    );

    final row = find.byType(MobileTrackRow);
    expect(tester.getSemantics(row).label, contains('播放《'));
    expect(
      tester.getSemantics(row).getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(tester.getSize(find.byTooltip('更多操作')), const Size(48, 48));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('continue listening clamps progress and exposes primary action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ContinueListening(
          title: '夜曲',
          subtitle: '周杰伦',
          artworkUrl: '',
          artwork: const SizedBox.square(dimension: 72),
          progress: 2,
          position: const Duration(seconds: 10),
          duration: const Duration(minutes: 3, seconds: 44),
          isPlaying: false,
          onOpen: () {},
          onTogglePlayback: () {},
        ),
      ),
    );

    expect(find.text('继续聆听'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '继续播放',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
  });

  testWidgets('compact text tabs retain a 48dp target', (tester) async {
    await tester.pumpWidget(
      _app(
        AppTextTabs<int>(
          items: const [
            AppTextTabItem(value: 0, label: '歌曲'),
            AppTextTabItem(value: 1, label: '专辑'),
          ],
          selectedValue: 0,
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.getSize(find.text('歌曲')).height, lessThanOrEqualTo(48));
    final inkWell = find.ancestor(
      of: find.text('歌曲'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(inkWell).height, greaterThanOrEqualTo(48));
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(child: SizedBox(width: 390, child: child)),
    ),
  );
}

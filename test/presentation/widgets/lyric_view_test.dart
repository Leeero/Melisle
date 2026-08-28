import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/presentation/widgets/lyric_view.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('highlights the line controlled by currentIndex', (tester) async {
    var tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: LyricView(
              lines: _lyrics,
              currentIndex: 1,
              onLineTap: (index) => tappedIndex = index,
              showCurrentLineButton: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final activeStyle = DefaultTextStyle.of(
      tester.element(find.text('现在我只想 要逃离')),
    ).style;
    expect(activeStyle.color, AppTheme.dark().lyricHighlight);

    await tester.tap(find.text('所谓的规矩'));
    expect(tappedIndex, 2);
  });

  testWidgets('shows a return-to-current button after user scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: LyricView(
              lines: _longLyrics,
              currentIndex: 8,
              showCurrentLineButton: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('定位到当前歌词'), findsNothing);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -80));
    await tester.pump();

    expect(find.byTooltip('定位到当前歌词'), findsOneWidget);
  });

  testWidgets('allows long lyric lines to use natural height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: LyricView(
              lines: _wrappedLyrics,
              currentIndex: 1,
              maxTextWidth: 120,
              showCurrentLineButton: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shortHeight = tester
        .getRect(find.text(_wrappedLyrics.first.text))
        .height;
    final longHeight = tester.getRect(find.text(_wrappedLyrics[1].text)).height;

    expect(longHeight, greaterThan(shortHeight));
  });

  testWidgets('keeps the active wrapped lyric line in view', (tester) async {
    final lyrics = List<LyricLine>.generate(
      20,
      (index) => LyricLine(
        start: Duration(seconds: index * 4),
        text: '第 $index 句很长很长的歌词，用于验证变高行不会让当前播放歌词离开可视区域。',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 240,
            child: LyricView(
              lines: lyrics,
              currentIndex: 16,
              maxTextWidth: 180,
              showCurrentLineButton: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final activeLine = tester.getRect(find.text(lyrics[16].text));
    expect(activeLine.top, greaterThanOrEqualTo(viewport.top));
    expect(activeLine.bottom, lessThanOrEqualTo(viewport.bottom));
  });

  testWidgets('scrolls after lyrics and current index update together', (
    tester,
  ) async {
    var lines = List<LyricLine>.of(_longLyrics);
    var currentIndex = 1;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return LyricView(
                  lines: lines,
                  currentIndex: currentIndex,
                  showCurrentLineButton: false,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    updateHost(() {
      lines = List<LyricLine>.of(_longLyrics);
      currentIndex = 14;
    });
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final activeLine = tester.getRect(find.text(_longLyrics[14].text));
    expect(activeLine.top, greaterThanOrEqualTo(viewport.top));
    expect(activeLine.bottom, lessThanOrEqualTo(viewport.bottom));
  });
}

const _lyrics = [
  LyricLine(start: Duration(seconds: 30), text: '压得我喘不过气'),
  LyricLine(start: Duration(seconds: 37), text: '现在我只想 要逃离'),
  LyricLine(start: Duration(seconds: 38), text: '所谓的规矩'),
];

final _longLyrics = List<LyricLine>.generate(
  18,
  (index) => LyricLine(
    start: Duration(seconds: index * 4),
    text: '第 $index 句歌词，用于测试滚动恢复',
  ),
);

const _wrappedLyrics = [
  LyricLine(start: Duration.zero, text: '短句'),
  LyricLine(
    start: Duration(seconds: 4),
    text: '这是一句很长很长的歌词，需要在较窄的歌词区域里自然换行展示，不能被固定行高裁切',
  ),
];

import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inline link hover stays transparent and has no underline', (
    tester,
  ) async {
    late ButtonStyle style;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            style = AppActionButtonStyle.link(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const hovered = <WidgetState>{WidgetState.hovered};
    expect(style.backgroundColor?.resolve(hovered), Colors.transparent);
    expect(
      style.textStyle?.resolve(hovered)?.decoration,
      TextDecoration.none,
    );
    expect(style.mouseCursor?.resolve(hovered), SystemMouseCursors.click);
    expect(
      style.mouseCursor?.resolve({WidgetState.disabled}),
      SystemMouseCursors.basic,
    );
  });

  testWidgets('custom action buttons do not add hover surfaces or borders', (
    tester,
  ) async {
    late ButtonStyle textStyle;
    late ButtonStyle iconStyle;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            textStyle = AppActionButtonStyle.text(context);
            iconStyle = AppActionButtonStyle.icon(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const hovered = <WidgetState>{WidgetState.hovered};
    expect(textStyle.backgroundColor?.resolve(hovered), Colors.transparent);
    expect(iconStyle.backgroundColor?.resolve(hovered), Colors.transparent);
    expect(iconStyle.side?.resolve(hovered), BorderSide.none);
    expect(iconStyle.mouseCursor?.resolve(hovered), SystemMouseCursors.click);
  });
}

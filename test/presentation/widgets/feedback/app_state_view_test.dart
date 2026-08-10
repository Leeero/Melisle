import 'package:cross_platform_music_player/presentation/widgets/feedback/app_state_view.dart';
import 'package:cross_platform_music_player/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('加载状态在深浅主题与字体缩放下保持语义和布局稳定', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final brightness in Brightness.values) {
      for (final size in const [Size(390, 844), Size(1280, 900)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.3),
                disableAnimations: true,
              ),
              child: const Scaffold(
                body: AppLoadingView(
                  title: '正在加载媒体库',
                  description: '加载完成后会自动显示。',
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.label == '正在加载媒体库',
          ),
          findsOneWidget,
        );
        expect(find.text('加载完成后会自动显示。'), findsOneWidget);
      }
    }
  });

  testWidgets('消息状态暴露标题语义并保留可操作入口', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppBodyStateView.message(
            message: '加载失败',
            description: '请检查网络连接后重试。',
            icon: Icons.wifi_off_rounded,
            action: FilledButton(
              onPressed: () => retried = true,
              child: const Text('重新加载'),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '加载失败',
      ),
      findsOneWidget,
    );
    expect(find.text('请检查网络连接后重试。'), findsOneWidget);

    final action = find.widgetWithText(FilledButton, '重新加载');
    expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    await tester.tap(action);
    expect(retried, isTrue);
  });

  testWidgets('分页失败状态提供统一语义和重试入口', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppPaginationFooter(
            status: AppPaginationStatus.failed,
            errorMessage: '加载更多失败，请稍后重试。',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == '加载更多失败，请稍后重试。',
      ),
      findsOneWidget,
    );
    expect(find.text('无法连接到服务器'), findsOneWidget);

    final retry = find.widgetWithText(OutlinedButton, '重试');
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));
    await tester.tap(retry);
    expect(retried, isTrue);
  });
}

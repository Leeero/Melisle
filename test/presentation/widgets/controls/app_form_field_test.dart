import 'package:cross_platform_music_player/presentation/widgets/controls/app_form_field.dart';
import 'package:cross_platform_music_player/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HTTP URL 校验拒绝无协议地址', () {
    expect(AppFormField.validateHttpUrl('melisle.local'), isNotNull);
    expect(AppFormField.validateHttpUrl('htp://melisle.local'), isNotNull);
    expect(AppFormField.validateHttpUrl('https://melisle.local'), isNull);
  });

  testWidgets('表单控件提供标签、错误、只读和禁用语义', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              AppFormField(
                label: '服务器地址',
                errorText: 'URL 格式无效，必须以 http:// 或 https:// 开头',
                prefixIcon: Icons.link_rounded,
              ),
              const AppFormField(
                label: '系统默认缓存目录',
                readOnly: true,
                enabled: false,
                helperText: '系统分配路径不可修改',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('服务器地址'), findsOneWidget);
    expect(find.textContaining('URL 格式无效'), findsOneWidget);
    expect(find.text('系统分配路径不可修改'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

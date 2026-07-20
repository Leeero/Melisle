import 'package:flutter/material.dart';

/// 统一的 SnackBar 反馈。
///
/// 使用场景：收藏、添加队列、下载等成功操作后给出轻量确认。
/// 所有样式通过与 [SnackBarTheme] 保持一致来自定义。
class AppSnackBar {
  AppSnackBar._();

  /// 显示一条成功消息。
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: EdgeInsets.zero,
        ),
      );
  }
}

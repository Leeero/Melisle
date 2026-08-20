import 'dart:ui';

import 'package:flutter/material.dart';

/// 毛玻璃效果容器。
///
/// 为子组件添加毛玻璃背景效果，适用于迷你播放器、浮层等场景。
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blurRadius = 20,
    this.opacity = 0.8,
    this.tintColor,
    this.borderRadius,
    this.border,
  });

  final Widget child;
  final double blurRadius;
  final double opacity;
  final Color? tintColor;
  final BorderRadius? borderRadius;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTintColor = tintColor ??
        (isDark
            ? Colors.black.withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity));
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(16);

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurRadius,
          sigmaY: blurRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: effectiveTintColor,
            borderRadius: effectiveBorderRadius,
            border: border ??
                Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 毛玻璃效果的迷你播放器包装。
///
/// 为迷你播放器提供精致的毛玻璃背景。
class GlassMiniPlayerWrapper extends StatelessWidget {
  const GlassMiniPlayerWrapper({
    super.key,
    required this.child,
    this.isWide = false,
  });

  final Widget child;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isWide) {
      // 桌面端使用边框而非毛玻璃
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: child,
      );
    }

    // 移动端使用毛玻璃效果
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        blurRadius: 24,
        opacity: isDark ? 0.75 : 0.85,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

import 'package:flutter/animation.dart';

/// Melisle 动效系统
///
/// 所有时长和曲线统一管理，确保一致的交互体验。
/// 参考 Material Design 3 和 Apple HIG 的动效规范。
abstract final class AppMotion {
  // ──────────────────── 时长 ────────────────────

  /// 100ms - 即时反馈（颜色变化、图标切换）
  static const Duration instant = Duration(milliseconds: 100);

  /// 150ms - 快速反馈（悬停、按压）
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms - 普通过渡（展开、收起）
  static const Duration normal = Duration(milliseconds: 250);

  /// 350ms - 慢速过渡（页面切换、模态）
  static const Duration slow = Duration(milliseconds: 350);

  /// 500ms - 更慢（全屏动画、复杂过渡）
  static const Duration slower = Duration(milliseconds: 500);

  // ──── 语义化时长 ────

  /// 悬停反馈
  static const Duration hover = fast;

  /// 点击反馈
  static const Duration tap = fast;

  /// 状态切换
  static const Duration state = normal;

  /// 页面切换
  static const Duration page = slow;

  /// Sheet 弹出
  static const Duration sheet = normal;

  /// 浮层出现
  static const Duration overlay = slower;

  /// 歌词滚动
  static const Duration lyrics = Duration(milliseconds: 420);

  /// 微交互（收藏弹跳等）
  static const Duration micro = Duration(milliseconds: 600);

  // ──────────────────── 缓动曲线 ────────────────────

  /// 标准缓动（大多数场景）
  static const Curve standard = Curves.easeOut;

  /// 强调缓动（重要元素进入）
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// 柔和缓动（退出、收起）
  static const Curve gentle = Cubic(0.4, 0, 0.2, 1);

  /// 进入曲线（元素出现）
  static const Curve enter = Cubic(0.2, 0, 0.13, 1);

  /// 退出曲线（元素消失）
  static const Curve exit = Curves.easeIn;

  /// 弹性曲线（收藏、喜欢）
  static const Curve bounce = Curves.elasticOut;

  /// 音乐曲线（歌词、进度条）
  static const Curve music = Cubic(0.2, 0, 0.13, 1);

  /// 平滑曲线（滚动、平移）
  static const Curve smooth = Cubic(0.4, 0, 0.2, 1);
}

/// 全局 Z-Index 层级定义。
///
/// 统一管理各 UI 层的堆叠顺序，避免不同组件之间出现层叠冲突。
/// 数值参考 Material 3 elevation 体系，且与 Flutter 内置 widget 的
/// 默认 elevation 对齐（如 AppBar ≈ 6, SnackBar ≈ 6）。
abstract final class AppZIndex {
  /// 页面基底内容。
  static const int pageContent = 0;

  /// 导航栏 / 侧边栏。
  static const int navbar = 10;

  /// 弹出菜单、工具提示。
  static const int popup = 20;

  /// 迷你播放栏。
  static const int miniPlayer = 30;

  /// 对话框、底部 Sheet。
  static const int dialog = 40;

  /// SnackBar / Toast。
  static const int snackbar = 50;

  /// 加载遮罩、模态阻塞层。
  static const int overlay = 60;
}

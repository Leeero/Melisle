import 'package:cross_platform_music_player/shared/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 移动端左滑操作组件。
///
/// 支持左滑露出操作按钮，如收藏、添加到队列等。
/// 仅在移动端（compact 布局）下启用，桌面端不支持。
class SwipeAction extends StatefulWidget {
  const SwipeAction({
    super.key,
    required this.child,
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.onSwipeEnd,
    this.threshold = 80.0,
    this.enabled = true,
  });

  final Widget child;
  final List<SwipeActionItem> leadingActions;
  final List<SwipeActionItem> trailingActions;
  final VoidCallback? onSwipeEnd;
  final double threshold;
  final bool enabled;

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<SwipeAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragExtent = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.state,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _maxSwipeExtent {
    final actions = _dragExtent > 0
        ? widget.leadingActions
        : widget.trailingActions;
    if (actions.isEmpty) return 0;
    return actions.length * 72.0;
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_isDragging) return;

    final delta = details.primaryDelta ?? 0;
    setState(() {
      _dragExtent += delta;
      _dragExtent = _dragExtent.clamp(-_maxSwipeExtent, _maxSwipeExtent);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!widget.enabled || !_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;

    if (_dragExtent.abs() > widget.threshold || velocity.abs() > 500) {
      // 执行操作
      _executeAction();
    }

    // 回弹
    _dragExtent = 0;
    _controller.forward(from: 0).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _executeAction() {
    final actions = _dragExtent > 0
        ? widget.leadingActions
        : widget.trailingActions;

    if (actions.isNotEmpty) {
      // 执行第一个操作
      actions.first.onPressed();
      HapticFeedback.mediumImpact();
    }

    widget.onSwipeEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled ||
        (widget.leadingActions.isEmpty && widget.trailingActions.isEmpty)) {
      return widget.child;
    }

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // 操作按钮背景
          if (_dragExtent != 0) _buildActionsBackground(),
          // 内容
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBackground() {
    final isLeftSwipe = _dragExtent > 0;
    final actions = isLeftSwipe
        ? widget.leadingActions
        : widget.trailingActions;
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Row(
        mainAxisAlignment:
            isLeftSwipe ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: actions.map((action) {
          return Container(
            width: 72,
            decoration: BoxDecoration(
              color: action.backgroundColor ?? colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  color: action.iconColor ?? colorScheme.onPrimary,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  style: TextStyle(
                    color: action.labelColor ?? colorScheme.onPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 滑动操作项配置。
class SwipeActionItem {
  const SwipeActionItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? labelColor;
}

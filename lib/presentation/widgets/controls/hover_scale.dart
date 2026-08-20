import 'package:cross_platform_music_player/shared/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// 包装子组件，提供悬停时的上浮和缩放效果。
///
/// 用于卡片、按钮等可交互元素，提供精致的悬停反馈。
class HoverScale extends StatefulWidget {
  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.translateY = -2.0,
    this.duration,
    this.curve,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final double translateY;
  final Duration? duration;
  final Curve? curve;
  final bool enabled;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: widget.duration ?? AppMotion.fast,
        curve: widget.curve ?? AppMotion.standard,
        transform: _hovered
            ? (Matrix4.identity()
              ..translate(0.0, widget.translateY)
              ..scale(widget.scale))
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}

/// 包装子组件，提供按压时的缩放效果。
///
/// 用于按钮、卡片等可交互元素，提供精致的按压反馈。
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
    this.duration,
    this.curve,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final Duration? duration;
  final Curve? curve;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: widget.duration ?? AppMotion.fast,
        curve: widget.curve ?? AppMotion.standard,
        scale: _pressed ? widget.scale : 1.0,
        child: widget.child,
      ),
    );
  }
}

/// 组合悬停和按压效果的容器。
///
/// 提供完整的微交互体验：悬停上浮 + 按压缩缩。
class InteractiveContainer extends StatefulWidget {
  const InteractiveContainer({
    super.key,
    required this.child,
    required this.onTap,
    this.hoverScale = 1.02,
    this.hoverTranslateY = -2.0,
    this.pressScale = 0.96,
    this.borderRadius,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final double hoverScale;
  final double hoverTranslateY;
  final double pressScale;
  final BorderRadius? borderRadius;
  final bool enabled;

  @override
  State<InteractiveContainer> createState() => _InteractiveContainerState();
}

class _InteractiveContainerState extends State<InteractiveContainer> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          transform: _pressed
              ? (Matrix4.identity()..scale(widget.pressScale))
              : _hovered
                  ? (Matrix4.identity()
                    ..translate(0.0, widget.hoverTranslateY)
                    ..scale(widget.hoverScale))
                  : Matrix4.identity(),
          child: widget.child,
        ),
      ),
    );
  }
}

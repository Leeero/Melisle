import 'package:cross_platform_music_player/shared/theme/app_motion.dart';
import 'package:cross_platform_music_player/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 带弹跳动效的收藏按钮。
///
/// 点击时有弹性缩放效果，提供情感化的交互反馈。
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 24,
    this.color,
  });

  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final Color? color;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.micro,
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onToggle();
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ??
        (widget.isFavorite
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant);

    return Semantics(
      button: true,
      label: widget.isFavorite ? '取消收藏' : '收藏',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Icon(
                widget.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: widget.size,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 轻量级收藏图标（无动画，用于列表项等高频场景）。
class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({
    super.key,
    required this.isFavorite,
    this.size = 18,
    this.color,
  });

  final bool isFavorite;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ??
        (isFavorite
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant);

    return Icon(
      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      size: size,
      color: iconColor,
    );
  }
}

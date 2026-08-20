import 'package:cross_platform_music_player/shared/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// 淡入滑动页面过渡。
///
/// 提供精致的页面切换效果：从下方滑入 + 淡入。
class FadeSlideTransition extends StatelessWidget {
  const FadeSlideTransition({
    super.key,
    required this.animation,
    required this.child,
    this.slideBegin = const Offset(0, 0.05),
  });

  final Animation<double> animation;
  final Widget child;
  final Offset slideBegin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(
              0,
              slideBegin.dy * (1 - animation.value) * 100,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// 自定义页面切换路由。
///
/// 提供精致的页面切换效果。
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({
    required this.child,
    this.transitionDuration = AppMotion.slow,
    this.reverseTransitionDuration = AppMotion.normal,
  }) : super(
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeSlideTransition(
              animation: animation,
              child: child,
            );
          },
        );

  final Widget child;
  @override
  final Duration transitionDuration;
  @override
  final Duration reverseTransitionDuration;
}

/// 列表项进入动画。
///
/// 为列表中的每个项目提供交错的进入动画。
class StaggeredFadeSlide extends StatelessWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
    this.duration,
  });

  final int index;
  final Widget child;
  final Duration delay;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = duration ?? AppMotion.normal;
    final totalDelay = delay * index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: effectiveDuration + totalDelay,
      curve: AppMotion.enter,
      builder: (context, value, child) {
        // 延迟后才开始动画
        final progress = (value * (effectiveDuration + totalDelay).inMilliseconds -
                totalDelay.inMilliseconds) /
            effectiveDuration.inMilliseconds;
        final clampedProgress = progress.clamp(0.0, 1.0);

        return Opacity(
          opacity: clampedProgress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - clampedProgress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

/// 骨架屏组件，支持行、网格、卡片三种变体。
///
/// 自动适应主题色，暗色/亮色模式下使用对应的表面色。
/// 尊重 [MediaQuery.reducedMotionOf]。
final class AppSkeleton {
  AppSkeleton._();

  /// 单行骨架。
  static Widget row({
    Key? key,
    double? width,
    double height = 16,
    double borderRadius = 6,
  }) {
    return _SkeletonBase(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  /// 圆形骨架。
  static Widget circle({
    Key? key,
    double size = 44,
  }) {
    return _SkeletonBase(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// 网格骨架，用于专辑/歌单卡片列表。
  static Widget grid({
    Key? key,
    int count = 6,
    double aspectRatio = 1,
    double borderRadius = 14,
    double spacing = 16,
  }) {
    return _SkeletonGrid(
      key: key,
      count: count,
      aspectRatio: aspectRatio,
      borderRadius: borderRadius,
      spacing: spacing,
    );
  }

  /// 曲目行骨架。
  static Widget trackRow({
    Key? key,
    double height = 52,
  }) {
    return _SkeletonTrackRow(
      key: key,
      height: height,
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({
    super.key,
    required this.count,
    required this.aspectRatio,
    required this.borderRadius,
    required this.spacing,
  });

  final int count;
  final double aspectRatio;
  final double borderRadius;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final columnCount = _columnCount(context);
    final rowCount = (count / columnCount).ceil();

    return Column(
      children: [
        for (var row = 0; row < rowCount; row++) ...[
          if (row > 0) SizedBox(height: spacing),
          Row(
            children: [
              for (var col = 0; col < columnCount; col++) ...[
                if (col > 0) SizedBox(width: spacing),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: _SkeletonBase(
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  int _columnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 5;
    if (width >= 960) return 4;
    if (width >= 640) return 3;
    return 2;
  }
}

class _SkeletonTrackRow extends StatelessWidget {
  const _SkeletonTrackRow({
    super.key,
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: height - 12,
        child: Row(
          children: [
            _SkeletonBase(width: height - 12, height: height - 12, borderRadius: 6),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SkeletonBase(width: 160, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  _SkeletonBase(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 40),
            _SkeletonBase(width: 32, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBase extends StatefulWidget {
  const _SkeletonBase({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<_SkeletonBase> createState() => _SkeletonBaseState();
}

class _SkeletonBaseState extends State<_SkeletonBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              colorScheme.onSurface.withValues(alpha: _animation.value * 0.10),
              colorScheme.surfaceContainerHighest,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

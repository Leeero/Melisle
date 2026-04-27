import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:flutter/material.dart';

/// 同步歌词视图：
///
/// - 垂直滚动歌词列表
/// - 当前行居中 + 高亮
/// - 其他行半透明
/// - 点击任意一行 → 调用 [onLineTap] 跳转到该行开始时间
/// Design spec: Lyric Highlight color — warm golden-yellow for focal contrast on cool backgrounds.
const kLyricHighlightColor = Color(0xFFFFD43B);

class LyricView extends StatefulWidget {
  const LyricView({
    super.key,
    required this.lines,
    required this.currentIndex,
    this.onLineTap,
    this.empty,
  });

  final List<LyricLine> lines;
  final int? currentIndex;
  final ValueChanged<int>? onLineTap;

  /// 无歌词时的占位。null 时使用默认文案。
  final Widget? empty;

  @override
  State<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends State<LyricView> {
  final _scrollController = ScrollController();
  static const double _lineHeight = 56;

  @override
  void didUpdateWidget(covariant LyricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != null &&
        widget.currentIndex != oldWidget.currentIndex) {
      _scrollToCurrent();
    }
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final idx = widget.currentIndex;
    if (idx == null) return;
    final target = (idx * _lineHeight) -
        (_scrollController.position.viewportDimension / 2) +
        (_lineHeight / 2);
    final clamped = target.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.lines.isEmpty) {
      return widget.empty ??
          Center(
            child: Text(
              '暂无歌词',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 120),
      itemCount: widget.lines.length,
      itemExtent: _lineHeight,
      itemBuilder: (context, index) {
        final isCurrent = index == widget.currentIndex;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onLineTap == null
              ? null
              : () => widget.onLineTap!(index),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              scale: isCurrent ? 1.05 : 1.0,
              alignment: Alignment.centerLeft,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: (isCurrent
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleMedium) ??
                    const TextStyle(),
                child: Text(
                  widget.lines[index].text,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? kLyricHighlightColor
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

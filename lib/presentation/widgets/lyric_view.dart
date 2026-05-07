import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

/// 同步歌词视图：
///
/// - 垂直滚动歌词列表
/// - 当前行居中 + 高亮
/// - 其他行半透明
/// - 点击任意一行 → 调用 [onLineTap] 跳转到该行开始时间

class LyricView extends StatefulWidget {
  const LyricView({
    super.key,
    required this.lines,
    required this.currentIndex,
    this.onLineTap,
    this.empty,
    this.textAlign = TextAlign.left,
    this.alignment = Alignment.centerLeft,
    this.maxTextWidth,
    this.currentScale = 1.05,
  });

  final List<LyricLine> lines;
  final int? currentIndex;
  final ValueChanged<int>? onLineTap;

  /// 无歌词时的占位。null 时使用默认文案。
  final Widget? empty;
  final TextAlign textAlign;
  final Alignment alignment;
  final double? maxTextWidth;
  final double currentScale;

  @override
  State<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends State<LyricView> {
  final _scrollController = ScrollController();
  static const double _lineHeight = 56;
  static const double _verticalPadding = 120;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(covariant LyricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != null &&
        (widget.currentIndex != oldWidget.currentIndex ||
            widget.lines != oldWidget.lines)) {
      _scrollToCurrent();
    }
  }

  void _scrollToCurrent() {
    final idx = widget.currentIndex;
    if (idx == null) return;

    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
      return;
    }

    final target =
        _verticalPadding +
        (idx * _lineHeight) -
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
      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
      itemCount: widget.lines.length,
      itemExtent: _lineHeight,
      itemBuilder: (context, index) {
        final isCurrent = index == widget.currentIndex;
        final text = AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style:
              (isCurrent
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.titleMedium) ??
              const TextStyle(),
          child: Text(
            widget.lines[index].text,
            textAlign: widget.textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
              color: isCurrent
                  ? theme.lyricHighlight
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        );

        Widget content = AnimatedScale(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          scale: isCurrent ? widget.currentScale : 1.0,
          alignment: Alignment.center,
          child: text,
        );

        if (widget.maxTextWidth != null) {
          content = SizedBox(
            width: widget.maxTextWidth,
            child: content,
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onLineTap == null
              ? null
              : () => widget.onLineTap!(index),
          child: Align(
            alignment: widget.alignment,
            child: content,
          ),
        );
      },
    );
  }
}

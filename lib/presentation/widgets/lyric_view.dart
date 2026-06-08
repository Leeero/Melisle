import 'dart:async';

import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/gestures.dart';
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
    this.showCurrentLineButton = true,
    this.currentTextStyle,
    this.inactiveTextStyle,
    this.linePadding = const EdgeInsets.symmetric(vertical: 6),
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
  final bool showCurrentLineButton;
  final TextStyle? currentTextStyle;
  final TextStyle? inactiveTextStyle;
  final EdgeInsetsGeometry linePadding;

  @override
  State<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends State<LyricView> {
  final _scrollController = ScrollController();
  Timer? _autoScrollResumeTimer;
  bool _userScrollLocked = false;
  int? _lastScrolledIndex;

  static const Duration _autoScrollResumeDelay = Duration(seconds: 3);
  static const double _verticalPadding = 80;
  static const double _estimatedLineExtent = 58;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(covariant LyricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines != oldWidget.lines) {
      _lastScrolledIndex = null;
    }
    if (widget.currentIndex != null &&
        (widget.currentIndex != oldWidget.currentIndex ||
            widget.lines != oldWidget.lines)) {
      _scrollToCurrent();
    }
  }

  void _scrollToCurrent({bool force = false}) {
    final idx = widget.currentIndex;
    if (idx == null || idx < 0 || idx >= widget.lines.length) return;
    if (!force && _userScrollLocked) return;
    if (!force && _lastScrolledIndex == idx) return;

    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToCurrent(force: force);
      });
      return;
    }

    _lastScrolledIndex = idx;
    final viewport = _scrollController.position.viewportDimension;
    final rawOffset =
        _verticalPadding + idx * _estimatedLineExtent - viewport / 2;
    final target = rawOffset
        .clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        )
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _lockAutoScrollForUser() {
    _autoScrollResumeTimer?.cancel();
    if (!_userScrollLocked && mounted) {
      setState(() => _userScrollLocked = true);
    }
    _autoScrollResumeTimer = Timer(_autoScrollResumeDelay, () {
      if (!mounted) return;
      setState(() => _userScrollLocked = false);
      _lastScrolledIndex = null;
      _scrollToCurrent(force: true);
    });
  }

  void _jumpBackToCurrent() {
    _autoScrollResumeTimer?.cancel();
    setState(() => _userScrollLocked = false);
    _lastScrolledIndex = null;
    _scrollToCurrent(force: true);
  }

  void _handleLineTap(int index) {
    _autoScrollResumeTimer?.cancel();
    if (_userScrollLocked) {
      setState(() => _userScrollLocked = false);
    }
    _lastScrolledIndex = null;
    widget.onLineTap?.call(index);
  }

  @override
  void dispose() {
    _autoScrollResumeTimer?.cancel();
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

    final lyrics = Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _lockAutoScrollForUser();
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
          cacheExtent: _estimatedLineExtent * 8,
          itemCount: widget.lines.length,
          itemBuilder: (context, index) {
            return _LyricLineTile(
              line: widget.lines[index],
              isCurrent: index == widget.currentIndex,
              textAlign: widget.textAlign,
              alignment: widget.alignment,
              maxTextWidth: widget.maxTextWidth,
              currentScale: widget.currentScale,
              currentTextStyle: widget.currentTextStyle,
              inactiveTextStyle: widget.inactiveTextStyle,
              linePadding: widget.linePadding,
              onTap: widget.onLineTap == null
                  ? null
                  : () => _handleLineTap(index),
            );
          },
        ),
      ),
    );

    if (!widget.showCurrentLineButton) return lyrics;

    return Stack(
      children: [
        Positioned.fill(child: lyrics),
        Positioned(
          right: 12,
          bottom: 12,
          child: AnimatedSwitcher(
            duration: AppMotion.micro,
            child: _userScrollLocked
                ? _CurrentLyricButton(onPressed: _jumpBackToCurrent)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _lockAutoScrollForUser();
    }
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      _lockAutoScrollForUser();
    }
    return false;
  }
}

class _LyricLineTile extends StatelessWidget {
  const _LyricLineTile({
    required this.line,
    required this.isCurrent,
    required this.textAlign,
    required this.alignment,
    required this.currentScale,
    required this.linePadding,
    this.maxTextWidth,
    this.currentTextStyle,
    this.inactiveTextStyle,
    this.onTap,
  });

  final LyricLine line;
  final bool isCurrent;
  final TextAlign textAlign;
  final Alignment alignment;
  final double currentScale;
  final EdgeInsetsGeometry linePadding;
  final double? maxTextWidth;
  final TextStyle? currentTextStyle;
  final TextStyle? inactiveTextStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fallbackStyle =
        (isCurrent
                ? theme.textTheme.headlineSmall
                : theme.textTheme.titleMedium)
            ?.copyWith(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? theme.lyricHighlight
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.58),
              height: isCurrent ? 1.56 : 1.78,
            ) ??
        TextStyle(
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent
              ? theme.lyricHighlight
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.58),
          height: isCurrent ? 1.56 : 1.78,
        );
    final style =
        (isCurrent ? currentTextStyle : inactiveTextStyle) ?? fallbackStyle;

    Widget content = AnimatedScale(
      duration: const Duration(milliseconds: 420),
      curve: AppMotion.enter,
      scale: isCurrent ? currentScale : 1.0,
      alignment: Alignment.center,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 420),
        curve: AppMotion.enter,
        style: style,
        child: Text(
          line.text,
          textAlign: textAlign,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (maxTextWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxTextWidth!),
        child: content,
      );
    }

    return Semantics(
      selected: isCurrent,
      button: onTap != null,
      label: isCurrent ? '当前歌词：${line.text}' : line.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: linePadding,
            child: Align(alignment: alignment, child: content),
          ),
        ),
      ),
    );
  }
}

class _CurrentLyricButton extends StatelessWidget {
  const _CurrentLyricButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: '定位到当前歌词',
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: const Icon(Icons.my_location_rounded, size: 18),
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.82,
          ),
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

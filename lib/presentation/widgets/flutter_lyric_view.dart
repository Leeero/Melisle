import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lyric/flutter_lyric.dart' as flutter_lyric;

class FlutterLyricView extends StatefulWidget {
  const FlutterLyricView({
    super.key,
    required this.lines,
    this.onLineTap,
    this.textAlign = TextAlign.left,
    this.alignment = Alignment.centerLeft,
    this.maxTextWidth,
    this.currentScale = 1.05,
  });

  final List<LyricLine> lines;
  final ValueChanged<int>? onLineTap;
  final TextAlign textAlign;
  final Alignment alignment;
  final double? maxTextWidth;
  final double currentScale;

  @override
  State<FlutterLyricView> createState() => _FlutterLyricViewState();
}

class _FlutterLyricViewState extends State<FlutterLyricView> {
  late final flutter_lyric.LyricController _controller;

  @override
  void initState() {
    super.initState();
    _controller = flutter_lyric.LyricController()
      ..setOnTapLineCallback(_handleTapLine);
    _loadLyrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncProgress(context.read<PlayerCubit>().state);
  }

  @override
  void didUpdateWidget(covariant FlutterLyricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines != oldWidget.lines) {
      _loadLyrics();
      _syncProgress(context.read<PlayerCubit>().state);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadLyrics() {
    _controller.loadLyric(_toLrc(widget.lines));
    _controller.lyricOffset = 0;
  }

  void _syncProgress(PlayerViewState state) {
    _controller.setProgress(
      _shiftPosition(state.position, state.lyricSyncOffset),
    );
  }

  void _handleTapLine(Duration position) {
    final index = widget.lines.indexWhere(
      (line) => line.start.inMilliseconds == position.inMilliseconds,
    );
    if (index >= 0) {
      // 点击后立即同步歌词到目标行，避免等待异步 seek 完成前的显示滞后。
      _controller.setProgress(position);
      widget.onLineTap?.call(index);
    }
  }

  Duration _shiftPosition(Duration position, Duration offset) {
    final shifted = position + offset;
    return shifted.isNegative ? Duration.zero : shifted;
  }

  String _toLrc(List<LyricLine> lines) {
    final lrcLines = <String>[];
    if (lines.isNotEmpty && lines.first.start > Duration.zero) {
      lrcLines.add('[00:00.000]');
    }
    lrcLines.addAll(
      lines.map(
        (line) =>
            '[${_formatTimestamp(line.start)}]${_sanitizeText(line.text)}',
      ),
    );
    return lrcLines.join('\n');
  }

  String _formatTimestamp(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);
    return '$totalMinutes:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
  }

  String _sanitizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  flutter_lyric.LyricStyle _buildStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlight = theme.lyricHighlight;
    final isCentered = widget.alignment.x == 0;

    return flutter_lyric.LyricStyle(
      textStyle: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.58),
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      activeStyle: (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
        color: highlight,
        fontWeight: FontWeight.w800,
        height: 1.25,
        fontSize:
            (theme.textTheme.titleLarge?.fontSize ?? 22) * widget.currentScale,
      ),
      translationStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
          .copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            height: 1.2,
          ),
      lineTextAlign: widget.textAlign,
      lineGap: 24,
      translationLineGap: 8,
      contentAlignment: isCentered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      selectionAnchorPosition: 0.5,
      activeAnchorPosition: 0.5,
      fadeRange: flutter_lyric.FadeRange(top: 0.18, bottom: 0.24),
      scrollDuration: const Duration(milliseconds: 320),
      scrollDurations: {
        500: const Duration(milliseconds: 420),
        1000: const Duration(milliseconds: 560),
      },
      scrollCurve: Curves.easeOutCubic,
      selectionAlignment: isCentered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      activeAlignment: isCentered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      selectedColor: highlight,
      selectedTranslationColor: highlight,
      selectionAutoResumeMode:
          flutter_lyric.SelectionAutoResumeMode.afterSelecting,
      selectionAutoResumeDuration: const Duration(milliseconds: 500),
      activeAutoResumeDuration: const Duration(seconds: 3),
      activeHighlightColor: highlight.withValues(alpha: 0.9),
      activeHighlightExtraFadeWidth: 24,
      enableSwitchAnimation: true,
      switchEnterDuration: const Duration(milliseconds: 220),
      switchExitDuration: const Duration(milliseconds: 220),
      switchEnterCurve: Curves.easeOutCubic,
      switchExitCurve: Curves.easeOutCubic,
      disableTouchEvent: widget.onLineTap == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlayerCubit, PlayerViewState>(
      listenWhen: (previous, current) =>
          previous.position != current.position ||
          previous.lyricSyncOffset != current.lyricSyncOffset,
      listener: (context, state) => _syncProgress(state),
      child: Align(
        alignment: widget.alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.maxTextWidth ?? double.infinity,
          ),
          child: flutter_lyric.LyricView(
            controller: _controller,
            style: _buildStyle(context),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}

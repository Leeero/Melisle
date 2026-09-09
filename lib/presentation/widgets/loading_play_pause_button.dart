import 'dart:math' as math;

import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class LoadingPlayPauseButton extends StatefulWidget {
  const LoadingPlayPauseButton({
    super.key,
    required this.isLoading,
    required this.isPlaying,
    required this.onPressed,
    this.size = 56,
    this.iconSize = 28,
    this.loadingStrokeWidth = 2.8,
    this.backgroundColor,
    this.foregroundColor,
  });

  final bool isLoading;
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final double loadingStrokeWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<LoadingPlayPauseButton> createState() => _LoadingPlayPauseButtonState();
}

class _LoadingPlayPauseButtonState extends State<LoadingPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;
  bool _hovered = false;
  bool _pressed = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _updateAnimation();
    }
  }

  @override
  void didUpdateWidget(LoadingPlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading == oldWidget.isLoading) return;
    _updateAnimation();
  }

  void _updateAnimation() {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (widget.isLoading && !disableAnimations) {
      _loadingController.repeat();
    } else {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = widget.size;
    final tapTargetSize = math.max(size, 44.0);
    final tooltip = _tooltip;
    final reduceMotion = AppMotion.shouldReduce(context);
    final scale = reduceMotion
        ? 1.0
        : _pressed
        ? 0.96
        : (_hovered ? 1.035 : 1.0);
    final backgroundColor =
        widget.backgroundColor ?? colorScheme.primaryContainer;
    final foregroundColor =
        widget.foregroundColor ?? colorScheme.onPrimaryContainer;
    final ringColor = colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        liveRegion: widget.isLoading,
        child: SizedBox.square(
          dimension: tapTargetSize,
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() {
                _hovered = false;
                _pressed = false;
              }),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  widget.onPressed();
                },
                child: AnimatedScale(
                  duration: AppMotion.adaptive(context, AppMotion.fast),
                  curve: AppMotion.standard,
                  scale: scale,
                  child: AnimatedContainer(
                    duration: AppMotion.adaptive(context, AppMotion.fast),
                    curve: AppMotion.standard,
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isLoading
                            ? ringColor.withValues(alpha: 0.34)
                            : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: _hovered ? 0.18 : 0.10,
                          ),
                          blurRadius: _hovered ? 18 : 12,
                          offset: const Offset(0, 5),
                        ),
                        if (widget.isLoading)
                          BoxShadow(
                            color: ringColor.withValues(alpha: 0.18),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.isLoading)
                          RotationTransition(
                            turns: _loadingController,
                            child: SizedBox.square(
                              dimension: size - widget.loadingStrokeWidth,
                              child: CircularProgressIndicator(
                                strokeWidth: widget.loadingStrokeWidth,
                                strokeCap: StrokeCap.round,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ringColor,
                                ),
                                backgroundColor: foregroundColor.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                          ),
                        AnimatedSwitcher(
                          duration: AppMotion.adaptive(context, AppMotion.fast),
                          child: Icon(
                            _icon,
                            key: ValueKey(
                              '${widget.isLoading}-${widget.isPlaying}',
                            ),
                            size: widget.isLoading
                                ? widget.iconSize * 0.78
                                : widget.iconSize,
                            color: foregroundColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _tooltip {
    if (widget.isLoading) return '正在准备播放';
    if (widget.isPlaying) return '暂停';
    return '播放';
  }

  IconData get _icon {
    if (widget.isLoading) return Icons.play_arrow_rounded;
    if (widget.isPlaying) return Icons.pause_rounded;
    return Icons.play_arrow_rounded;
  }
}

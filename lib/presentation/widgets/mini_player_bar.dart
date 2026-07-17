import 'dart:ui' as ui;

import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/loading_play_pause_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/queue_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      // 外层只监听曲目切换；isPlaying/position/volume 等高频状态由子组件各自监听，
      // 避免外层重建导致 StatefulWidget 子组件（如 _MiniTimeline）丢失内部状态。
      buildWhen: (prev, next) => prev.currentTrack?.id != next.currentTrack?.id,
      builder: (context, state) {
        final track = state.currentTrack;
        if (track == null) {
          return const SizedBox.shrink();
        }

        final width = MediaQuery.sizeOf(context).width;
        final isWide = AppBreakpoints.usesWideContentWidth(width);
        final artworkSourceContext = ArtworkSourceContext.track(track);

        return _MiniPlayerFrame(
          isWide: isWide,
          child: isWide
              ? _WideMiniPlayer(
                  trackTitle: track.title,
                  artistName: track.artistName,
                  artworkUrl: track.artworkUrl,
                  sourceContext: artworkSourceContext,
                )
              : _CompactMiniPlayer(
                  trackTitle: track.title,
                  artistName: track.artistName,
                  artworkUrl: track.artworkUrl,
                  sourceContext: artworkSourceContext,
                ),
        );
      },
    );
  }
}

class _MiniPlayerFrame extends StatelessWidget {
  const _MiniPlayerFrame({required this.isWide, required this.child});

  final bool isWide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (isWide) {
      return SizedBox(
        height: AppSpacingTokens.desktopMiniPlayerHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.72 : 1,
                ),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacingTokens.miniPlayerInnerHorizontal,
            ),
            child: child,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.94),
                    Color.alphaBlend(
                      theme.musicWarmSoft.withValues(alpha: 0.30),
                      colorScheme.surface,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Color.alphaBlend(
                    theme.musicTeal.withValues(alpha: 0.18),
                    colorScheme.outlineVariant,
                  ),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 0, 10, 0),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactMiniPlayer extends StatefulWidget {
  const _CompactMiniPlayer({
    required this.trackTitle,
    required this.artistName,
    required this.artworkUrl,
    required this.sourceContext,
  });

  final String trackTitle;
  final String artistName;
  final String artworkUrl;
  final ArtworkSourceContext sourceContext;

  @override
  State<_CompactMiniPlayer> createState() => _CompactMiniPlayerState();
}

class _CompactMiniPlayerState extends State<_CompactMiniPlayer> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '当前播放：${widget.trackTitle}，${widget.artistName}。点击展开播放页。',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => PlayerNavigation.openPlayerPage(context),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedScale(
            duration: AppMotion.micro,
            curve: AppMotion.standard,
            scale: _pressed ? 0.992 : 1,
            child: AnimatedSlide(
              duration: AppMotion.micro,
              curve: AppMotion.standard,
              offset: _pressed ? const Offset(0, 0.012) : Offset.zero,
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: widget.artworkUrl,
                    size: 42,
                    borderRadius: 12,
                    sourceContext: widget.sourceContext,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trackTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.muted,
                            fontSize: 12,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  BlocBuilder<PlayerCubit, PlayerViewState>(
                    buildWhen: (prev, next) =>
                        prev.isPlaying != next.isPlaying ||
                        prev.isLoading != next.isLoading,
                    builder: (context, state) {
                      return LoadingPlayPauseButton(
                        isLoading: state.isLoading,
                        isPlaying: state.isPlaying,
                        onPressed: context.read<PlayerCubit>().togglePlayback,
                        size: 36,
                        iconSize: 16,
                        loadingStrokeWidth: 2.4,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  _MiniControlButton(
                    icon: Icons.queue_music_rounded,
                    onPressed: () => _showMiniQueueSheet(context),
                    compact: true,
                    tooltip: '当前播放列表',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WideMiniPlayer extends StatelessWidget {
  const _WideMiniPlayer({
    required this.trackTitle,
    required this.artistName,
    required this.artworkUrl,
    required this.sourceContext,
  });

  final String trackTitle;
  final String artistName;
  final String artworkUrl;
  final ArtworkSourceContext sourceContext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: _MiniTrackButton(
            trackTitle: trackTitle,
            artistName: artistName,
            artworkUrl: artworkUrl,
            sourceContext: sourceContext,
          ),
        ),
        const SizedBox(width: 16),
        const _MiniControlCluster(child: _MiniTransportControls()),
        const SizedBox(width: 16),
        const Expanded(child: _MiniTimelineBlock(showElapsedLabels: true)),
        const SizedBox(width: 16),
        const _MiniPlaybackModeButton(),
        const SizedBox(width: 8),
        const _MiniVolumeControl(),
        const SizedBox(width: 4),
        const _MiniExpandButton(),
      ],
    );
  }
}

void _showMiniQueueSheet(BuildContext context) {
  QueueSheet.show(context);
}

class _MiniTrackButton extends StatelessWidget {
  const _MiniTrackButton({
    required this.trackTitle,
    required this.artistName,
    required this.artworkUrl,
    required this.sourceContext,
  });

  final String trackTitle;
  final String artistName;
  final String artworkUrl;
  final ArtworkSourceContext sourceContext;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final content = Row(
      children: [
        CachedArtwork(
          imageUrl: artworkUrl,
          size: 48,
          borderRadius: AppRadiusTokens.desktopSm,
          sourceContext: sourceContext,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trackTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              const SizedBox(height: 4),
              Text(
                artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      label: '当前播放：$trackTitle，$artistName。点击展开播放器。',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        onTap: () => PlayerNavigation.openPlayerPage(context),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: content,
        ),
      ),
    );
  }
}

class _MiniTransportControls extends StatelessWidget {
  const _MiniTransportControls();

  @override
  Widget build(BuildContext context) {
    const gap = AppSpacingTokens.miniPlayerControlGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniControlButton(
          icon: Icons.skip_previous_rounded,
          onPressed: context.read<PlayerCubit>().previous,
          tooltip: '上一曲',
        ),
        SizedBox(width: gap),
        BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) =>
              prev.isPlaying != next.isPlaying ||
              prev.isLoading != next.isLoading,
          builder: (context, state) => LoadingPlayPauseButton(
            isLoading: state.isLoading,
            isPlaying: state.isPlaying,
            onPressed: context.read<PlayerCubit>().togglePlayback,
            size: 36,
            iconSize: 18,
            loadingStrokeWidth: 2.4,
          ),
        ),
        SizedBox(width: gap),
        _MiniControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: context.read<PlayerCubit>().next,
          tooltip: '下一曲',
        ),
      ],
    );
  }
}

class _MiniTimelineBlock extends StatelessWidget {
  const _MiniTimelineBlock({this.showElapsedLabels = false});

  final bool showElapsedLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _MiniTimeline(),
        if (showElapsedLabels) ...[
          const SizedBox(height: 6),
          BlocBuilder<PlayerCubit, PlayerViewState>(
            buildWhen: (prev, next) =>
                prev.position != next.position ||
                prev.duration != next.duration,
            builder: (context, state) => Row(
              children: [
                Text(
                  _format(state.position),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  _format(state.duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniControlCluster extends StatelessWidget {
  const _MiniControlCluster({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _MiniVolumeControl extends StatelessWidget {
  const _MiniVolumeControl();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 132,
      child: Row(
        children: [
          Icon(
            Icons.volume_up_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.volume != next.volume,
              builder: (context, state) => Slider(
                value: state.volume,
                semanticFormatterCallback: (value) =>
                    '音量 ${_volumePercent(value)}%',
                onChanged: context.read<PlayerCubit>().setVolume,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniExpandButton extends StatelessWidget {
  const _MiniExpandButton();

  @override
  Widget build(BuildContext context) {
    return _MiniControlButton(
      icon: Icons.open_in_full_rounded,
      onPressed: () => PlayerNavigation.openPlayerPage(context),
      tooltip: '展开播放器',
    );
  }
}

class _MiniTimeline extends StatefulWidget {
  const _MiniTimeline();

  @override
  State<_MiniTimeline> createState() => _MiniTimelineState();
}

class _MiniTimelineState extends State<_MiniTimeline> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (prev, next) =>
          prev.position != next.position || prev.duration != next.duration,
      builder: (context, state) {
        final sliderMax = state.duration.inMilliseconds.toDouble();
        final effectiveMax = sliderMax <= 0 ? 1.0 : sliderMax;
        final streamValue = sliderMax == 0
            ? 0.0
            : state.position.inMilliseconds
                  .clamp(0, sliderMax.toInt())
                  .toDouble();
        final sliderValue =
            (_dragging ? _dragValue.clamp(0, effectiveMax) : streamValue)
                .toDouble();

        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: sliderValue,
              max: effectiveMax,
              semanticFormatterCallback: (value) =>
                  '播放进度 ${_format(Duration(milliseconds: value.round()))}',
              onChangeStart: (value) {
                setState(() {
                  _dragging = true;
                  _dragValue = value;
                });
              },
              onChanged: (value) {
                setState(() => _dragValue = value);
              },
              onChangeEnd: (value) {
                context.read<PlayerCubit>().seek(
                  Duration(milliseconds: value.round()),
                );
                // seek 会 emit 新的 position，BlocBuilder 重建时 _dragging
                // 已为 false，sliderValue 会用 seek 后的 streamValue。
                setState(() => _dragging = false);
              },
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlaybackModeButton extends StatelessWidget {
  const _MiniPlaybackModeButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (prev, next) =>
          prev.loopMode != next.loopMode ||
          prev.shuffleEnabled != next.shuffleEnabled,
      builder: (context, state) {
        final mode = state.playbackMode;
        final selected = mode != PlaybackModeOption.sequence;
        return IconButton(
          onPressed: context.read<PlayerCubit>().cyclePlaybackMode,
          tooltip: '播放模式：${_playbackModeLabel(mode)}，点击切换',
          style: AppActionButtonStyle.icon(
            context,
            selected: selected,
            size: 32,
            iconSize: 18,
          ),
          icon: Icon(_playbackModeIcon(mode)),
        );
      },
    );
  }
}

class _MiniControlButton extends StatefulWidget {
  const _MiniControlButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.tooltip,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final String? tooltip;
  final bool compact;

  @override
  State<_MiniControlButton> createState() => _MiniControlButtonState();
}

class _MiniControlButtonState extends State<_MiniControlButton> {
  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 40.0 : 36.0;
    return IconButton(
      onPressed: widget.onPressed,
      tooltip: widget.tooltip,
      style: AppActionButtonStyle.icon(
        context,
        tone: widget.isPrimary
            ? AppActionButtonTone.primary
            : AppActionButtonTone.neutral,
        size: size,
        iconSize: widget.compact ? 20 : 18,
      ),
      icon: Icon(widget.icon),
    );
  }
}

IconData _playbackModeIcon(PlaybackModeOption mode) {
  return switch (mode) {
    PlaybackModeOption.sequence => Icons.swap_horiz_rounded,
    PlaybackModeOption.loopAll => Icons.repeat_on_rounded,
    PlaybackModeOption.loopOne => Icons.repeat_one_on_rounded,
    PlaybackModeOption.shuffle => Icons.shuffle_rounded,
  };
}

String _playbackModeLabel(PlaybackModeOption mode) {
  return switch (mode) {
    PlaybackModeOption.sequence => '顺序播放',
    PlaybackModeOption.loopAll => '列表循环',
    PlaybackModeOption.loopOne => '单曲循环',
    PlaybackModeOption.shuffle => '随机播放',
  };
}

int _volumePercent(double volume) => (volume.clamp(0, 1) * 100).round();

String _format(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

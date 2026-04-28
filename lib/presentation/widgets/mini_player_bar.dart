import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
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
        final colorScheme = Theme.of(context).colorScheme;
        final artworkSourceContext = ArtworkSourceContext.track(track);

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingTokens.miniPlayerOuterHorizontal,
              AppSpacingTokens.miniPlayerOuterTop,
              AppSpacingTokens.miniPlayerOuterHorizontal,
              isWide
                  ? AppSpacingTokens.miniPlayerOuterBottomWide
                  : AppSpacingTokens.miniPlayerOuterBottomCompact,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadiusTokens.card),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.75),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacingTokens.miniPlayerInnerHorizontal,
                  isWide
                      ? AppSpacingTokens.miniPlayerInnerVerticalWide
                      : AppSpacingTokens.miniPlayerInnerVerticalCompact,
                  AppSpacingTokens.miniPlayerInnerHorizontal,
                  AppSpacingTokens.miniPlayerInnerVerticalWide,
                ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactMiniPlayer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: '展开全屏播放器',
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadiusTokens.card),
                  onTap: () => PlayerNavigation.openPlayerPage(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        CachedArtwork(
                          imageUrl: artworkUrl,
                          size: 52,
                          borderRadius: 20,
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
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
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
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacingTokens.miniPlayerControlGap),
            _MiniControlButton(
              icon: Icons.skip_previous_rounded,
              onPressed: context.read<PlayerCubit>().previous,
              tooltip: '上一曲',
            ),
            const SizedBox(width: AppSpacingTokens.miniPlayerControlGap),
            BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.isPlaying != next.isPlaying,
              builder: (context, s) => _MiniControlButton(
                icon: s.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onPressed: context.read<PlayerCubit>().togglePlayback,
                isPrimary: true,
                tooltip: s.isPlaying ? '暂停' : '播放',
              ),
            ),
            const SizedBox(width: AppSpacingTokens.miniPlayerControlGap),
            _MiniControlButton(
              icon: Icons.skip_next_rounded,
              onPressed: context.read<PlayerCubit>().next,
              tooltip: '下一曲',
            ),
          ],
        ),
        const SizedBox(height: AppSpacingTokens.miniPlayerSectionGap),
        const Row(
          children: [
            Expanded(child: _MiniTimeline()),
            SizedBox(width: AppSpacingTokens.miniPlayerSectionGap),
            _MiniPlaybackModeButton(compact: true),
          ],
        ),
      ],
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
        Expanded(
          flex: 4,
          child: Semantics(
            label: '展开全屏播放器',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => PlayerNavigation.openPlayerPage(context),
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: artworkUrl,
                    size: 56,
                    borderRadius: 22,
                    sourceContext: sourceContext,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trackTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
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
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _MiniTimeline(),
              const SizedBox(height: 6),
              BlocBuilder<PlayerCubit, PlayerViewState>(
                buildWhen: (prev, next) =>
                    prev.position != next.position ||
                    prev.duration != next.duration,
                builder: (context, tlState) => Row(
                  children: [
                    Text(
                      _format(tlState.position),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      _format(tlState.duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        _MiniControlButton(
          icon: Icons.skip_previous_rounded,
          onPressed: context.read<PlayerCubit>().previous,
          tooltip: '上一曲',
        ),
        const SizedBox(width: 8),
        BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) => prev.isPlaying != next.isPlaying,
          builder: (context, s) => _MiniControlButton(
            icon: s.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onPressed: context.read<PlayerCubit>().togglePlayback,
            isPrimary: true,
            tooltip: s.isPlaying ? '暂停' : '播放',
          ),
        ),
        const SizedBox(width: 8),
        _MiniControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: context.read<PlayerCubit>().next,
          tooltip: '下一曲',
        ),
        const SizedBox(width: 8),
        const _MiniPlaybackModeButton(),
        const SizedBox(width: 12),
        SizedBox(
          width: 132,
          child: Row(
            children: [
              const Tooltip(
                message: '音量',
                child: Icon(Icons.volume_up_rounded, size: 18),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: BlocBuilder<PlayerCubit, PlayerViewState>(
                  buildWhen: (prev, next) => prev.volume != next.volume,
                  builder: (context, s) => Slider(
                    value: s.volume,
                    onChanged: context.read<PlayerCubit>().setVolume,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => PlayerNavigation.openPlayerPage(context),
          icon: const Icon(Icons.open_in_full_rounded),
          tooltip: '展开播放器',
        ),
      ],
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
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: sliderValue,
              max: effectiveMax,
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
  const _MiniPlaybackModeButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (prev, next) =>
          prev.loopMode != next.loopMode ||
          prev.shuffleEnabled != next.shuffleEnabled,
      builder: (context, state) {
        final mode = state.playbackMode;
        final selected = mode != PlaybackModeOption.sequence;
        final foregroundColor = selected
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;
        final button = IconButton.filled(
          onPressed: context.read<PlayerCubit>().cyclePlaybackMode,
          tooltip: '播放模式：${_playbackModeLabel(mode)}，点击切换',
          style: IconButton.styleFrom(
            backgroundColor: selected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            foregroundColor: foregroundColor,
            minimumSize: Size.square(compact ? 38 : 42),
            maximumSize: Size.square(compact ? 38 : 42),
            padding: EdgeInsets.zero,
            iconSize: compact ? 18 : 20,
          ),
          icon: Icon(_playbackModeIcon(mode)),
        );

        if (!compact) {
          return button;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button,
            const SizedBox(height: 2),
            Text(
              _playbackModeShortLabel(mode),
              style: theme.textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniControlButton extends StatelessWidget {
  const _MiniControlButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: isPrimary
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        foregroundColor: isPrimary
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        minimumSize: Size.square(isPrimary ? 50 : 42),
        iconSize: isPrimary ? 24 : 20,
      ),
      icon: Icon(icon),
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

String _playbackModeShortLabel(PlaybackModeOption mode) {
  return switch (mode) {
    PlaybackModeOption.sequence => '顺序',
    PlaybackModeOption.loopAll => '循环',
    PlaybackModeOption.loopOne => '单曲',
    PlaybackModeOption.shuffle => '随机',
  };
}

String _format(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

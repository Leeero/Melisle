import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/effects/glass_container.dart';
import 'package:cross_platform_music_player/presentation/widgets/loading_play_pause_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/queue_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MiniPlayerPlaybackStatus { idle, loading, playing, paused, failed }

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
        if (track == null) return const SizedBox.shrink();
        final width = MediaQuery.sizeOf(context).width;
        final isWide = AppBreakpoints.usesDesktopShellWidth(width);
        final artworkSourceContext = ArtworkSourceContext.track(track);
        final trackTitle = MediaDisplayText.trackTitle(track.title);
        final artistName = MediaDisplayText.artistName(track.artistName);

        return _MiniPlayerFrame(
          isWide: isWide,
          child: isWide
              ? _WideMiniPlayer(
                  trackTitle: trackTitle,
                  artistName: artistName,
                  artworkUrl: track.artworkUrl,
                  sourceContext: artworkSourceContext,
                  qualityLabel: _qualityLabel(track),
                )
              : _CompactMiniPlayer(
                  trackTitle: trackTitle,
                  artistName: artistName,
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
    return BlocSelector<PlayerCubit, PlayerViewState, MiniPlayerPlaybackStatus>(
      selector: _playbackStatus,
      builder: (context, status) => Semantics(
        container: true,
        label: _playbackStatusLabel(status),
        liveRegion:
            status == MiniPlayerPlaybackStatus.loading ||
            status == MiniPlayerPlaybackStatus.failed,
        child: _MiniPlayerSurface(isWide: isWide, status: status, child: child),
      ),
    );
  }
}

class _MiniPlayerSurface extends StatelessWidget {
  const _MiniPlayerSurface({
    required this.isWide,
    required this.status,
    required this.child,
  });

  final bool isWide;
  final MiniPlayerPlaybackStatus status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isWide) {
      return SizedBox(
        height: AppSpacingTokens.desktopMiniPlayerHeight.toDouble(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? AppShadowTokens.darkBorder
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
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

    final failed = status == MiniPlayerPlaybackStatus.failed;
    final paused = status == MiniPlayerPlaybackStatus.paused;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: AppSpacingTokens.mobileMiniPlayerHeight.toDouble(),
        child: GlassContainer(
          blurRadius: 24,
          opacity: paused ? 0.70 : 0.85,
          borderRadius: BorderRadius.circular(AppRadiusTokens.miniPlayer),
          border: Border.all(
            color: failed
                ? colorScheme.error.withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.10),
          ),
          tintColor: failed
              ? colorScheme.errorContainer.withValues(alpha: 0.30)
              : null,
          child: Opacity(
            opacity: paused ? 0.80 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

MiniPlayerPlaybackStatus _playbackStatus(PlayerViewState state) {
  if (state.currentTrack == null) return MiniPlayerPlaybackStatus.idle;
  if (state.errorMessage != null) return MiniPlayerPlaybackStatus.failed;
  if (state.isLoading) return MiniPlayerPlaybackStatus.loading;
  if (state.isPlaying) return MiniPlayerPlaybackStatus.playing;
  return MiniPlayerPlaybackStatus.paused;
}

String _playbackStatusLabel(MiniPlayerPlaybackStatus status) {
  return switch (status) {
    MiniPlayerPlaybackStatus.idle => '迷你播放器：未在播放',
    MiniPlayerPlaybackStatus.loading => '迷你播放器：正在缓冲',
    MiniPlayerPlaybackStatus.playing => '迷你播放器：正在播放',
    MiniPlayerPlaybackStatus.paused => '迷你播放器：已暂停',
    MiniPlayerPlaybackStatus.failed => '迷你播放器：播放失败',
  };
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

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (previous, current) =>
          previous.isPlaying != current.isPlaying ||
          previous.isLoading != current.isLoading ||
          previous.errorMessage != current.errorMessage ||
          previous.sleepRemaining != current.sleepRemaining ||
          previous.sleepEndOfTrack != current.sleepEndOfTrack ||
          previous.position != current.position ||
          previous.duration != current.duration,
      builder: (context, state) {
        final failed = state.errorMessage != null;
        final subtitle = failed
            ? state.errorMessage!
            : state.isLoading
            ? '正在缓冲…'
            : state.sleepRemaining != null
            ? '${_formatSleepRemaining(state.sleepRemaining!)} 后停止'
            : state.sleepEndOfTrack
            ? '本曲结束后停止'
            : widget.artistName;
        return Semantics(
          label: '当前播放：${widget.trackTitle}，$subtitle。点击展开播放页。',
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -250) context.read<PlayerCubit>().next();
              if (velocity > 250) context.read<PlayerCubit>().previous();
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => PlayerNavigation.openPlayerPage(context),
                mouseCursor: SystemMouseCursors.click,
                onHighlightChanged: (value) => setState(() => _pressed = value),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: AnimatedScale(
                  duration: AppMotion.micro,
                  curve: AppMotion.standard,
                  scale: _pressed ? 0.992 : 1,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: _CompactProgressBar(
                          failed: failed,
                          loading: state.isLoading,
                          position: state.position,
                          duration: state.duration,
                        ),
                      ),
                      Row(
                        children: [
                          _CompactArtwork(
                            imageUrl: widget.artworkUrl,
                            sourceContext: widget.sourceContext,
                            failed: failed,
                            loading: state.isLoading,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.trackTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                    height: 18 / 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: failed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: failed
                                        ? theme.colorScheme.onSurface
                                              .withValues(alpha: 0.50)
                                        : null,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: failed
                                        ? theme.colorScheme.error
                                        : state.isLoading
                                        ? theme.colorScheme.secondary
                                        : state.sleepRemaining != null ||
                                              state.sleepEndOfTrack
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (failed)
                            const _MiniRetryButton()
                          else
                            LoadingPlayPauseButton(
                              isLoading: state.isLoading,
                              isPlaying: state.isPlaying,
                              onPressed: context
                                  .read<PlayerCubit>()
                                  .togglePlayback,
                              size: 36,
                              iconSize: 20,
                              loadingStrokeWidth: 2.0,
                            ),
                          _MiniControlButton(
                            icon: Icons.skip_next_rounded,
                            onPressed: state.isLoading
                                ? null
                                : context.read<PlayerCubit>().next,
                            compact: true,
                            tooltip: '下一曲',
                          ),
                        ],
                      ),
                    ],
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

class _CompactArtwork extends StatelessWidget {
  const _CompactArtwork({
    required this.imageUrl,
    required this.sourceContext,
    required this.failed,
    required this.loading,
  });

  final String imageUrl;
  final ArtworkSourceContext sourceContext;
  final bool failed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: failed
              ? 0.50
              : loading
              ? 0.70
              : 1,
          child: ColorFiltered(
            colorFilter: failed
                ? ColorFilter.mode(
                    AppColorTokens.desaturatedGrey,
                    BlendMode.saturation,
                  )
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: CachedArtwork(
              imageUrl: imageUrl,
              size: 32,
              borderRadius: AppRadiusTokens.sm,
              sourceContext: sourceContext,
            ),
          ),
        ),
        if (failed)
          Icon(
            Icons.error_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }
}

class _CompactProgressBar extends StatelessWidget {
  const _CompactProgressBar({
    required this.failed,
    required this.loading,
    required this.position,
    required this.duration,
  });

  final bool failed;
  final bool loading;
  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final total = duration.inMilliseconds;
    final progress = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          value: loading ? null : progress,
          color: failed ? colors.error : colors.primary,
          backgroundColor: failed
              ? colors.error.withValues(alpha: 0.20)
              : colors.surfaceContainerHighest,
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
    required this.qualityLabel,
  });

  final String trackTitle;
  final String artistName;
  final String artworkUrl;
  final ArtworkSourceContext sourceContext;
  final String qualityLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: _MiniTrackButton(
                  trackTitle: trackTitle,
                  artistName: artistName,
                  artworkUrl: artworkUrl,
                  sourceContext: sourceContext,
                ),
              ),
              const SizedBox(width: 8),
              const _MiniFavoriteButton(),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniTransportControls(),
                SizedBox(height: 2),
                _MiniTimelineBlock(showElapsedLabels: true),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactControls = constraints.maxWidth < 270;
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!compactControls) ...[
                    _MiniQualityBadge(label: qualityLabel),
                    const SizedBox(width: 8),
                  ],
                  _MiniControlButton(
                    icon: Icons.queue_music_rounded,
                    onPressed: () => _showMiniQueueSheet(context),
                    tooltip: '当前歌单',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniFavoriteButton extends StatelessWidget {
  const _MiniFavoriteButton();

  @override
  Widget build(BuildContext context) {
    final track = context.select<PlayerCubit, MusicTrack?>(
      (cubit) => cubit.state.currentTrack,
    );
    if (track == null) return const SizedBox.shrink();
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        final isFavorite = state.entries[track.id] ?? track.isFavorite;
        return IconButton(
          onPressed: () => context.read<FavoritesCubit>().toggle(
            track.id,
            currentValue: isFavorite,
          ),
          tooltip: isFavorite ? '取消收藏' : '收藏',
          style: AppActionButtonStyle.icon(
            context,
            selected: isFavorite,
            size: 44,
            iconSize: 20,
          ),
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
        );
      },
    );
  }
}

class _MiniQualityBadge extends StatelessWidget {
  const _MiniQualityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qualityColor = theme.colorScheme.secondary;
    return Semantics(
      label: '音质：$label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: qualityColor.withValues(alpha: 0.78)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: qualityColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
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
        BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) => prev.isPlaying != next.isPlaying,
          builder: (context, state) {
            return AnimatedContainer(
              duration: AppMotion.micro,
              width: 3,
              height: state.isPlaying ? 20 : 10,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: state.isPlaying
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          },
        ),
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
        mouseCursor: SystemMouseCursors.click,
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
    const gap = 16.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _MiniPlaybackModeButton(),
        SizedBox(width: gap),
        BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) =>
              prev.isLoading != next.isLoading ||
              prev.errorMessage != next.errorMessage,
          builder: (context, state) => _MiniControlButton(
            icon: Icons.skip_previous_rounded,
            onPressed: state.isLoading || state.errorMessage != null
                ? null
                : context.read<PlayerCubit>().previous,
            tooltip: '上一曲',
          ),
        ),
        SizedBox(width: gap),
        BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) =>
              prev.isPlaying != next.isPlaying ||
              prev.isLoading != next.isLoading ||
              prev.errorMessage != next.errorMessage,
          builder: (context, state) => state.errorMessage != null
              ? const _MiniRetryButton()
              : LoadingPlayPauseButton(
                  isLoading: state.isLoading,
                  isPlaying: state.isPlaying,
                  onPressed: context.read<PlayerCubit>().togglePlayback,
                  size: 40,
                  iconSize: 24,
                  loadingStrokeWidth: 2.4,
                ),
        ),
        SizedBox(width: gap),
        BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) =>
              prev.isLoading != next.isLoading ||
              prev.errorMessage != next.errorMessage,
          builder: (context, state) => _MiniControlButton(
            icon: Icons.skip_next_rounded,
            onPressed: state.isLoading || state.errorMessage != null
                ? null
                : context.read<PlayerCubit>().next,
            tooltip: '下一曲',
          ),
        ),
        SizedBox(width: gap),
        const _MiniVolumePopoverButton(),
      ],
    );
  }
}

class _MiniPlaybackModeButton extends StatelessWidget {
  const _MiniPlaybackModeButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (previous, current) =>
          previous.shuffleEnabled != current.shuffleEnabled ||
          previous.loopMode != current.loopMode,
      builder: (context, state) {
        final mode = state.playbackMode;
        return _MiniControlButton(
          icon: _playbackModeIcon(mode),
          onPressed: context.read<PlayerCubit>().cyclePlaybackMode,
          tooltip: '播放模式：${_playbackModeLabel(mode)}，点击切换',
          selected: mode != PlaybackModeOption.sequence,
        );
      },
    );
  }
}

class _MiniVolumePopoverButton extends StatefulWidget {
  const _MiniVolumePopoverButton();

  @override
  State<_MiniVolumePopoverButton> createState() =>
      _MiniVolumePopoverButtonState();
}

class _MiniVolumePopoverButtonState extends State<_MiniVolumePopoverButton> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, -8),
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.card),
          ),
        ),
      ),
      menuChildren: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _MiniVolumePopoverContent(),
        ),
      ],
      builder: (context, controller, child) {
        return BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (previous, current) => previous.volume != current.volume,
          builder: (context, state) => _MiniControlButton(
            icon: _volumeIcon(state.volume),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            tooltip: '调节音量',
            selected: controller.isOpen,
          ),
        );
      },
    );
  }
}

class _MiniVolumePopoverContent extends StatelessWidget {
  const _MiniVolumePopoverContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: 208,
      child: BlocBuilder<PlayerCubit, PlayerViewState>(
        buildWhen: (previous, current) => previous.volume != current.volume,
        builder: (context, state) => Row(
          children: [
            Icon(_volumeIcon(state.volume), color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: state.volume,
                semanticFormatterCallback: (value) =>
                    '音量 ${_volumePercent(value)}%',
                onChanged: context.read<PlayerCubit>().setVolume,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(
                '${_volumePercent(state.volume)}%',
                textAlign: TextAlign.end,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRetryButton extends StatelessWidget {
  const _MiniRetryButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: '重试播放',
        onPressed: context.read<PlayerCubit>().togglePlayback,
        style: AppActionButtonStyle.icon(
          context,
          tone: AppActionButtonTone.danger,
          size: 44,
          iconSize: 20,
        ),
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

class _MiniTimelineBlock extends StatelessWidget {
  const _MiniTimelineBlock({this.showElapsedLabels = false});

  final bool showElapsedLabels;

  @override
  Widget build(BuildContext context) {
    if (!showElapsedLabels) return const _MiniTimeline();
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (prev, next) =>
          prev.position != next.position || prev.duration != next.duration,
      builder: (context, state) => Row(
        children: [
          Text(
            _format(state.position),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 12),
          const Expanded(child: _MiniTimeline()),
          const SizedBox(width: 12),
          Text(
            _format(state.duration),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
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

        return SizedBox(
          height: 18,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 9),
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
                  setState(() => _dragging = false);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniControlButton extends StatefulWidget {
  const _MiniControlButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.compact = false,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool compact;
  final bool selected;

  @override
  State<_MiniControlButton> createState() => _MiniControlButtonState();
}

class _MiniControlButtonState extends State<_MiniControlButton> {
  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 28.0 : 36.0;
    return IconButton(
      onPressed: widget.onPressed,
      tooltip: widget.tooltip,
      style: AppActionButtonStyle.icon(
        context,
        tone: AppActionButtonTone.neutral,
        selected: widget.selected,
        size: size,
        iconSize: widget.compact ? 14 : 16,
      ),
      icon: Icon(widget.icon, size: widget.compact ? 14 : 16),
    );
  }
}

String _qualityLabel(MusicTrack track) {
  final codec = (track.codec ?? track.container ?? '').toLowerCase();
  if (codec == 'flac' || codec == 'alac' || codec == 'wav') return '无损音质';
  if ((track.bitRate ?? 0) >= 300000) return '高品质';
  return '标准音质';
}

String _formatSleepRemaining(Duration remaining) {
  final minutes = remaining.inMinutes;
  final seconds = remaining.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

int _volumePercent(double volume) => (volume.clamp(0, 1) * 100).round();

IconData _playbackModeIcon(PlaybackModeOption mode) {
  return switch (mode) {
    PlaybackModeOption.sequence ||
    PlaybackModeOption.loopAll => Icons.repeat_rounded,
    PlaybackModeOption.loopOne => Icons.repeat_one_rounded,
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

IconData _volumeIcon(double volume) {
  if (volume <= 0.001) return Icons.volume_off_rounded;
  if (volume < 0.5) return Icons.volume_down_rounded;
  return Icons.volume_up_rounded;
}

String _format(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

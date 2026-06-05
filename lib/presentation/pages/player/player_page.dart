import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/lyric_view.dart';
import 'package:cross_platform_music_player/presentation/widgets/quality_picker_sheet.dart';
import 'package:cross_platform_music_player/presentation/widgets/queue_sheet.dart';
import 'package:cross_platform_music_player/presentation/widgets/sleep_timer_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      // Edge-to-edge: 让状态栏和导航栏透明，内容延伸到系统 UI 下方。
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      // 离开播放页后恢复默认系统 UI 模式。
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<PlayerCubit, PlayerViewState>(
        buildWhen: (prev, next) =>
            prev.currentTrack?.id != next.currentTrack?.id ||
            prev.currentIndex != next.currentIndex ||
            prev.sleepRemaining != next.sleepRemaining ||
            prev.sleepEndOfTrack != next.sleepEndOfTrack,
        builder: (context, state) {
          final track = state.currentTrack;
          if (track == null) {
            return const _EmptyPlayerState();
          }

          final artworkSourceContext = ArtworkSourceContext.track(track);
          return Stack(
            fit: StackFit.expand,
            children: [
              BlurredCoverBackground(
                imageUrl: track.artworkUrl,
                sourceContext: artworkSourceContext,
              ),
              SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = AppBreakpoints.usesWideContentWidth(
                      constraints.maxWidth,
                    );
                    if (isWide) {
                      return _DesktopLayout(state: state, track: track);
                    }
                    return _MobileLayout(state: state, track: track);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile layout — fullscreen stack: artwork, lyrics, controls, extras
// ---------------------------------------------------------------------------

class _MobileLayout extends StatefulWidget {
  const _MobileLayout({required this.state, required this.track});

  final PlayerViewState state;
  final MusicTrack track;

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  static const _horizontalSwipeThreshold = 72.0;
  static const _verticalDismissThreshold = 80.0;
  static const _axisDominance = 1.35;

  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            _PlayerTopBar(
              compact: true,
              onMorePressed: () =>
                  _showMobileMoreActionsSheet(context, track: widget.track),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacingTokens.playerHorizontalPadding,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: math.min(constraints.maxHeight * 0.36, 300),
                      child: _MobileSwipeGestureRegion(
                        onSwipeEnd: (details) => _handleSwipe(context, details),
                        onSwipeCancel: _resetSwipe,
                        onSwipeUpdate: _updateSwipe,
                        child: _MobileArtworkStage(track: widget.track),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MobileTrackInfo(track: widget.track),
                    const SizedBox(height: 14),
                    const Expanded(child: _MobileLyricView()),
                  ],
                ),
              ),
            ),
            _MobileSwipeGestureRegion(
              onSwipeEnd: (details) => _handleSwipe(context, details),
              onSwipeCancel: _resetSwipe,
              onSwipeUpdate: _updateSwipe,
              translucent: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacingTokens.playerHorizontalPadding,
                    ),
                    child: _ProgressTimeline(),
                  ),
                  const SizedBox(height: 12),
                  const _PlaybackControls(
                    showQueueButton: true,
                    subtleModeButton: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _MobileExtrasBar(track: widget.track),
            const SizedBox(height: AppSpacingTokens.playerToolbarGap),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        );
      },
    );
  }

  void _resetSwipe() {
    _dragOffset = Offset.zero;
  }

  void _updateSwipe(DragUpdateDetails details) {
    _dragOffset += details.delta;
  }

  void _handleSwipe(BuildContext context, DragEndDetails details) {
    final offset = _dragOffset;
    _resetSwipe();

    final horizontalDistance = offset.dx.abs();
    final verticalDistance = offset.dy.abs();

    final isHorizontalSwipe =
        horizontalDistance >= _horizontalSwipeThreshold &&
        horizontalDistance > verticalDistance * _axisDominance;
    if (isHorizontalSwipe) {
      HapticFeedback.selectionClick();
      final playerCubit = context.read<PlayerCubit>();
      if (offset.dx < 0) {
        playerCubit.next();
      } else {
        playerCubit.previous();
      }
      return;
    }

    final isDownwardDismiss =
        offset.dy >= _verticalDismissThreshold &&
        verticalDistance > horizontalDistance * _axisDominance;
    if (isDownwardDismiss) {
      HapticFeedback.lightImpact();
      Navigator.of(context).maybePop();
    }
  }
}

class _MobileSwipeGestureRegion extends StatelessWidget {
  const _MobileSwipeGestureRegion({
    required this.child,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
    required this.onSwipeCancel,
    this.translucent = true,
  });

  final Widget child;
  final ValueChanged<DragUpdateDetails> onSwipeUpdate;
  final ValueChanged<DragEndDetails> onSwipeEnd;
  final VoidCallback onSwipeCancel;
  final bool translucent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: translucent
          ? HitTestBehavior.translucent
          : HitTestBehavior.deferToChild,
      onPanStart: (_) => onSwipeCancel(),
      onPanUpdate: onSwipeUpdate,
      onPanCancel: onSwipeCancel,
      onPanEnd: onSwipeEnd,
      child: child,
    );
  }
}

class _MobileArtworkStage extends StatelessWidget {
  const _MobileArtworkStage({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final artworkSourceContext = ArtworkSourceContext.track(track);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math
              .min(constraints.maxWidth, constraints.maxHeight)
              .clamp(220.0, 280.0)
              .toDouble();
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadiusTokens.mobileXl),
              color: colorScheme.outlineVariant.withValues(alpha: 0.24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: CachedArtwork(
              imageUrl: track.artworkUrl,
              size: size,
              borderRadius: AppRadiusTokens.mobileXl,
              sourceContext: artworkSourceContext,
              semanticLabel: '《${track.title}》封面',
            ),
          );
        },
      ),
    );
  }
}

class _MobileLyricView extends StatelessWidget {
  const _MobileLyricView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (p, c) =>
          p.lyricSyncState.timeline != c.lyricSyncState.timeline ||
          p.lyricSyncState.activeIndex != c.lyricSyncState.activeIndex ||
          p.isLyricsLoading != c.isLyricsLoading,
      builder: (context, state) {
        if (state.isLyricsLoading && state.lyrics.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.lyrics.isEmpty) {
          return Center(
            child: Text(
              '暂无歌词',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final currentColor = Color.lerp(
          colorScheme.onSurface,
          theme.musicRose,
          theme.brightness == Brightness.dark ? 0.52 : 0.42,
        )!;
        final inactiveColor = colorScheme.onSurfaceVariant.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.62 : 0.56,
        );

        return LyricView(
          lines: state.lyrics,
          currentIndex: state.currentLyricIndex,
          textAlign: TextAlign.center,
          alignment: Alignment.center,
          maxTextWidth: 340,
          currentScale: 1.025,
          showCurrentLineButton: false,
          linePadding: const EdgeInsets.symmetric(vertical: 3),
          currentTextStyle: theme.textTheme.titleLarge?.copyWith(
            color: currentColor,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            height: 1.74,
            letterSpacing: 0,
          ),
          inactiveTextStyle: theme.textTheme.bodyLarge?.copyWith(
            color: inactiveColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 2.04,
            letterSpacing: 0,
          ),
          onLineTap: (i) => context.read<PlayerCubit>().seekToLyricIndex(i),
        );
      },
    );
  }
}

class _MobileTrackInfo extends StatelessWidget {
  const _MobileTrackInfo({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Column(
        key: ValueKey(track.id),
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            track.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileExtrasBar extends StatelessWidget {
  const _MobileExtrasBar({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.playerHorizontalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favState) {
              final isFav = favState.entries[track.id] ?? track.isFavorite;
              return _PlayerExtraIconButton(
                icon: isFav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                tooltip: isFav ? '取消收藏' : '收藏',
                active: isFav,
                onPressed: () => context.read<FavoritesCubit>().toggle(
                  track.id,
                  currentValue: isFav,
                ),
              );
            },
          ),
          _PlayerExtraIconButton(
            icon: Icons.volume_up_rounded,
            tooltip: '调节音量',
            onPressed: () => _showVolumeSheet(context),
          ),
          _PlayerExtraIconButton(
            icon: Icons.tune_rounded,
            tooltip: '播放设置',
            onPressed: () => QualityPickerSheet.show(context),
          ),
        ],
      ),
    );
  }
}

class _PlayerExtraIconButton extends StatelessWidget {
  const _PlayerExtraIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            side: BorderSide.none,
            foregroundColor: active
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            backgroundColor: Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout — immersive workspace: artwork | lyrics | queue preview
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.state, required this.track});

  final PlayerViewState state;
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return Column(
      children: [
        _PlayerTopBar(
          onMorePressed: () => _showDesktopMoreActionsDialog(context, track),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  14,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compactDesktop = constraints.maxWidth < 1220;
                          final majorGap = compactDesktop ? 28.0 : 54.0;
                          final minorGap = compactDesktop ? 20.0 : 34.0;
                          final queueWidth = compactDesktop ? 250.0 : 286.0;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 4,
                                child: _DesktopArtworkStage(track: track),
                              ),
                              SizedBox(width: majorGap),
                              Expanded(
                                flex: 5,
                                child: _DesktopLyricStage(track: track),
                              ),
                              SizedBox(width: minorGap),
                              SizedBox(
                                width: queueWidth,
                                child: const _DesktopQueuePreview(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DesktopBottomBar(track: track),
                    SizedBox(
                      height:
                          AppSpacingTokens.shellBottomInset +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopArtworkStage extends StatelessWidget {
  const _DesktopArtworkStage({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final artworkSourceContext = ArtworkSourceContext.track(track);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = math
                    .min(constraints.maxWidth, constraints.maxHeight * 0.88)
                    .clamp(300.0, 420.0)
                    .toDouble();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: colorScheme.outlineVariant.withValues(alpha: 0.24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.onSurface.withValues(alpha: 0.18),
                        blurRadius: 54,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: CachedArtwork(
                    imageUrl: track.artworkUrl,
                    size: size,
                    borderRadius: 26,
                    sourceContext: artworkSourceContext,
                    semanticLabel: '《${track.title}》封面',
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: AppMotion.medium,
          child: Column(
            key: ValueKey(track.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                track.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopLyricStage extends StatelessWidget {
  const _DesktopLyricStage({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (p, c) =>
          p.lyricSyncState.timeline != c.lyricSyncState.timeline ||
          p.lyricSyncState.activeIndex != c.lyricSyncState.activeIndex ||
          p.isLyricsLoading != c.isLyricsLoading,
      builder: (context, state) {
        if (state.isLyricsLoading && state.lyrics.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.lyrics.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lyrics_outlined,
                  size: 30,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  '暂无歌词',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return LyricView(
          lines: state.lyrics,
          currentIndex: state.currentLyricIndex,
          onLineTap: (i) => context.read<PlayerCubit>().seekToLyricIndex(i),
          textAlign: TextAlign.left,
          alignment: Alignment.centerLeft,
          maxTextWidth: 640,
          currentScale: 1.06,
        );
      },
    );
  }
}

class _DesktopQueuePreview extends StatelessWidget {
  const _DesktopQueuePreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '接下来',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              BlocBuilder<PlayerCubit, PlayerViewState>(
                buildWhen: (prev, next) =>
                    prev.queue != next.queue ||
                    prev.currentIndex != next.currentIndex,
                builder: (context, state) {
                  final nextItems = <({int index, MusicTrack track})>[
                    for (
                      var i = state.currentIndex + 1;
                      i < state.queue.length;
                      i++
                    )
                      (index: i, track: state.queue[i]),
                  ].take(6).toList();

                  if (nextItems.isEmpty) {
                    return Text(
                      '队列已到末尾',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in nextItems)
                        _DesktopQueuePreviewItem(
                          track: item.track,
                          onTap: () =>
                              context.read<PlayerCubit>().playIndex(item.index),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopQueuePreviewItem extends StatefulWidget {
  const _DesktopQueuePreviewItem({required this.track, required this.onTap});

  final MusicTrack track;
  final VoidCallback onTap;

  @override
  State<_DesktopQueuePreviewItem> createState() =>
      _DesktopQueuePreviewItemState();
}

class _DesktopQueuePreviewItemState extends State<_DesktopQueuePreviewItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hoverBackground = colorScheme.surface.withValues(alpha: 0.70);
    final idleBackground = hoverBackground.withValues(alpha: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          decoration: BoxDecoration(
            color: _hovered ? hoverBackground : idleBackground,
            borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
              hoverColor: Colors.transparent,
              focusColor: colorScheme.primary.withValues(alpha: 0.08),
              splashColor: colorScheme.primary.withValues(alpha: 0.06),
              highlightColor: Colors.transparent,
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    CachedArtwork(
                      imageUrl: widget.track.artworkUrl,
                      size: 34,
                      borderRadius: 9,
                      sourceContext: ArtworkSourceContext.track(widget.track),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.track.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _format(widget.track.duration),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.muted,
                        fontFeatures: [const ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopBottomBar extends StatelessWidget {
  const _DesktopBottomBar({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _ProgressTimeline(),
        ),
        const SizedBox(height: 10),
        _PlaybackControls(
          showQueueButton: true,
          onQueuePressed: () => _showDesktopQueueDialog(context),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _DesktopExtrasBar(track: track),
        ),
      ],
    );
  }
}

class _DesktopExtrasBar extends StatelessWidget {
  const _DesktopExtrasBar({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, favState) {
            final isFav = favState.entries[track.id] ?? track.isFavorite;
            return _PlayerExtraIconButton(
              icon: isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              tooltip: isFav ? '取消收藏' : '收藏',
              active: isFav,
              onPressed: () => context.read<FavoritesCubit>().toggle(
                track.id,
                currentValue: isFav,
              ),
            );
          },
        ),
        BlocBuilder<DownloadsCubit, DownloadsState>(
          buildWhen: (p, c) =>
              p.completedTrackIds.contains(track.id) !=
                  c.completedTrackIds.contains(track.id) ||
              p.jobs.containsKey(track.id) != c.jobs.containsKey(track.id),
          builder: (context, dlState) {
            final downloaded = dlState.completedTrackIds.contains(track.id);
            final running = dlState.jobs.containsKey(track.id);
            return _PlayerExtraIconButton(
              icon: downloaded
                  ? Icons.download_done_rounded
                  : running
                  ? Icons.downloading_rounded
                  : Icons.download_rounded,
              tooltip: downloaded
                  ? '已下载'
                  : running
                  ? '下载中'
                  : '下载',
              active: downloaded || running,
              onPressed: downloaded || running
                  ? () {}
                  : () => context.read<DownloadsCubit>().enqueue(track),
            );
          },
        ),
        const Spacer(),
        SizedBox(width: 132, child: _DesktopVolumeControl(compact: true)),
        const Spacer(),
        BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) =>
              prev.quality != next.quality ||
              prev.sleepRemaining != next.sleepRemaining ||
              prev.sleepEndOfTrack != next.sleepEndOfTrack,
          builder: (context, state) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlayerExtraIconButton(
                  icon: Icons.high_quality_rounded,
                  tooltip: '播放音质：${state.quality.label}',
                  active: state.quality != AudioQuality.auto,
                  onPressed: () => _showDesktopQualityDialog(context),
                ),
                _PlayerExtraIconButton(
                  icon: state.sleepRemaining != null || state.sleepEndOfTrack
                      ? Icons.bedtime_rounded
                      : Icons.bedtime_outlined,
                  tooltip: '睡眠定时',
                  active: state.sleepRemaining != null || state.sleepEndOfTrack,
                  onPressed: () => _showDesktopSleepTimerDialog(context),
                ),
              ],
            );
          },
        ),
        _PlayerExtraIconButton(
          icon: Icons.queue_music_rounded,
          tooltip: '播放队列',
          onPressed: () => _showDesktopQueueDialog(context),
        ),
      ],
    );
  }
}

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({this.onMorePressed, this.compact = false});

  final VoidCallback? onMorePressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDesktopMac =
        Platform.isMacOS &&
        !AppBreakpoints.isCompactWidth(MediaQuery.sizeOf(context).width);
    final leftPadding = _playerTopBarEdgePadding(context);
    final rightPadding = AppPageLayout.horizontalPadding(
      context,
    ).clamp(12.0, 24.0).toDouble();
    final morePressed = onMorePressed;
    final theme = Theme.of(context);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacingTokens.playerHorizontalPadding,
          6,
          AppSpacingTokens.playerHorizontalPadding,
          8,
        ),
        child: Row(
          children: [
            _ControlButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: () => Navigator.of(context).pop(),
              tooltip: '返回',
              size: 44,
              iconSize: 24,
            ),
            Expanded(
              child: Text(
                '正在播放',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (morePressed != null)
              _ControlButton(
                icon: Icons.more_horiz_rounded,
                onTap: morePressed,
                tooltip: '更多设置',
                size: 44,
                iconSize: 22,
              )
            else
              const SizedBox.square(dimension: 44),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding,
        right: rightPadding,
        top: 6,
        bottom: 6,
      ),
      child: morePressed == null
          ? Align(
              alignment: isDesktopMac
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: _PlayerTopBarIconButton(
                icon: Icons.keyboard_arrow_down_rounded,
                tooltip: '收起',
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : Row(
              children: [
                _PlayerTopBarIconButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip: '收起',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    '正在播放',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _PlayerTopBarIconButton(
                  icon: Icons.more_horiz_rounded,
                  tooltip: '更多操作',
                  onPressed: morePressed,
                ),
              ],
            ),
    );
  }
}

class _PlayerTopChrome extends StatelessWidget {
  const _PlayerTopChrome({
    required this.leading,
    required this.center,
    required this.trailing,
    required this.colorScheme,
  });

  final Widget leading;
  final Widget center;
  final List<Widget> trailing;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final trailingWidgets = trailing
        .where((widget) => widget is! SizedBox)
        .toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(child: center),
            if (trailingWidgets.isNotEmpty) ...[
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: trailingWidgets,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerEmptyTopBarStatus extends StatelessWidget {
  const _PlayerEmptyTopBarStatus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '播放器',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
            letterSpacing: 0.3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '等待开始播放',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlayerTopBarIconButton extends StatelessWidget {
  const _PlayerTopBarIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      tooltip: tooltip,
      color: colorScheme.onSurface,
      style: IconButton.styleFrom(
        side: BorderSide.none,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.16),
        disabledBackgroundColor: colorScheme.surface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
          alpha: 0.56,
        ),
      ),
    );
  }
}

double _playerTopBarEdgePadding(BuildContext context) {
  final needsTrafficLightPadding = Platform.isMacOS;
  final basePadding = AppPageLayout.horizontalPadding(
    context,
  ).clamp(12.0, 24.0).toDouble();
  return basePadding + (needsTrafficLightPadding ? 42 : 0);
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    this.showQueueButton = false,
    this.subtleModeButton = false,
    this.onQueuePressed,
  });

  final bool showQueueButton;
  final bool subtleModeButton;
  final VoidCallback? onQueuePressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (prev, next) =>
          prev.isPlaying != next.isPlaying ||
          prev.isLoading != next.isLoading ||
          prev.shuffleEnabled != next.shuffleEnabled ||
          prev.loopMode != next.loopMode,
      builder: (context, s) {
        final playbackMode = s.playbackMode;
        const controlGap = 12.0;
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = showQueueButton ? 350.0 : 292.0;
            final width = constraints.hasBoundedWidth
                ? math.min(constraints.maxWidth, maxWidth)
                : maxWidth;
            return SizedBox(
              width: width,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _PlaybackModeButton(
                          mode: playbackMode,
                          subtle: subtleModeButton,
                          onTap: context.read<PlayerCubit>().cyclePlaybackMode,
                        ),
                        const SizedBox(width: controlGap),
                        _ControlButton(
                          icon: Icons.skip_previous_rounded,
                          onTap: context.read<PlayerCubit>().previous,
                          tooltip: '上一曲',
                          size: 46,
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: controlGap),
                  _ControlButton(
                    icon: s.isLoading
                        ? Icons.downloading_rounded
                        : (s.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                    isPrimary: true,
                    size: 56,
                    iconSize: 28,
                    onTap: context.read<PlayerCubit>().togglePlayback,
                    tooltip: s.isPlaying ? '暂停' : '播放',
                  ),
                  const SizedBox(width: controlGap),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _ControlButton(
                          icon: Icons.skip_next_rounded,
                          onTap: context.read<PlayerCubit>().next,
                          tooltip: '下一曲',
                          size: 46,
                          iconSize: 24,
                        ),
                        if (showQueueButton) ...[
                          const SizedBox(width: controlGap),
                          _ControlButton(
                            icon: Icons.queue_music_rounded,
                            onTap: () {
                              final handler = onQueuePressed;
                              if (handler != null) {
                                handler();
                                return;
                              }
                              QueueSheet.show(context);
                            },
                            tooltip: '播放队列',
                            size: 46,
                            iconSize: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PlaybackModeButton extends StatefulWidget {
  const _PlaybackModeButton({
    required this.mode,
    required this.onTap,
    this.subtle = false,
  });

  final PlaybackModeOption mode;
  final VoidCallback onTap;
  final bool subtle;

  @override
  State<_PlaybackModeButton> createState() => _PlaybackModeButtonState();
}

class _PlaybackModeButtonState extends State<_PlaybackModeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobileStyle = widget.subtle;
    final isActiveMode = widget.mode != PlaybackModeOption.sequence;

    if (isMobileStyle) {
      return _ControlButton(
        icon: _playbackModeIcon(widget.mode),
        onTap: widget.onTap,
        tooltip: '播放模式：${_playbackModeLabel(widget.mode)}，点击切换',
        size: 46,
        iconSize: 22,
        active: isActiveMode,
      );
    }

    final foregroundColor = isActiveMode
        ? colorScheme.primary
        : (_hovered ? colorScheme.onSurface : colorScheme.onSurfaceVariant);

    return Tooltip(
      message: '播放模式：${_playbackModeLabel(widget.mode)}，点击切换',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _hovered ? 1.04 : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.button),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: AppMotion.micro,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isActiveMode
                      ? colorScheme.primaryContainer.withValues(
                          alpha: _hovered ? 0.74 : 0.58,
                        )
                      : (_hovered
                            ? colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.58,
                              )
                            : colorScheme.surface.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(AppRadiusTokens.button),
                  border: Border.all(
                    color: isActiveMode
                        ? colorScheme.primary.withValues(
                            alpha: _hovered ? 0.32 : 0.22,
                          )
                        : colorScheme.outlineVariant.withValues(
                            alpha: _hovered ? 0.34 : 0.22,
                          ),
                  ),
                  boxShadow: [
                    if (_hovered)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Icon(
                  _playbackModeIcon(widget.mode),
                  size: 19,
                  color: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopVolumeControl extends StatelessWidget {
  const _DesktopVolumeControl({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (prev, next) => prev.volume != next.volume,
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _volumeIcon(state.volume),
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.2,
                  activeTrackColor: colorScheme.primary.withValues(alpha: 0.92),
                  inactiveTrackColor: colorScheme.onSurface.withValues(
                    alpha: 0.14,
                  ),
                  thumbShape: _PlayerSliderThumbShape(
                    radius: 4.8,
                    fillColor: colorScheme.surface,
                    ringColor: colorScheme.primary,
                    glowColor: colorScheme.primary,
                    glowAlpha: 0.12,
                  ),
                  overlayColor: colorScheme.primary.withValues(alpha: 0.1),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  trackShape: _GlowingSliderTrackShape(
                    glowColor: colorScheme.primary,
                    glowAlpha: 0.1,
                    blurSigma: 6,
                  ),
                ),
                child: Slider(
                  value: state.volume,
                  semanticFormatterCallback: (value) =>
                      '音量 ${_volumePercent(value)}%',
                  onChanged: context.read<PlayerCubit>().setVolume,
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${_volumePercent(state.volume)}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: [const ui.FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VolumeSheet extends StatelessWidget {
  const _VolumeSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppSheetScaffold(
      title: '音量',
      description: '拖动滑杆调整当前播放音量。',
      trailing: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('完成'),
      ),
      child: BlocBuilder<PlayerCubit, PlayerViewState>(
        buildWhen: (prev, next) => prev.volume != next.volume,
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_volumeIcon(state.volume), color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: colorScheme.primary.withValues(
                          alpha: 0.94,
                        ),
                        inactiveTrackColor: colorScheme.onSurface.withValues(
                          alpha: 0.14,
                        ),
                        thumbShape: _PlayerSliderThumbShape(
                          radius: 5.8,
                          fillColor: colorScheme.surface,
                          ringColor: colorScheme.primary,
                          glowColor: colorScheme.primary,
                          glowAlpha: 0.16,
                        ),
                        overlayColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        trackShape: _GlowingSliderTrackShape(
                          glowColor: colorScheme.primary,
                          glowAlpha: 0.12,
                          blurSigma: 7,
                        ),
                      ),
                      child: Slider(
                        value: state.volume,
                        semanticFormatterCallback: (value) =>
                            '音量 ${_volumePercent(value)}%',
                        onChanged: context.read<PlayerCubit>().setVolume,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${_volumePercent(state.volume)}%',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFeatures: [const ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

void _showVolumeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: const _VolumeSheet(),
    ),
  );
}

Future<void> _showMobileMoreActionsSheet(
  BuildContext context, {
  required MusicTrack track,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<PlayerCubit>()),
        BlocProvider.value(value: context.read<DownloadsCubit>()),
      ],
      child: _MobileMoreActionsSheet(parentContext: context, track: track),
    ),
  );
}

class _MobileMoreActionsSheet extends StatelessWidget {
  const _MobileMoreActionsSheet({
    required this.parentContext,
    required this.track,
  });

  final BuildContext parentContext;
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AppSheetScaffold(
        title: '更多操作',
        description: '管理当前曲目的下载、音质、音量和睡眠定时。',
        trailing: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('完成'),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<DownloadsCubit, DownloadsState>(
              buildWhen: (p, c) =>
                  p.completedTrackIds.contains(track.id) !=
                      c.completedTrackIds.contains(track.id) ||
                  p.jobs.containsKey(track.id) != c.jobs.containsKey(track.id),
              builder: (context, downloadState) {
                final downloaded = downloadState.completedTrackIds.contains(
                  track.id,
                );
                final running = downloadState.jobs.containsKey(track.id);
                return AppOptionTile<_MobileMoreAction>(
                  icon: downloaded
                      ? Icons.download_done_rounded
                      : running
                      ? Icons.downloading_rounded
                      : Icons.download_rounded,
                  title: downloaded
                      ? '已下载'
                      : running
                      ? '下载中'
                      : '下载当前曲目',
                  subtitle: downloaded
                      ? '这首歌已经可离线播放'
                      : running
                      ? '正在加入离线缓存'
                      : '保存到本地，离线时优先播放',
                  value: _MobileMoreAction.download,
                  groupValue: _MobileMoreAction.none,
                  showRadio: false,
                  enabled: !downloaded && !running,
                  onSelected: (_) async {
                    await context.read<DownloadsCubit>().enqueue(track);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            ),
            BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.quality != next.quality,
              builder: (context, state) => AppOptionTile<_MobileMoreAction>(
                icon: Icons.high_quality_rounded,
                title: '播放音质：${state.quality.label}',
                subtitle: '下一首起生效；无损取决于源文件',
                value: _MobileMoreAction.quality,
                groupValue: _MobileMoreAction.none,
                showRadio: false,
                onSelected: (_) => _openNestedSheet(
                  context,
                  () => QualityPickerSheet.show(parentContext),
                ),
              ),
            ),
            BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) =>
                  prev.sleepRemaining != next.sleepRemaining ||
                  prev.sleepEndOfTrack != next.sleepEndOfTrack,
              builder: (context, state) {
                final remaining = state.sleepRemaining;
                final subtitle = state.sleepEndOfTrack
                    ? '将在本曲结束后暂停'
                    : remaining != null
                    ? '剩余 ${_formatSleep(remaining)}'
                    : '时间到后自动暂停播放';
                return AppOptionTile<_MobileMoreAction>(
                  icon: remaining != null || state.sleepEndOfTrack
                      ? Icons.bedtime_rounded
                      : Icons.bedtime_outlined,
                  title: '睡眠定时',
                  subtitle: subtitle,
                  value: _MobileMoreAction.sleep,
                  groupValue: _MobileMoreAction.none,
                  showRadio: false,
                  onSelected: (_) => _openNestedSheet(
                    context,
                    () => SleepTimerSheet.show(parentContext),
                  ),
                );
              },
            ),
            BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.volume != next.volume,
              builder: (context, state) => AppOptionTile<_MobileMoreAction>(
                icon: _volumeIcon(state.volume),
                title: '音量 ${_volumePercent(state.volume)}%',
                subtitle: '调节当前输出强度',
                value: _MobileMoreAction.volume,
                groupValue: _MobileMoreAction.none,
                showRadio: false,
                onSelected: (_) => _openNestedSheet(
                  context,
                  () async => _showVolumeSheet(parentContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNestedSheet(BuildContext context, Future<void> Function() open) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (parentContext.mounted) {
        open();
      }
    });
  }
}

enum _MobileMoreAction { none, download, quality, sleep, volume }

Future<void> _showDesktopPopover(BuildContext context, Widget child) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: '关闭面板',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          alignment: Alignment.bottomRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

Future<void> _showDesktopSidePanel(BuildContext context, Widget child) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: '关闭面板',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

Future<void> _showDesktopSleepTimerDialog(BuildContext context) {
  return _showDesktopPopover(
    context,
    BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: const _DesktopSleepTimerDialog(),
    ),
  );
}

Future<void> _showDesktopQueueDialog(BuildContext context) {
  return _showDesktopSidePanel(
    context,
    BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: const _DesktopQueueDialog(),
    ),
  );
}

Future<void> _showDesktopQualityDialog(BuildContext context) {
  return _showDesktopPopover(
    context,
    BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: const _DesktopQualityDialog(),
    ),
  );
}

Future<void> _showDesktopMoreActionsDialog(
  BuildContext context,
  MusicTrack track,
) {
  return _showDesktopPopover(
    context,
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<PlayerCubit>()),
        BlocProvider.value(value: context.read<FavoritesCubit>()),
        BlocProvider.value(value: context.read<DownloadsCubit>()),
      ],
      child: _DesktopMoreActionsDialog(parentContext: context, track: track),
    ),
  );
}

class _DesktopMoreActionsDialog extends StatelessWidget {
  const _DesktopMoreActionsDialog({
    required this.parentContext,
    required this.track,
  });

  final BuildContext parentContext;
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 108),
          child: Material(
            color: Colors.transparent,
            child: _DesktopPopoverSurface(
              width: 348,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesktopPopoverHeader(
                    icon: Icons.more_horiz_rounded,
                    title: '更多操作',
                    subtitle: track.title,
                    trailing: _DesktopPopoverCloseButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, favState) {
                      final isFav =
                          favState.entries[track.id] ?? track.isFavorite;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DesktopPopoverOptionRow(
                          icon: isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          title: isFav ? '取消收藏' : '收藏歌曲',
                          subtitle: '同步到私人收藏',
                          selected: isFav,
                          onTap: () {
                            context.read<FavoritesCubit>().toggle(
                              track.id,
                              currentValue: isFav,
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                  BlocBuilder<DownloadsCubit, DownloadsState>(
                    buildWhen: (p, c) =>
                        p.completedTrackIds.contains(track.id) !=
                            c.completedTrackIds.contains(track.id) ||
                        p.jobs.containsKey(track.id) !=
                            c.jobs.containsKey(track.id),
                    builder: (context, dlState) {
                      final downloaded = dlState.completedTrackIds.contains(
                        track.id,
                      );
                      final running = dlState.jobs.containsKey(track.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DesktopPopoverOptionRow(
                          icon: downloaded
                              ? Icons.download_done_rounded
                              : running
                              ? Icons.downloading_rounded
                              : Icons.download_rounded,
                          title: downloaded
                              ? '已下载'
                              : running
                              ? '下载中'
                              : '下载当前歌曲',
                          subtitle: downloaded
                              ? '这首歌已经可离线播放'
                              : running
                              ? '正在加入离线缓存'
                              : '保存到本机离线播放',
                          selected: downloaded || running,
                          onTap: downloaded || running
                              ? () => Navigator.of(context).pop()
                              : () async {
                                  await context.read<DownloadsCubit>().enqueue(
                                    track,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DesktopPopoverOptionRow(
                      icon: Icons.high_quality_rounded,
                      title: '播放音质',
                      subtitle: '选择当前服务可用音质',
                      onTap: () => _openDesktopNestedPopover(
                        context,
                        () => _showDesktopQualityDialog(parentContext),
                      ),
                    ),
                  ),
                  _DesktopPopoverOptionRow(
                    icon: Icons.bedtime_outlined,
                    title: '睡眠定时',
                    subtitle: '到点后自动暂停播放',
                    onTap: () => _openDesktopNestedPopover(
                      context,
                      () => _showDesktopSleepTimerDialog(parentContext),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDesktopNestedPopover(
    BuildContext context,
    Future<void> Function() open,
  ) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (parentContext.mounted) {
        open();
      }
    });
  }
}

class _DesktopPopoverSurface extends StatelessWidget {
  const _DesktopPopoverSurface({
    required this.width,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
  });

  final double width;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.68),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 48,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DesktopPopoverHeader extends StatelessWidget {
  const _DesktopPopoverHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.meta,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.46,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(width: 8),
                      _DesktopPopoverBadge(label: meta!),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.muted,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _DesktopPopoverBadge extends StatelessWidget {
  const _DesktopPopoverBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DesktopPopoverCloseButton extends StatelessWidget {
  const _DesktopPopoverCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      tooltip: '关闭',
      style: IconButton.styleFrom(
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.32,
        ),
        foregroundColor: colorScheme.onSurfaceVariant,
        fixedSize: const Size.square(36),
        iconSize: 19,
      ),
      icon: const Icon(Icons.close_rounded),
    );
  }
}

class _DesktopPopoverOptionRow extends StatefulWidget {
  const _DesktopPopoverOptionRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final bool selected;
  final bool destructive;
  final VoidCallback onTap;

  @override
  State<_DesktopPopoverOptionRow> createState() =>
      _DesktopPopoverOptionRowState();
}

class _DesktopPopoverOptionRowState extends State<_DesktopPopoverOptionRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = widget.selected;
    final toneColor = widget.destructive
        ? colorScheme.error
        : colorScheme.primary;
    final hoverBackground = theme.hoverWash.withValues(alpha: 0.56);
    final pressedBackground = theme.hoverWash.withValues(alpha: 0.78);
    final idleBackground = hoverBackground.withValues(alpha: 0);
    final backgroundColor = selected
        ? theme.selectedWash.withValues(alpha: 0.72)
        : _pressed
        ? pressedBackground
        : _hovered
        ? hoverBackground
        : idleBackground;
    final borderColor = selected
        ? toneColor.withValues(alpha: 0.26)
        : colorScheme.outlineVariant.withValues(alpha: _hovered ? 0.30 : 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        duration: AppMotion.micro,
        curve: AppMotion.standard,
        scale: _pressed ? 0.992 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: AppMotion.micro,
            curve: AppMotion.standard,
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color: selected ? toneColor : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: widget.destructive
                              ? colorScheme.error
                              : colorScheme.onSurface,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (selected)
                  Icon(Icons.check_rounded, size: 18, color: toneColor)
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.56),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSleepTimerDialog extends StatelessWidget {
  const _DesktopSleepTimerDialog();

  static const _presets = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 108),
          child: Material(
            color: Colors.transparent,
            child: BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) =>
                  prev.sleepRemaining != next.sleepRemaining ||
                  prev.sleepEndOfTrack != next.sleepEndOfTrack,
              builder: (context, state) {
                final remaining = state.sleepRemaining;
                final active = remaining != null || state.sleepEndOfTrack;
                final cubit = context.read<PlayerCubit>();

                return _DesktopPopoverSurface(
                  width: 360,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DesktopPopoverHeader(
                        icon: active
                            ? Icons.bedtime_rounded
                            : Icons.bedtime_outlined,
                        title: '睡眠定时',
                        subtitle: '启用后将在指定时间或本曲结束后暂停播放。',
                        meta: state.sleepEndOfTrack
                            ? '本曲结束后'
                            : remaining != null
                            ? '剩余 ${_formatSleep(remaining)}'
                            : '未启用',
                        trailing: _DesktopPopoverCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final preset in _presets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DesktopPopoverOptionRow(
                            icon: Icons.timer_rounded,
                            title: '${preset.inMinutes} 分钟',
                            subtitle: '到点后自动暂停播放',
                            onTap: () async {
                              await cubit.startSleepTimer(preset);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      _DesktopPopoverOptionRow(
                        icon: Icons.skip_next_rounded,
                        title: '本曲结束后',
                        subtitle: '当前歌曲播放完毕后暂停',
                        selected: state.sleepEndOfTrack,
                        onTap: () async {
                          await cubit.startSleepTimerEndOfTrack();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      if (active) ...[
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _DesktopPopoverOptionRow(
                          icon: Icons.alarm_off_rounded,
                          title: '取消睡眠定时',
                          subtitle: '恢复持续播放',
                          destructive: true,
                          onTap: () async {
                            await cubit.cancelSleepTimer();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopQualityDialog extends StatelessWidget {
  const _DesktopQualityDialog();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 108),
          child: Material(
            color: Colors.transparent,
            child: BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.quality != next.quality,
              builder: (context, state) {
                return _DesktopPopoverSurface(
                  width: 348,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DesktopPopoverHeader(
                        icon: Icons.high_quality_rounded,
                        title: '播放音质',
                        subtitle: '切换后会从下一首开始生效。',
                        meta: state.quality.label,
                        trailing: _DesktopPopoverCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final quality in AudioQuality.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DesktopPopoverOptionRow(
                            icon: Icons.high_quality_rounded,
                            title: quality.label,
                            subtitle: _qualityDescription(quality),
                            selected: quality == state.quality,
                            onTap: () async {
                              await context.read<PlayerCubit>().setQuality(
                                quality,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopQueueDialog extends StatefulWidget {
  const _DesktopQueueDialog();

  @override
  State<_DesktopQueueDialog> createState() => _DesktopQueueDialogState();
}

class _DesktopQueueDialogState extends State<_DesktopQueueDialog> {
  bool _confirmingClear = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _DesktopQueueSurface(
              width: 360,
              child: Column(
                children: [
                  BlocBuilder<PlayerCubit, PlayerViewState>(
                    buildWhen: (prev, next) =>
                        prev.queue.length != next.queue.length ||
                        prev.currentIndex != next.currentIndex ||
                        prev.isPlaying != next.isPlaying,
                    builder: (context, state) {
                      return _DesktopQueueHeader(
                        count: state.queue.length,
                        confirmingClear: _confirmingClear,
                        onClearPressed: state.queue.isEmpty
                            ? null
                            : () {
                                if (_confirmingClear) {
                                  context.read<PlayerCubit>().clearQueue();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                  return;
                                }

                                setState(() => _confirmingClear = true);
                              },
                        onCancelClear: _confirmingClear
                            ? () => setState(() => _confirmingClear = false)
                            : null,
                        onClosePressed: () => Navigator.of(context).pop(),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.24),
                  ),
                  Expanded(
                    child: BlocBuilder<PlayerCubit, PlayerViewState>(
                      buildWhen: (prev, next) =>
                          prev.queue != next.queue ||
                          prev.currentIndex != next.currentIndex ||
                          prev.isPlaying != next.isPlaying,
                      builder: (context, state) {
                        if (state.queue.isEmpty) {
                          return const _DesktopQueueEmptyState();
                        }

                        return ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                          buildDefaultDragHandles: false,
                          itemExtent: 60,
                          proxyDecorator: _desktopQueueProxyDecorator,
                          itemCount: state.queue.length,
                          onReorder: context.read<PlayerCubit>().moveQueueItem,
                          itemBuilder: (context, index) {
                            final track = state.queue[index];
                            final isCurrent = index == state.currentIndex;
                            return _DesktopQueueItem(
                              key: ValueKey('desktop-queue-${track.id}-$index'),
                              index: index,
                              track: track,
                              isCurrent: isCurrent,
                              isPlaying: state.isPlaying,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _desktopQueueProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return Transform.translate(
          offset: Offset(0, -2 * t),
          child: Transform.scale(
            scale: 1.0 + 0.01 * t,
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _DesktopQueueSurface extends StatelessWidget {
  const _DesktopQueueSurface({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.74),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 42,
            offset: const Offset(-14, 0),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DesktopQueueHeader extends StatelessWidget {
  const _DesktopQueueHeader({
    required this.count,
    required this.confirmingClear,
    required this.onClearPressed,
    required this.onCancelClear,
    required this.onClosePressed,
  });

  final int count;
  final bool confirmingClear;
  final VoidCallback? onClearPressed;
  final VoidCallback? onCancelClear;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '播放队列',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count 首',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.muted,
                    fontFeatures: [const ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (confirmingClear)
            TextButton(onPressed: onCancelClear, child: const Text('取消')),
          if (count > 0)
            TextButton(
              onPressed: onClearPressed,
              child: Text(confirmingClear ? '确认清空' : '清空'),
            ),
          IconButton(
            onPressed: onClosePressed,
            tooltip: '关闭',
            style: IconButton.styleFrom(
              minimumSize: const Size.square(28),
              fixedSize: const Size.square(28),
              padding: EdgeInsets.zero,
              side: BorderSide.none,
              backgroundColor: Colors.transparent,
              foregroundColor: colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DesktopQueueItem extends StatefulWidget {
  const _DesktopQueueItem({
    super.key,
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
  });

  final int index;
  final MusicTrack track;
  final bool isCurrent;
  final bool isPlaying;

  @override
  State<_DesktopQueueItem> createState() => _DesktopQueueItemState();
}

class _DesktopQueueItemState extends State<_DesktopQueueItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = [
      widget.track.artistName,
      if (widget.track.albumTitle.isNotEmpty) widget.track.albumTitle,
    ].where((value) => value.isNotEmpty).join(' · ');
    final hoverBackground = colorScheme.outlineVariant.withValues(alpha: 0.34);
    final idleBackground = hoverBackground.withValues(alpha: 0);

    final baseColor = widget.isCurrent
        ? colorScheme.primaryContainer.withValues(alpha: 0.58)
        : _hovered
        ? hoverBackground
        : idleBackground;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
            hoverColor: Colors.transparent,
            focusColor: colorScheme.primary.withValues(alpha: 0.08),
            splashColor: colorScheme.primary.withValues(alpha: 0.06),
            highlightColor: Colors.transparent,
            onTap: () async {
              await context.read<PlayerCubit>().playIndex(widget.index);
            },
            child: AnimatedContainer(
              duration: AppMotion.micro,
              curve: Curves.easeOutQuart,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: widget.track.artworkUrl,
                    size: 40,
                    borderRadius: AppRadiusTokens.desktopSm,
                    sourceContext: ArtworkSourceContext.track(widget.track),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: widget.isCurrent
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: AppMotion.micro,
                    child: _hovered
                        ? Row(
                            key: const ValueKey('queue-actions'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => context
                                    .read<PlayerCubit>()
                                    .removeQueueItem(widget.index),
                                tooltip: '移出队列',
                                style: IconButton.styleFrom(
                                  minimumSize: const Size.square(28),
                                  fixedSize: const Size.square(28),
                                  padding: EdgeInsets.zero,
                                  side: BorderSide.none,
                                  foregroundColor: colorScheme.onSurfaceVariant,
                                ),
                                icon: const Icon(Icons.close_rounded, size: 16),
                              ),
                              _DesktopQueueDragHandle(
                                index: widget.index,
                                colorScheme: colorScheme,
                              ),
                            ],
                          )
                        : Text(
                            key: const ValueKey('queue-duration'),
                            _format(widget.track.duration),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.muted,
                              fontFeatures: [
                                const ui.FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
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

class _DesktopQueueDragHandle extends StatelessWidget {
  const _DesktopQueueDragHandle({
    required this.index,
    required this.colorScheme,
  });

  final int index;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '拖拽排序',
      button: true,
      child: Tooltip(
        message: '拖拽排序',
        child: ReorderableDragStartListener(
          index: index,
          child: SizedBox.square(
            dimension: 28,
            child: Center(
              child: Icon(
                Icons.drag_handle_rounded,
                size: 17,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopQueueEmptyState extends StatelessWidget {
  const _DesktopQueueEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: 46,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.42),
            ),
            const SizedBox(height: 12),
            Text(
              '当前播放队列为空',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '从音乐库选择歌曲后，队列会在这里持续显示。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressTimeline extends StatefulWidget {
  const _ProgressTimeline();

  @override
  State<_ProgressTimeline> createState() => _ProgressTimelineState();
}

class _ProgressTimelineState extends State<_ProgressTimeline> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (prev, next) =>
          prev.position != next.position || prev.duration != next.duration,
      builder: (context, tlState) {
        final sliderMax = tlState.duration.inMilliseconds.toDouble();
        final effectiveMax = sliderMax <= 0 ? 1.0 : sliderMax;
        final streamValue = sliderMax == 0
            ? 0.0
            : tlState.position.inMilliseconds
                  .clamp(0, sliderMax.toInt())
                  .toDouble();
        final sliderValue =
            (_dragging ? _dragValue.clamp(0, effectiveMax) : streamValue)
                .toDouble();
        final displayPosition = _dragging
            ? Duration(milliseconds: _dragValue.round())
            : tlState.position;

        return Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                _format(displayPosition),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFeatures: [const ui.FontFeature.tabularFigures()],
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.5,
                  activeTrackColor: colorScheme.primary.withValues(alpha: 0.96),
                  inactiveTrackColor: colorScheme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.16)
                      : colorScheme.outlineVariant.withValues(alpha: 0.42),
                  thumbShape: _PlayerSliderThumbShape(
                    radius: _dragging ? 6.4 : 5.2,
                    fillColor: colorScheme.surface,
                    ringColor: colorScheme.primary,
                    glowColor: colorScheme.primary,
                    glowAlpha: _dragging ? 0.26 : 0.18,
                  ),
                  overlayColor: colorScheme.primary.withValues(alpha: 0.12),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: _dragging ? 18 : 15,
                  ),
                  trackShape: _GlowingSliderTrackShape(
                    glowColor: colorScheme.primary,
                    glowAlpha: _dragging ? 0.24 : 0.16,
                    blurSigma: _dragging ? 10 : 8,
                  ),
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
            SizedBox(
              width: 38,
              child: Text(
                _format(tlState.duration),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFeatures: [const ui.FontFeature.tabularFigures()],
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Control button
// ---------------------------------------------------------------------------

class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.tooltip,
    this.size,
    this.iconSize,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final String? tooltip;
  final double? size;
  final double? iconSize;
  final bool active;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scale = _pressed ? 0.96 : (_hovered ? 1.035 : 1.0);
    final btnSize = widget.size ?? (widget.isPrimary ? 60 : 42);
    final icnSize = widget.iconSize ?? (widget.isPrimary ? 30 : 22);
    final neutralHoverBackground = colorScheme.outlineVariant.withValues(
      alpha: 0.48,
    );
    final neutralPressedBackground = colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.66);
    final neutralIdleBackground = neutralHoverBackground.withValues(alpha: 0);

    final backgroundColor = widget.isPrimary
        ? Color.alphaBlend(
            theme.musicRose.withValues(alpha: 0.12),
            colorScheme.onSurface,
          )
        : (_pressed
              ? neutralPressedBackground
              : (_hovered ? neutralHoverBackground : neutralIdleBackground));
    final foregroundColor = widget.isPrimary
        ? colorScheme.surface
        : widget.active
        ? colorScheme.primary
        : (_hovered || _pressed
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant);

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          duration: AppMotion.micro,
          curve: AppMotion.standard,
          scale: scale,
          child: _buildButtonBody(
            btnSize,
            backgroundColor,
            foregroundColor,
            icnSize,
            colorScheme,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }

  Widget _buildButtonBody(
    double btnSize,
    Color backgroundColor,
    Color foregroundColor,
    double icnSize,
    ColorScheme colorScheme,
  ) {
    final neutralBorderColor = colorScheme.outlineVariant.withValues(
      alpha: _hovered || _pressed ? 0.32 : 0,
    );

    return AnimatedContainer(
      duration: AppMotion.micro,
      curve: AppMotion.standard,
      width: btnSize,
      height: btnSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: widget.isPrimary ? null : Border.all(color: neutralBorderColor),
        boxShadow: [
          if (widget.isPrimary)
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.18 : 0.10),
              blurRadius: _hovered ? 18 : 12,
              offset: const Offset(0, 5),
            ),
          if (!widget.isPrimary && _hovered)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Center(
        child: Icon(widget.icon, size: icnSize, color: foregroundColor),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glowing slider track
// ---------------------------------------------------------------------------

class _PlayerSliderThumbShape extends SliderComponentShape {
  const _PlayerSliderThumbShape({
    required this.radius,
    required this.fillColor,
    required this.ringColor,
    required this.glowColor,
    this.glowAlpha = 0.16,
  });

  final double radius;
  final Color fillColor;
  final Color ringColor;
  final Color glowColor;
  final double glowAlpha;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius + 4);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: glowAlpha * enableAnimation.value)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.9);
    canvas.drawCircle(center, radius + 2.2, glowPaint);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, fillPaint);

    final ringPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius - 0.5, ringPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.2),
      radius * 0.24,
      highlightPaint,
    );
  }
}

/// Custom slider track that paints a soft glow beneath the active segment.
class _GlowingSliderTrackShape extends RoundedRectSliderTrackShape {
  const _GlowingSliderTrackShape({
    required this.glowColor,
    this.glowAlpha = 0.18,
    this.blurSigma = 8,
  });

  final Color glowColor;
  final double glowAlpha;
  final double blurSigma;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final canvas = context.canvas;
    final preferredRect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      offset: offset,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final trackHeight = sliderTheme.trackHeight ?? 3.5;
    final trackLeft = preferredRect.left;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final activeWidth = thumbCenter.dx - trackLeft;

    if (activeWidth > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: glowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
      final glowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(trackLeft, trackTop - 2, activeWidth, trackHeight + 4),
        Radius.circular(trackHeight),
      );
      canvas.drawRRect(glowRect, glowPaint);
    }

    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );
  }
}

// ---------------------------------------------------------------------------
// Empty player state — immersive, matching the live player atmosphere
// ---------------------------------------------------------------------------

class _EmptyPlayerState extends StatelessWidget {
  const _EmptyPlayerState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 复用 BlurredCoverBackground（imageUrl 为 null 时自动生成
        // primary/secondary 渐变 + 光斑氛围，与有曲目时的背景风格一致）
        const BlurredCoverBackground(imageUrl: null),

        // 前景内容
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: _playerTopBarEdgePadding(context),
                  right: _playerTopBarEdgePadding(context),
                  top: 6,
                  bottom: 6,
                ),
                child: _PlayerTopChrome(
                  leading: _PlayerTopBarIconButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: '收起',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  center: const _PlayerEmptyTopBarStatus(),
                  trailing: const [],
                  colorScheme: colorScheme,
                ),
              ),

              // -- 主内容区：居中空状态信息 --
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 精致的音乐图标 — 使用柔和的容器包裹
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface.withValues(alpha: 0.18),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.22,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 36,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 标题
                      Text(
                        '还没有开始播放。',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 副标题引导
                      Text(
                        '去媒体库挑一首喜欢的歌曲吧',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      AppActionButton(
                        icon: Icons.library_music_rounded,
                        label: '返回浏览',
                        dense: false,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

String _qualityDescription(AudioQuality quality) {
  return switch (quality) {
    AudioQuality.auto => '按服务器配置透传原文件',
    AudioQuality.lossless => '优先保留 FLAC / ALAC 的完整细节',
    AudioQuality.high => '高码率有损，兼顾音质与带宽',
    AudioQuality.medium => '适合常规网络环境的平衡选择',
    AudioQuality.low => '弱网或流量受限时更稳定',
  };
}

IconData _volumeIcon(double volume) {
  if (volume <= 0.001) {
    return Icons.volume_off_rounded;
  }
  if (volume < 0.5) {
    return Icons.volume_down_rounded;
  }
  return Icons.volume_up_rounded;
}

int _volumePercent(double volume) => (volume.clamp(0, 1) * 100).round();

String _format(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatSleep(Duration remaining) {
  final m = remaining.inMinutes;
  final s = remaining.inSeconds.remainder(60);
  if (m > 0) return '$m分${s > 0 ? '$s秒' : ''}';
  return '$s秒';
}

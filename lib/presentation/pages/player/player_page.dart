import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

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
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/favorite_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/loading_play_pause_button.dart';
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
    if (Platform.isMacOS) {
      unawaited(_setMacosWindowButtonsVisibility(false));
    }
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
    if (Platform.isMacOS) {
      unawaited(_setMacosWindowButtonsVisibility(true));
    }
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

  Future<void> _setMacosWindowButtonsVisibility(bool visible) async {
    try {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: visible,
      );
    } catch (error, stackTrace) {
      debugPrint('PlayerPage: macOS 窗口按钮状态更新失败：$error\n$stackTrace');
    }
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
            prev.sleepEndOfTrack != next.sleepEndOfTrack ||
            prev.errorMessage != next.errorMessage,
        builder: (context, state) {
          final track = state.currentTrack;
          if (track == null) {
            return const _EmptyPlayerState();
          }

          final artworkSourceContext = ArtworkSourceContext.track(track);
          final compact = AppBreakpoints.isCompact(context);
          return Stack(
            fit: StackFit.expand,
            children: [
              BlurredCoverBackground(
                imageUrl: track.artworkUrl,
                sourceContext: artworkSourceContext,
                artworkOpacity: compact ? 0.22 : 0.28,
                blurSigma: compact ? 48 : 40,
                protectionStrength: compact ? 0.96 : 0.92,
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
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final artworkHeight = math.min(
          constraints.maxHeight * (textScale > 1.3 ? 0.28 : 0.36),
          textScale > 1.3 ? 220.0 : 300.0,
        );
        return Column(
          children: [
            _PlayerTopBar(
              compact: true,
              onMorePressed: () =>
                  _showMobileMoreActionsSheet(context, track: widget.track),
            ),
            if (widget.state.errorMessage case final message?)
              _PlayerFailureNotice(message: message),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacingTokens.playerHorizontalPadding,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: artworkHeight,
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
                    SizedBox(
                      height: textScale > 1.3 ? 176 : 156,
                      child: const _MobileLyricView(),
                    ),
                    const SizedBox(height: 8),
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
              .clamp(120.0, 280.0)
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

class _LyricLoadFailure extends StatelessWidget {
  const _LyricLoadFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lyrics_outlined, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<PlayerCubit>().reloadLyricsForCurrent(),
              child: const Text('重试'),
            ),
          ],
        ),
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
          p.isLyricsLoading != c.isLyricsLoading ||
          p.lyricErrorMessage != c.lyricErrorMessage ||
          p.queue != c.queue ||
          p.currentIndex != c.currentIndex,
      builder: (context, state) {
        if (state.isLyricsLoading && state.lyrics.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.lyricErrorMessage != null) {
          return _LyricLoadFailure(message: state.lyricErrorMessage!);
        }
        if (state.lyrics.isEmpty) {
          final nextIndex = state.currentIndex + 1;
          final nextTrack = nextIndex < state.queue.length
              ? state.queue[nextIndex]
              : null;
          return _NoLyricsPanel(nextTrack: nextTrack, nextIndex: nextIndex);
        }

        final theme = Theme.of(context);
        final currentColor = theme.lyricHighlight;
        final inactiveColor = theme.lyricInactive;

        return LyricView(
          key: ValueKey('lyrics-${state.currentTrack?.id ?? "none"}'),
          lines: state.lyrics,
          currentIndex: state.currentLyricIndex,
          textAlign: TextAlign.center,
          alignment: Alignment.center,
          maxTextWidth: 340,
          currentScale: 1.025,
          showCurrentLineButton: true,
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

class _NoLyricsPanel extends StatelessWidget {
  const _NoLyricsPanel({required this.nextTrack, required this.nextIndex});

  final MusicTrack? nextTrack;
  final int nextIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.mobileTheme;
    if (nextTrack == null) {
      return Center(
        child: Text(
          '暂无歌词',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      );
    }

    final track = nextTrack!;
    return Semantics(
      button: true,
      label: '下一首：${track.title}，${track.artistName}',
      child: Material(
        color: colors.surfaceMuted.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
        child: InkWell(
          onTap: () => context.read<PlayerCubit>().playIndex(nextIndex),
          borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CachedArtwork(
                  imageUrl: track.artworkUrl,
                  size: 54,
                  borderRadius: AppRadiusTokens.mobileSm,
                  sourceContext: ArtworkSourceContext.track(track),
                  semanticLabel: '《${track.title}》封面',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下一首',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
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
      duration: AppMotion.adaptive(context, AppMotion.state),
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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacingTokens.compactGap),
          Text(
            track.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
          Expanded(
            child: BlocBuilder<FavoritesCubit, FavoritesState>(
              builder: (context, favState) {
                final isFav = favState.entries[track.id] ?? track.isFavorite;
                return _MobileExtraAction(
                  label: isFav ? '已收藏' : '收藏',
                  child: FavoriteButton(
                    isFavorite: isFav,
                    onToggle: () => context.read<FavoritesCubit>().toggle(
                      track.id,
                      currentValue: isFav,
                    ),
                    size: 22,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _MobileExtraAction(
              label: '音量',
              child: _PlayerExtraIconButton(
                icon: Icons.volume_up_rounded,
                tooltip: '调节音量',
                onPressed: () => _showVolumeSheet(context),
              ),
            ),
          ),
          Expanded(
            child: _MobileExtraAction(
              label: '音质',
              child: _PlayerExtraIconButton(
                icon: Icons.tune_rounded,
                tooltip: '选择音质',
                onPressed: () => QualityPickerSheet.show(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileExtraAction extends StatelessWidget {
  const _MobileExtraAction({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        mouseCursor: SystemMouseCursors.click,
        style: AppActionButtonStyle.icon(
          context,
          selected: active,
          size: AppSpacingTokens.buttonHeight.toDouble(),
          iconSize: 20,
        ),
      ),
    );
  }
}

class _PlayerFailureNotice extends StatelessWidget {
  const _PlayerFailureNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacingTokens.pageHorizontalCompact,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadiusTokens.md),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: context.read<PlayerCubit>().togglePlayback,
              child: const Text('重试'),
            ),
            IconButton(
              tooltip: '下一曲',
              onPressed: context.read<PlayerCubit>().next,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout — immersive workspace: artwork | lyrics
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatefulWidget {
  const _DesktopLayout({required this.state, required this.track});

  final PlayerViewState state;
  final MusicTrack track;

  @override
  State<_DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<_DesktopLayout> {
  static const _inlineQueueBreakpoint = 1360.0;
  static const _inlineQueueWidth = 420.0;

  bool _queueVisible = false;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.74),
      ),
      child: Column(
        children: [
          _PlayerTopBar(
            onMorePressed: () =>
                _showDesktopMoreActionsDialog(context, widget.track),
          ),
          if (widget.state.errorMessage case final message?)
            _PlayerFailureNotice(message: message),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final supportsInlineQueue =
                    constraints.maxWidth >= _inlineQueueBreakpoint;
                final showInlineQueue = supportsInlineQueue && _queueVisible;
                return Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                28,
                                horizontalPadding,
                                28,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _DesktopArtworkStage(
                                      track: widget.track,
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                  const Expanded(
                                    flex: 6,
                                    child: _DesktopNowPlayingStage(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ClipRect(
                            child: AnimatedContainer(
                              key: const ValueKey('desktop-inline-queue'),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : AppMotion.normal,
                              curve: AppMotion.enter,
                              width: showInlineQueue ? _inlineQueueWidth : 0,
                              child: showInlineQueue
                                  ? OverflowBox(
                                      alignment: Alignment.centerLeft,
                                      minWidth: _inlineQueueWidth,
                                      maxWidth: _inlineQueueWidth,
                                      child: _DesktopInlineQueue(
                                        onClose: () => setState(
                                          () => _queueVisible = false,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DesktopBottomBar(
                      track: widget.track,
                      queueActive: showInlineQueue,
                      onQueuePressed: () {
                        if (!supportsInlineQueue) {
                          QueueSheet.show(context);
                          return;
                        }
                        setState(() => _queueVisible = !_queueVisible);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopArtworkStage extends StatelessWidget {
  const _DesktopArtworkStage({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final artworkSourceContext = ArtworkSourceContext.track(track);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, artworkConstraints) {
              final size = math
                  .min(
                    artworkConstraints.maxWidth,
                    artworkConstraints.maxHeight,
                  )
                  .clamp(0.0, 440.0)
                  .toDouble();
              return Center(
                child: Semantics(
                  image: true,
                  label: '《${track.title}》封面',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                      border: Border.all(
                        color: colorScheme.onSurface.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.34),
                          blurRadius: 46,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: CachedArtwork(
                      imageUrl: track.artworkUrl,
                      size: size,
                      borderRadius: AppRadiusTokens.lg,
                      sourceContext: artworkSourceContext,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          track.artistName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          track.albumTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BlocBuilder<FavoritesCubit, FavoritesState>(
              builder: (context, state) {
                final isFavorite = state.entries[track.id] ?? track.isFavorite;
                return _PlayerExtraIconButton(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  tooltip: isFavorite ? '取消收藏' : '收藏',
                  active: isFavorite,
                  onPressed: () => context.read<FavoritesCubit>().toggle(
                    track.id,
                    currentValue: isFavorite,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _DesktopFormatBadges(track: track),
          ],
        ),
      ],
    );
  }
}

class _DesktopNowPlayingStage extends StatelessWidget {
  const _DesktopNowPlayingStage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 9),
            Text(
              '正在播放',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Expanded(child: _DesktopLyricStage()),
      ],
    );
  }
}

class _DesktopInlineQueue extends StatelessWidget {
  const _DesktopInlineQueue({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        border: Border(
          left: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
      ),
      child: QueuePanel(onClose: onClose),
    );
  }
}

class _DesktopLyricStage extends StatelessWidget {
  const _DesktopLyricStage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (p, c) =>
          p.lyricSyncState.timeline != c.lyricSyncState.timeline ||
          p.lyricSyncState.activeIndex != c.lyricSyncState.activeIndex ||
          p.isLyricsLoading != c.isLyricsLoading ||
          p.lyricErrorMessage != c.lyricErrorMessage,
      builder: (context, state) {
        if (state.isLyricsLoading && state.lyrics.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.lyricErrorMessage != null) {
          return _LyricLoadFailure(message: state.lyricErrorMessage!);
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

        final currentColor = theme.lyricHighlight;
        final inactiveColor = theme.lyricInactive;

        return LyricView(
          key: ValueKey('lyrics-${state.currentTrack?.id ?? "none"}'),
          lines: state.lyrics,
          currentIndex: state.currentLyricIndex,
          onLineTap: (i) => context.read<PlayerCubit>().seekToLyricIndex(i),
          textAlign: TextAlign.left,
          alignment: Alignment.centerLeft,
          maxTextWidth: 672,
          currentScale: 1.05,
          linePadding: const EdgeInsets.symmetric(vertical: 10),
          currentTextStyle: theme.textTheme.headlineMedium?.copyWith(
            color: currentColor,
            fontSize: 32,
            height: 34 / 32,
            letterSpacing: 0,
          ),
          inactiveTextStyle: theme.textTheme.titleLarge?.copyWith(
            color: inactiveColor,
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        );
      },
    );
  }
}

class _DesktopBottomBar extends StatelessWidget {
  const _DesktopBottomBar({
    required this.track,
    required this.onQueuePressed,
    required this.queueActive,
  });

  final MusicTrack track;
  final VoidCallback onQueuePressed;
  final bool queueActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final footerColor = colorScheme.brightness == Brightness.dark
        ? AppColorTokens.darkPlayerFooter
        : AppColorTokens.lightPlayerFooter;
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    return Container(
      height: 148,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacingTokens.inlineGap,
        horizontalPadding,
        AppSpacingTokens.contentGap,
      ),
      decoration: BoxDecoration(
        color: footerColor.withValues(alpha: 0.80),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.48),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerWidth = math
              .min(640.0, constraints.maxWidth - 688)
              .clamp(292.0, 640.0)
              .toDouble();
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 280,
                  child: _DesktopTrackSummary(track: track),
                ),
              ),
              Center(
                child: SizedBox(
                  key: const ValueKey('desktop-player-center-stage'),
                  width: centerWidth,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PlaybackControls(subtleModeButton: true),
                      SizedBox(height: 10),
                      _ProgressTimeline(),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 328,
                  child: _DesktopFooterRight(
                    onQueuePressed: onQueuePressed,
                    queueActive: queueActive,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopTrackSummary extends StatelessWidget {
  const _DesktopTrackSummary({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final artistName = track.artistName.trim().isEmpty
        ? '未知歌手'
        : track.artistName.trim();

    return Semantics(
      container: true,
      label: '当前播放：${track.title}，歌手：$artistName',
      child: ExcludeSemantics(
        child: Row(
          children: [
            CachedArtwork(
              imageUrl: track.artworkUrl,
              size: 52,
              borderRadius: 8,
              sourceContext: ArtworkSourceContext.track(track),
              semanticLabel: '《${track.title}》封面',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.state,
                child: Column(
                  key: ValueKey(track.id),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopFooterRight extends StatelessWidget {
  const _DesktopFooterRight({
    required this.onQueuePressed,
    required this.queueActive,
  });

  final VoidCallback onQueuePressed;
  final bool queueActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(
            width: 128,
            child: _DesktopVolumeControl(compact: true),
          ),
          const SizedBox(width: 14),
          Container(
            width: 1,
            height: 32,
            color: colors.outlineVariant.withValues(alpha: 0.64),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: '播放队列',
            child: TextButton.icon(
              onPressed: onQueuePressed,
              style: TextButton.styleFrom(
                foregroundColor: queueActive
                    ? colors.primary
                    : colors.onSurfaceVariant,
                minimumSize: const Size(118, 44),
              ),
              icon: const Icon(Icons.queue_music_rounded, size: 20),
              label: const Text('播放队列'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopFormatBadges extends StatelessWidget {
  const _DesktopFormatBadges({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final codec = track.codec?.trim();
    final container = track.container?.trim();
    final format = codec != null && codec.isNotEmpty
        ? codec.toUpperCase()
        : container?.toUpperCase();
    final showHiRes = track.bitRate != null && track.bitRate! >= 1_000_000;
    final showFormat = format != null && format.isNotEmpty;
    if (!showHiRes && !showFormat) return const SizedBox.shrink();

    final warmGold = theme.musicWarm;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHiRes)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: warmGold),
              color: warmGold.withValues(alpha: 0.05),
            ),
            child: Text(
              'HI-RES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: warmGold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),
          ),
        if (showFormat)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outlineVariant),
              color: colorScheme.onSurface.withValues(alpha: 0.05),
            ),
            child: Text(
              format,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),
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
    final rightPadding = AppPageLayout.horizontalPadding(context);
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

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: _playerSurfaceColor(context).withValues(alpha: 0.30),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.50),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
        child: morePressed == null
            ? Align(
                alignment: isDesktopMac
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: _PlayerTopBarIconButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip: '收起播放页',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
            : Row(
                children: [
                  _PlayerTopBarIconButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: '收起播放页',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      '正在播放',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
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
        color: _playerSurfaceColor(context).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorTokens.overlayDark,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacingTokens.inlineGapCompact,
          vertical: AppSpacingTokens.inlineGap,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacingTokens.inlineGapCompact),
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
      mouseCursor: SystemMouseCursors.click,
      style:
          IconButton.styleFrom(
            fixedSize: const Size.square(44),
            minimumSize: const Size.square(44),
            maximumSize: const Size.square(44),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
            shape: const CircleBorder(),
            backgroundColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.onSurfaceVariant.withValues(alpha: 0.36);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed)) {
                return colorScheme.onSurface;
              }
              return colorScheme.onSurfaceVariant;
            }),
            side: const WidgetStatePropertyAll(BorderSide.none),
          ),
    );
  }
}

double _playerTopBarEdgePadding(BuildContext context) {
  return AppPageLayout.horizontalPadding(context);
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    this.showQueueButton = false,
    this.subtleModeButton = false,
  });

  final bool showQueueButton;
  final bool subtleModeButton;

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
        if (!showQueueButton && !subtleModeButton) {
          final colorScheme = Theme.of(context).colorScheme;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: _playbackModeIcon(playbackMode),
                onTap: context.read<PlayerCubit>().cyclePlaybackMode,
                tooltip: '播放模式：${_playbackModeLabel(playbackMode)}，点击切换',
                size: 44,
                iconSize: 22,
                active: playbackMode != PlaybackModeOption.sequence,
              ),
              const SizedBox(width: 16),
              _ControlButton(
                icon: Icons.skip_previous_rounded,
                onTap: context.read<PlayerCubit>().previous,
                tooltip: '上一曲',
                size: 56,
                iconSize: 32,
              ),
              const SizedBox(width: 16),
              LoadingPlayPauseButton(
                isLoading: s.isLoading,
                isPlaying: s.isPlaying,
                onPressed: context.read<PlayerCubit>().togglePlayback,
                size: 72,
                iconSize: 44,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              const SizedBox(width: 16),
              _ControlButton(
                icon: Icons.skip_next_rounded,
                onTap: context.read<PlayerCubit>().next,
                tooltip: '下一曲',
                size: 56,
                iconSize: 32,
              ),
            ],
          );
        }
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
                  LoadingPlayPauseButton(
                    isLoading: s.isLoading,
                    isPlaying: s.isPlaying,
                    onPressed: context.read<PlayerCubit>().togglePlayback,
                    size: 56,
                    iconSize: 28,
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
                            onTap: () => QueueSheet.show(context),
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
  @override
  Widget build(BuildContext context) {
    return _ControlButton(
      icon: _playbackModeIcon(widget.mode),
      onTap: widget.onTap,
      tooltip: '播放模式：${_playbackModeLabel(widget.mode)}，点击切换',
      size: 46,
      iconSize: widget.subtle ? 22 : 24,
      active: widget.mode != PlaybackModeOption.sequence,
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
                  trackHeight: 4,
                  activeTrackColor: colorScheme.primary.withValues(alpha: 0.92),
                  inactiveTrackColor: colorScheme.onSurface.withValues(
                    alpha: 0.14,
                  ),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                    disabledThumbRadius: 6,
                  ),
                  overlayColor: colorScheme.primary.withValues(alpha: 0.1),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
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
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                          disabledThumbRadius: 6,
                        ),
                        overlayColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
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
          alignment: Alignment.topRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.025),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

Future<void> _showDesktopSleepTimerDialog(
  BuildContext context, {
  MusicTrack? returnTrack,
}) {
  return _showDesktopPopover(
    context,
    BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: _DesktopSleepTimerDialog(
        onBack: returnTrack == null
            ? null
            : () => _returnToDesktopMoreActions(context, returnTrack),
      ),
    ),
  );
}

Future<void> _showDesktopQualityDialog(
  BuildContext context, {
  MusicTrack? returnTrack,
}) {
  return _showDesktopPopover(
    context,
    BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: _DesktopQualityDialog(
        onBack: returnTrack == null
            ? null
            : () => _returnToDesktopMoreActions(context, returnTrack),
      ),
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
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacingTokens.desktopMainContentPaddingX,
            AppSpacingTokens.sectionGap,
            AppSpacingTokens.desktopMainContentPaddingX,
            AppSpacingTokens.sectionPadding,
          ),
          child: Material(
            color: Colors.transparent,
            child: _DesktopPopoverSurface(
              width: 360,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesktopPopoverHeader(
                    title: '更多操作',
                    subtitle: track.title,
                    trailing: _DesktopPopoverCloseButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, favState) {
                      final isFav =
                          favState.entries[track.id] ?? track.isFavorite;
                      return _DesktopPopoverOptionRow(
                        icon: isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        title: isFav ? '已收藏' : '收藏',
                        selected: isFav,
                        onTap: () {
                          context.read<FavoritesCubit>().toggle(
                            track.id,
                            currentValue: isFav,
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                  const _DesktopPopoverDivider(),
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
                      return _DesktopPopoverOptionRow(
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
                            : '离线播放',
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
                      );
                    },
                  ),
                  if (track.albumId?.isNotEmpty ?? false)
                    _DesktopPopoverOptionRow(
                      icon: Icons.album_rounded,
                      title: '查看专辑',
                      showChevron: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        parentContext.push('/album/${track.albumId}');
                      },
                    ),
                  if (track.artistId?.isNotEmpty ?? false)
                    _DesktopPopoverOptionRow(
                      icon: Icons.person_rounded,
                      title: '查看歌手',
                      showChevron: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        parentContext.push('/artist/${track.artistId}');
                      },
                    ),
                  const _DesktopPopoverDivider(),
                  _DesktopPopoverOptionRow(
                    icon: Icons.playlist_add_rounded,
                    title: '添加到当前队列',
                    onTap: () async {
                      await context.read<PlayerCubit>().addToQueue(track);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      if (parentContext.mounted) {
                        AppSnackBar.show(parentContext, '已加入队列：${track.title}');
                      }
                    },
                  ),
                  const _DesktopPopoverDivider(),
                  BlocBuilder<PlayerCubit, PlayerViewState>(
                    buildWhen: (previous, current) =>
                        previous.quality != current.quality,
                    builder: (context, state) => _DesktopPopoverOptionRow(
                      icon: Icons.high_quality_rounded,
                      title: '播放音质',
                      subtitle: '${state.quality.label}（下一首起生效）',
                      showChevron: true,
                      onTap: () => _openDesktopNestedPopover(
                        context,
                        () => _showDesktopQualityDialog(
                          parentContext,
                          returnTrack: track,
                        ),
                      ),
                    ),
                  ),
                  BlocBuilder<PlayerCubit, PlayerViewState>(
                    buildWhen: (previous, current) =>
                        previous.sleepRemaining != current.sleepRemaining ||
                        previous.sleepEndOfTrack != current.sleepEndOfTrack,
                    builder: (context, state) => _DesktopPopoverOptionRow(
                      icon: Icons.bedtime_outlined,
                      title: '睡眠定时',
                      subtitle: state.sleepEndOfTrack
                          ? '本曲结束后暂停播放'
                          : state.sleepRemaining == null
                          ? '30 分钟后暂停播放'
                          : '剩余 ${_formatSleep(state.sleepRemaining!)}',
                      showChevron: true,
                      onTap: () => _openDesktopNestedPopover(
                        context,
                        () => _showDesktopSleepTimerDialog(
                          parentContext,
                          returnTrack: track,
                        ),
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

void _returnToDesktopMoreActions(BuildContext context, MusicTrack track) {
  Navigator.of(context).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) _showDesktopMoreActionsDialog(context, track);
  });
}

class _DesktopPopoverSurface extends StatelessWidget {
  const _DesktopPopoverSurface({
    required this.width,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacingTokens.cardPadding),
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
            color: _playerSurfaceColor(context).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.68),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColorTokens.overlayDark,
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
    required this.title,
    required this.subtitle,
    this.trailing,
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .48),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacingTokens.cardPadding,
          AppSpacingTokens.buttonPaddingV,
          AppSpacingTokens.contentGap,
          AppSpacingTokens.contentGap,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
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
      mouseCursor: SystemMouseCursors.click,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return colorScheme.onSurface;
          }
          return colorScheme.onSurfaceVariant;
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        minimumSize: WidgetStateProperty.all(const Size.square(40)),
        maximumSize: WidgetStateProperty.all(const Size.square(40)),
      ),
      icon: const Icon(Icons.close_rounded),
    );
  }
}

class _DesktopPopoverBackButton extends StatelessWidget {
  const _DesktopPopoverBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: '返回',
      mouseCursor: SystemMouseCursors.click,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return colorScheme.onSurface;
          }
          return colorScheme.onSurfaceVariant;
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        minimumSize: WidgetStateProperty.all(const Size.square(40)),
        maximumSize: WidgetStateProperty.all(const Size.square(40)),
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}

class _DesktopPopoverOptionRow extends StatefulWidget {
  const _DesktopPopoverOptionRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.selected = false,
    this.showChevron = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final bool showChevron;
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
    final toneColor = colorScheme.primary;
    final hoverBackground = theme.hoverWash.withValues(alpha: 0.52);
    final pressedBackground = theme.hoverWash.withValues(alpha: 0.72);
    final backgroundColor = selected
        ? theme.selectedWash.withValues(alpha: 0.72)
        : _pressed
        ? pressedBackground
        : _hovered
        ? hoverBackground
        : Colors.transparent;

    return MouseRegion(
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
          widget.onTap();
        },
        child: Container(
          constraints: BoxConstraints(
            minHeight: AppSpacingTokens.buttonHeight.toDouble(),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacingTokens.cardPadding,
            vertical: AppSpacingTokens.inlineGapCompact,
          ),
          color: backgroundColor,
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: selected ? toneColor : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
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
                        color: colorScheme.onSurface,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (selected)
                Icon(Icons.check_rounded, size: 18, color: toneColor)
              else if (widget.showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.56),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopPopoverDivider extends StatelessWidget {
  const _DesktopPopoverDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .48),
  );
}

class _DesktopSleepTimerDialog extends StatelessWidget {
  const _DesktopSleepTimerDialog({this.onBack});

  final VoidCallback? onBack;

  static const _presets = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacingTokens.desktopMainContentPaddingX,
            AppSpacingTokens.sectionGap,
            AppSpacingTokens.desktopMainContentPaddingX,
            AppSpacingTokens.sectionPadding,
          ),
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
                  width: 320,
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DesktopPopoverHeader(
                        title: '睡眠定时',
                        subtitle: '到点后自动暂停播放',
                        leading: _DesktopPopoverBackButton(
                          onPressed:
                              onBack ?? () => Navigator.of(context).pop(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacingTokens.inlineGap,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final preset in _presets)
                              _DesktopPopoverOptionRow(
                                title: '${preset.inMinutes} 分钟',
                                subtitle:
                                    preset == const Duration(minutes: 30) &&
                                        active
                                    ? '剩余 ${_formatSleep(remaining ?? preset)}'
                                    : null,
                                selected:
                                    remaining != null &&
                                    remaining.inMinutes <= preset.inMinutes &&
                                    remaining.inMinutes > preset.inMinutes - 2,
                                onTap: () async {
                                  await cubit.startSleepTimer(preset);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            _DesktopPopoverOptionRow(
                              title: '本曲结束后',
                              selected: state.sleepEndOfTrack,
                              onTap: () async {
                                await cubit.startSleepTimerEndOfTrack();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            const _DesktopPopoverDivider(),
                            _DesktopPopoverOptionRow(
                              title: '取消睡眠定时',
                              onTap: () async {
                                await cubit.cancelSleepTimer();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ],
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

class _DesktopQualityDialog extends StatelessWidget {
  const _DesktopQualityDialog({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacingTokens.desktopMainContentPaddingX,
            AppSpacingTokens.sectionGap,
            AppSpacingTokens.desktopMainContentPaddingX,
            AppSpacingTokens.sectionPadding,
          ),
          child: Material(
            color: Colors.transparent,
            child: BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.quality != next.quality,
              builder: (context, state) {
                return _DesktopPopoverSurface(
                  width: 320,
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DesktopPopoverHeader(
                        title: '播放音质',
                        subtitle: '切换后从下一首开始生效',
                        leading: _DesktopPopoverBackButton(
                          onPressed:
                              onBack ?? () => Navigator.of(context).pop(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacingTokens.inlineGap,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final quality in const [
                              AudioQuality.auto,
                              AudioQuality.lossless,
                              AudioQuality.high,
                              AudioQuality.medium,
                            ])
                              _DesktopPopoverOptionRow(
                                title: quality.label,
                                subtitle: _desktopQualityDescription(quality),
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
                          ],
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
              width: 48,
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
                  trackHeight: 4,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.outlineVariant.withValues(
                    alpha: colorScheme.brightness == Brightness.dark
                        ? 0.48
                        : 0.72,
                  ),
                  thumbColor: colorScheme.primary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                    disabledThumbRadius: 6,
                  ),
                  overlayColor: colorScheme.primary.withValues(alpha: 0.12),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
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
              width: 48,
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
    this.tooltip,
    this.size,
    this.iconSize,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
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
    final btnSize = widget.size ?? 42;
    final icnSize = widget.iconSize ?? 22;

    final foregroundColor = widget.active
        ? colorScheme.primary
        : (_hovered || _pressed
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant);

    Widget button = MouseRegion(
      cursor: SystemMouseCursors.click,
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
        child: SizedBox(
          width: btnSize,
          height: btnSize,
          child: Center(
            child: Icon(widget.icon, size: icnSize, color: foregroundColor),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
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
                    tooltip: '收起播放页',
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

Color _playerSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColorTokens.darkPlayerFooter
      : AppColorTokens.lightPlayerFooter;
}

IconData _playbackModeIcon(PlaybackModeOption mode) {
  return switch (mode) {
    PlaybackModeOption.sequence => Icons.repeat_rounded,
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

String _desktopQualityDescription(AudioQuality quality) {
  return switch (quality) {
    AudioQuality.auto => '根据服务器与网络配置',
    AudioQuality.lossless => 'FLAC / ALAC（当前选择）',
    AudioQuality.high => '320kbps / 适合大多数场景',
    AudioQuality.medium => '128kbps / 节省流量与空间',
    AudioQuality.low => '128kbps / 节省流量与空间',
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

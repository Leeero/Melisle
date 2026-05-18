import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
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
import 'package:cross_platform_music_player/presentation/widgets/flutter_lyric_view.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/quality_picker_sheet.dart';
import 'package:cross_platform_music_player/presentation/widgets/queue_sheet.dart';
import 'package:cross_platform_music_player/presentation/widgets/sleep_timer_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            prev.queue.length != next.queue.length ||
            prev.duration != next.duration ||
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
// Mobile layout — focused modes: artwork or lyrics, with compact quick actions
// ---------------------------------------------------------------------------

enum _MobilePlayerContentMode { artwork, lyrics }

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
  _MobilePlayerContentMode _contentMode = _MobilePlayerContentMode.artwork;

  @override
  Widget build(BuildContext context) {
    final showingLyrics = _contentMode == _MobilePlayerContentMode.lyrics;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            _PlayerTopBar(
              onMorePressed: () =>
                  _showMobileMoreActionsSheet(context, track: widget.track),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: showingLyrics
                      ? _MobileLyricsStage(
                          key: const ValueKey('lyrics'),
                          onShowArtwork: () => setState(
                            () =>
                                _contentMode = _MobilePlayerContentMode.artwork,
                          ),
                        )
                      : _MobileSwipeGestureRegion(
                          key: const ValueKey('artwork'),
                          onTap: () => setState(
                            () =>
                                _contentMode = _MobilePlayerContentMode.lyrics,
                          ),
                          onSwipeEnd: (details) =>
                              _handleSwipe(context, details),
                          onSwipeCancel: _resetSwipe,
                          onSwipeUpdate: _updateSwipe,
                          child: _MobileArtworkStage(track: widget.track),
                        ),
                ),
              ),
            ),
            _MobileTrackInfo(track: widget.track),
            const SizedBox(height: 12),
            _MobileSwipeGestureRegion(
              onSwipeEnd: (details) => _handleSwipe(context, details),
              onSwipeCancel: _resetSwipe,
              onSwipeUpdate: _updateSwipe,
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
        _contentMode == _MobilePlayerContentMode.artwork &&
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
    super.key,
    required this.child,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
    required this.onSwipeCancel,
    this.onTap,
  });

  final Widget child;
  final ValueChanged<DragUpdateDetails> onSwipeUpdate;
  final ValueChanged<DragEndDetails> onSwipeEnd;
  final VoidCallback onSwipeCancel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math
                .min(constraints.maxWidth, constraints.maxHeight * 0.88)
                .clamp(240.0, 390.0);
            return BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) =>
                  prev.isPlaying != next.isPlaying ||
                  prev.isLoading != next.isLoading,
              builder: (context, s) {
                return _VinylArtworkStage(
                  track: track,
                  isPlaying: s.isPlaying,
                  isLoading: s.isLoading,
                  size: size,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MobileLyricsStage extends StatelessWidget {
  const _MobileLyricsStage({super.key, required this.onShowArtwork});

  final VoidCallback onShowArtwork;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _MobileLyricView()),
          Positioned(
            top: 10,
            right: 10,
            child: Tooltip(
              message: '切回封面',
              child: FilledButton.tonalIcon(
                onPressed: onShowArtwork,
                icon: const Icon(Icons.album_rounded, size: 18),
                label: const Text('封面'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLyricView extends StatelessWidget {
  const _MobileLyricView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.playerHorizontalPadding,
      ),
      child: BlocBuilder<PlayerCubit, PlayerViewState>(
        buildWhen: (p, c) =>
            p.lyrics != c.lyrics || p.isLyricsLoading != c.isLyricsLoading,
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

          return FlutterLyricView(
            lines: state.lyrics,
            onLineTap: (i) => context.read<PlayerCubit>().seekToLyricIndex(i),
          );
        },
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.playerHorizontalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Column(
                key: ValueKey(track.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${track.artistName}${track.albumTitle.isNotEmpty ? ' · ${track.albumTitle}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favState) {
              final isFav = favState.entries[track.id] ?? track.isFavorite;
              return IconButton(
                onPressed: () => context.read<FavoritesCubit>().toggle(
                  track.id,
                  currentValue: isFav,
                ),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isFav),
                    color: isFav
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                tooltip: isFav ? '取消收藏' : '收藏',
                style: IconButton.styleFrom(
                  side: BorderSide.none,
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout — side by side: Artwork+Info | Lyrics, bottom bar
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
        const _PlayerTopBar(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _DesktopArtworkStage(track: track),
                    ),
                    const SizedBox(width: 48),
                    Expanded(flex: 6, child: _DesktopLyricStage(track: track)),
                  ],
                ),
              ),
            ),
          ),
        ),
        _DesktopBottomBar(state: state, track: track),
      ],
    );
  }
}

class _DesktopArtworkStage extends StatelessWidget {
  const _DesktopArtworkStage({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) =>
              prev.isPlaying != next.isPlaying ||
              prev.isLoading != next.isLoading,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: _VinylArtworkStage(
                      track: track,
                      isPlaying: state.isPlaying,
                      isLoading: state.isLoading,
                      size: 410,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
    final subtitle = [
      track.artistName,
      if (track.albumTitle.isNotEmpty) track.albumTitle,
    ].where((value) => value.isNotEmpty).join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (p, c) =>
              p.lyrics != c.lyrics ||
              p.isLyricsLoading != c.isLyricsLoading ||
              p.currentIndex != c.currentIndex,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: colorScheme.surface.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: state.isLyricsLoading && state.lyrics.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : state.lyrics.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lyrics_outlined,
                                    size: 28,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '暂无歌词',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : FlutterLyricView(
                              lines: state.lyrics,
                              onLineTap: (i) => context
                                  .read<PlayerCubit>()
                                  .seekToLyricIndex(i),
                              textAlign: TextAlign.center,
                              alignment: Alignment.center,
                              maxTextWidth: 520,
                              currentScale: 1.02,
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesktopBottomBar extends StatelessWidget {
  const _DesktopBottomBar({required this.state, required this.track});

  final PlayerViewState state;
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final artworkSourceContext = ArtworkSourceContext.track(track);
    final subtitle = [
      track.artistName,
      if (track.albumTitle.isNotEmpty) track.albumTitle,
    ].where((value) => value.isNotEmpty).join(' · ');

    Widget sectionDivider() {
      return Container(
        width: 1,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.52,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                        child: CachedArtwork(
                          imageUrl: track.artworkUrl,
                          size: 58,
                          borderRadius: 18,
                          sourceContext: artworkSourceContext,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '正在播放',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      BlocBuilder<FavoritesCubit, FavoritesState>(
                        builder: (context, favState) {
                          final isFav =
                              favState.entries[track.id] ?? track.isFavorite;
                          return _DesktopUtilityIconButton(
                            tooltip: isFav ? '取消收藏' : '收藏',
                            active: isFav,
                            onPressed: () => context
                                .read<FavoritesCubit>()
                                .toggle(track.id, currentValue: isFav),
                            child: AnimatedSwitcher(
                              duration: AppMotion.micro,
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                key: ValueKey(isFav),
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                sectionDivider(),
                Expanded(
                  flex: 5,
                  child: Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ProgressTimeline(),
                          const SizedBox(height: 12),
                          _DesktopControlCluster(
                            child: const _PlaybackControls(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                sectionDivider(),
                Expanded(
                  flex: 4,
                  child: _DesktopUtilityBar(state: state, track: track),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared components
// ---------------------------------------------------------------------------

class _DesktopUtilityBar extends StatelessWidget {
  const _DesktopUtilityBar({required this.state, required this.track});

  final PlayerViewState state;
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showInlineVolume = constraints.maxWidth >= 420;
        final sliderWidth = (constraints.maxWidth - 230)
            .clamp(112.0, 156.0)
            .toDouble();
        final sleepActive =
            state.sleepRemaining != null || state.sleepEndOfTrack;

        return Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DesktopUtilitySegment(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        return _DesktopUtilityIconButton(
                          tooltip: downloaded
                              ? '已下载'
                              : running
                              ? '下载中'
                              : '下载当前曲目',
                          active: downloaded || running,
                          onPressed: downloaded || running
                              ? null
                              : () => context.read<DownloadsCubit>().enqueue(
                                  track,
                                ),
                          child: Icon(
                            downloaded
                                ? Icons.download_done_rounded
                                : running
                                ? Icons.downloading_rounded
                                : Icons.download_rounded,
                            size: 20,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    _DesktopUtilityIconButton(
                      tooltip: sleepActive
                          ? state.sleepRemaining != null
                                ? '睡眠定时：${_formatSleep(state.sleepRemaining!)}'
                                : '睡眠定时：本曲结束后'
                          : '睡眠定时',
                      active: sleepActive,
                      onPressed: () => _showDesktopSleepTimerDialog(context),
                      child: Icon(
                        sleepActive
                            ? Icons.bedtime_rounded
                            : Icons.bedtime_outlined,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _DesktopUtilitySegment(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DesktopUtilityIconButton(
                      tooltip: '播放队列（${state.queue.length}）',
                      onPressed: () => _showDesktopQueueDialog(context),
                      child: _DesktopQueueGlyph(count: state.queue.length),
                    ),
                    const SizedBox(width: 6),
                    BlocBuilder<PlayerCubit, PlayerViewState>(
                      buildWhen: (prev, next) => prev.quality != next.quality,
                      builder: (context, playerState) {
                        return _DesktopUtilityIconButton(
                          tooltip: '播放音质：${playerState.quality.label}',
                          active: playerState.quality != AudioQuality.auto,
                          onPressed: () => _showDesktopQualityDialog(context),
                          child: const Icon(
                            Icons.high_quality_rounded,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (showInlineVolume)
                _DesktopUtilitySegment(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: sliderWidth,
                    child: _DesktopVolumeControl(width: sliderWidth),
                  ),
                )
              else
                _DesktopUtilitySegment(
                  child: BlocBuilder<PlayerCubit, PlayerViewState>(
                    buildWhen: (prev, next) => prev.volume != next.volume,
                    builder: (context, playerState) {
                      return _DesktopUtilityIconButton(
                        tooltip: '音量 ${_volumePercent(playerState.volume)}%',
                        onPressed: () => _showDesktopVolumeDialog(context),
                        child: Icon(_volumeIcon(playerState.volume), size: 20),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopControlCluster extends StatelessWidget {
  const _DesktopControlCluster({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}

class _DesktopUtilitySegment extends StatelessWidget {
  const _DesktopUtilitySegment({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DesktopUtilityIconButton extends StatefulWidget {
  const _DesktopUtilityIconButton({
    required this.child,
    required this.tooltip,
    this.onPressed,
    this.active = false,
  });

  final Widget child;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  State<_DesktopUtilityIconButton> createState() =>
      _DesktopUtilityIconButtonState();
}

class _DesktopUtilityIconButtonState extends State<_DesktopUtilityIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = widget.onPressed != null;
    final foregroundColor = !isEnabled
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
        : widget.active
        ? colorScheme.primary
        : (_hovered ? colorScheme.onSurface : colorScheme.onSurfaceVariant);
    final backgroundColor = widget.active
        ? colorScheme.primaryContainer.withValues(alpha: _hovered ? 0.76 : 0.62)
        : (_hovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.58)
              : Colors.transparent);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _hovered && isEnabled ? 1.03 : 1.0,
          child: AnimatedContainer(
            duration: AppMotion.micro,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                if (_hovered && isEnabled)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: IconButton(
              onPressed: widget.onPressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 42, height: 42),
              style: IconButton.styleFrom(
                side: BorderSide.none,
                foregroundColor: foregroundColor,
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: foregroundColor,
              ),
              icon: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopQueueGlyph extends StatelessWidget {
  const _DesktopQueueGlyph({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeText = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.queue_music_rounded, size: 20),
        if (count > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({this.onMorePressed});

  final VoidCallback? onMorePressed;

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
                const Spacer(),
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActiveMode =
        !widget.subtle && widget.mode != PlaybackModeOption.sequence;
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
  const _DesktopVolumeControl({this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (prev, next) => prev.volume != next.volume,
      builder: (context, state) {
        return SizedBox(
          width: width,
          child: Row(
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
                    activeTrackColor: colorScheme.primary.withValues(
                      alpha: 0.92,
                    ),
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
                    onChanged: context.read<PlayerCubit>().setVolume,
                  ),
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
                    fontFeatures: [const ui.FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.volume != next.volume,
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _volumeIcon(state.volume),
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '音量',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${_volumePercent(state.volume)}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFeatures: [
                              const ui.FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
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
                        onChanged: context.read<PlayerCubit>().setVolume,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '静音',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '最大',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '更多操作',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '管理当前曲目的下载、音质、音量和睡眠定时。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
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
                return _MobileMoreActionTile(
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
                  enabled: !downloaded && !running,
                  onTap: () async {
                    await context.read<DownloadsCubit>().enqueue(track);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            ),
            BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.quality != next.quality,
              builder: (context, state) => _MobileMoreActionTile(
                icon: Icons.high_quality_rounded,
                title: '播放音质：${state.quality.label}',
                subtitle: '下一首起生效；无损取决于源文件',
                onTap: () => _openNestedSheet(
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
                return _MobileMoreActionTile(
                  icon: remaining != null || state.sleepEndOfTrack
                      ? Icons.bedtime_rounded
                      : Icons.bedtime_outlined,
                  title: '睡眠定时',
                  subtitle: subtitle,
                  onTap: () => _openNestedSheet(
                    context,
                    () => SleepTimerSheet.show(parentContext),
                  ),
                );
              },
            ),
            BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.volume != next.volume,
              builder: (context, state) => _MobileMoreActionTile(
                icon: _volumeIcon(state.volume),
                title: '音量 ${_volumePercent(state.volume)}%',
                subtitle: '调节当前输出强度',
                onTap: () => _openNestedSheet(
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

class _MobileMoreActionTile extends StatelessWidget {
  const _MobileMoreActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(
                      alpha: enabled ? 0.58 : 0.24,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: enabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: enabled
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.45,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(
                    alpha: enabled ? 0.72 : 0.32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showDesktopPopover(BuildContext context, Widget child) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: '关闭面板',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<void> _showDesktopVolumeDialog(BuildContext context) {
  return _showDesktopPopover(
    context,
    BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: const _DesktopVolumeDialog(),
    ),
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
  return _showDesktopPopover(
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

class _DesktopPopoverSurface extends StatelessWidget {
  const _DesktopPopoverSurface({
    required this.width,
    required this.child,
    this.constraints,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
  });

  final double width;
  final Widget child;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface.withValues(alpha: 0.9),
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
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

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
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
                        style: theme.textTheme.titleMedium?.copyWith(
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
                    color: colorScheme.onSurfaceVariant,
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
        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
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
        backgroundColor: colorScheme.surface.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      icon: const Icon(Icons.close_rounded),
    );
  }
}

class _DesktopPopoverActionButton extends StatelessWidget {
  const _DesktopPopoverActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class _DesktopVolumeDialog extends StatelessWidget {
  const _DesktopVolumeDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 108),
          child: Material(
            color: Colors.transparent,
            child: BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.volume != next.volume,
              builder: (context, state) {
                return _DesktopPopoverSurface(
                  width: 328,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DesktopPopoverHeader(
                        icon: _volumeIcon(state.volume),
                        title: '音量',
                        subtitle: '拖动滑块实时调节当前输出强度。',
                        meta: '${_volumePercent(state.volume)}%',
                        trailing: _DesktopPopoverCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.26),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.4,
                                activeTrackColor: colorScheme.primary
                                    .withValues(alpha: 0.94),
                                inactiveTrackColor: colorScheme.onSurface
                                    .withValues(alpha: 0.14),
                                thumbShape: _PlayerSliderThumbShape(
                                  radius: 5.2,
                                  fillColor: colorScheme.surface,
                                  ringColor: colorScheme.primary,
                                  glowColor: colorScheme.primary,
                                  glowAlpha: 0.14,
                                ),
                                overlayColor: colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 15,
                                ),
                                trackShape: _GlowingSliderTrackShape(
                                  glowColor: colorScheme.primary,
                                  glowAlpha: 0.12,
                                  blurSigma: 7,
                                ),
                              ),
                              child: Slider(
                                value: state.volume,
                                onChanged: context
                                    .read<PlayerCubit>()
                                    .setVolume,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '静音',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '最大',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
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

class _DesktopSleepTimerDialog extends StatelessWidget {
  const _DesktopSleepTimerDialog();

  static const _presets = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final preset in _presets)
                            FilledButton.tonal(
                              onPressed: () async {
                                await cubit.startSleepTimer(preset);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Text('${preset.inMinutes} 分钟'),
                            ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await cubit.startSleepTimerEndOfTrack();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text('本曲结束后'),
                          ),
                        ],
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              await cubit.cancelSleepTimer();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(Icons.alarm_off_rounded),
                            label: const Text('取消睡眠定时'),
                          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              await context.read<PlayerCubit>().setQuality(
                                quality,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: AnimatedContainer(
                              duration: AppMotion.micro,
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                13,
                                14,
                                13,
                              ),
                              decoration: BoxDecoration(
                                gradient: quality == state.quality
                                    ? LinearGradient(
                                        colors: [
                                          colorScheme.primaryContainer
                                              .withValues(alpha: 0.82),
                                          colorScheme.primaryContainer
                                              .withValues(alpha: 0.56),
                                        ],
                                      )
                                    : null,
                                color: quality == state.quality
                                    ? null
                                    : colorScheme.surface.withValues(
                                        alpha: 0.24,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: quality == state.quality
                                      ? colorScheme.primary.withValues(
                                          alpha: 0.3,
                                        )
                                      : colorScheme.outlineVariant.withValues(
                                          alpha: 0.2,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quality.label,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight:
                                                    quality == state.quality
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _qualityDescription(quality),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (quality == state.quality)
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.14,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                ],
                              ),
                            ),
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
    final maxHeight = (MediaQuery.sizeOf(context).height * 0.82)
        .clamp(560.0, 760.0)
        .toDouble();

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 108),
          child: _DesktopQueueSurface(
            width: 408,
            constraints: BoxConstraints(maxHeight: maxHeight),
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
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: BlocBuilder<PlayerCubit, PlayerViewState>(
                    builder: (context, state) {
                      if (state.queue.isEmpty) {
                        return const _DesktopQueueEmptyState();
                      }

                      return ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                        buildDefaultDragHandles: false,
                        itemExtent: 72,
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
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.18,
                        ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
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
  const _DesktopQueueSurface({
    required this.width,
    required this.child,
    this.constraints,
  });

  final double width;
  final Widget child;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      constraints: constraints,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.queue_music_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '播放队列',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DesktopQueueBadge(label: '$count 首'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  confirmingClear
                      ? '再次点击将清空整个队列'
                      : '点按切歌，拖拽排序，移除后可撤销',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (confirmingClear)
            TextButton(
              onPressed: onCancelClear,
              child: const Text('取消'),
            ),
          if (count > 0)
            TextButton(
              onPressed: onClearPressed,
              child: Text(confirmingClear ? '确认清空' : '清空'),
            ),
          const SizedBox(width: 4),
          _DesktopPopoverCloseButton(onPressed: onClosePressed),
        ],
      ),
    );
  }
}

class _DesktopQueueBadge extends StatelessWidget {
  const _DesktopQueueBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
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

    final baseColor = widget.isCurrent
        ? colorScheme.primaryContainer.withValues(alpha: 0.62)
        : colorScheme.surface.withValues(alpha: _hovered ? 0.7 : 0.24);
    final borderColor = widget.isCurrent
        ? colorScheme.primary.withValues(alpha: 0.22)
        : colorScheme.outlineVariant.withValues(alpha: _hovered ? 0.28 : 0.14);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await context.read<PlayerCubit>().playIndex(widget.index);
            },
            child: AnimatedContainer(
              duration: AppMotion.micro,
              curve: Curves.easeOutQuart,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${widget.index + 1}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: widget.isCurrent
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CachedArtwork(
                    imageUrl: widget.track.artworkUrl,
                    size: 44,
                    borderRadius: 14,
                    sourceContext: ArtworkSourceContext.track(widget.track),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: widget.isCurrent
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.isCurrent)
                    Icon(
                      widget.isPlaying
                          ? Icons.graphic_eq_rounded
                          : Icons.pause_circle_outline_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    duration: AppMotion.micro,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => context
                              .read<PlayerCubit>()
                              .removeQueueItem(widget.index),
                          tooltip: '移出队列',
                          style: IconButton.styleFrom(
                            side: BorderSide.none,
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        Tooltip(
                          message: '拖拽排序',
                          child: ReorderableDragStartListener(
                            index: widget.index,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_hovered)
                    const SizedBox(
                      width: 48,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
// Vinyl artwork
// ---------------------------------------------------------------------------

class _VinylArtworkStage extends StatelessWidget {
  const _VinylArtworkStage({
    required this.track,
    required this.isPlaying,
    required this.isLoading,
    this.size = 440,
  });

  final MusicTrack track;
  final bool isPlaying;
  final bool isLoading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final discSize = size * 0.86;
    final artworkSourceContext = ArtworkSourceContext.track(track);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: size * 0.04,
            child: Container(
              width: size * 0.62,
              height: size * 0.08,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.12),
                gradient: RadialGradient(
                  center: const Alignment(-0.08, -0.14),
                  radius: 0.84,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.14),
                    colorScheme.surface.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.58, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 44,
                    offset: const Offset(0, 24),
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 48,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.94,
            height: size * 0.94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.72, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          _RotatingArtwork(
            imageUrl: track.artworkUrl,
            sourceContext: artworkSourceContext,
            size: discSize,
            isPlaying: isPlaying,
            isLoading: isLoading,
            isVinyl: true,
          ),
          Positioned(
            top: -size * 0.068,
            right: size * 0.12,
            child: _StylusArm(
              isPlaying: isPlaying && !isLoading,
              height: size * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StylusArm extends StatelessWidget {
  const _StylusArm({required this.isPlaying, this.height = 220});

  final bool isPlaying;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 0.45;
    return AnimatedRotation(
      turns: isPlaying ? 0.08 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: const Alignment(0.0, -0.8),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.topCenter,
        child: CustomPaint(
          size: Size(width * 0.8, height * 0.9),
          painter: _StylusPainter(),
        ),
      ),
    );
  }
}

class _StylusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.05, h * 0.045);
    _drawShadow(canvas, w, h);
    canvas.restore();

    _drawArmTube(canvas, w, h);
    _drawCounterweight(canvas, w, h);
    _drawHeadShell(canvas, w, h);
    _drawPivot(canvas, w, h);
  }

  Path _armPath(double w, double h) {
    return Path()
      ..moveTo(w * 0.445, h * 0.105)
      ..lineTo(w * 0.555, h * 0.105)
      ..lineTo(w * 0.5, h * 0.695)
      ..lineTo(w * 0.308, h * 0.9)
      ..lineTo(w * 0.248, h * 0.888)
      ..lineTo(w * 0.438, h * 0.69)
      ..close();
  }

  void _drawShadow(Canvas canvas, double w, double h) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    canvas.drawPath(_armPath(w, h), shadowPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.1), w * 0.24, shadowPaint);

    canvas.save();
    canvas.translate(w * 0.275, h * 0.895);
    canvas.rotate(math.pi / 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.13, -h * 0.03, w * 0.27, h * 0.165),
        Radius.circular(w * 0.05),
      ),
      shadowPaint,
    );
    canvas.restore();
  }

  void _drawArmTube(Canvas canvas, double w, double h) {
    final armPath = _armPath(w, h);
    final metallicPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.5, h * 0.08),
        Offset(w * 0.25, h * 0.92),
        const [Color(0xFFF4F4F4), Color(0xFFCFCFCF), Color(0xFF8E8E8E)],
        const [0.0, 0.55, 1.0],
      )
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(armPath, metallicPaint);

    final edgePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.46, h * 0.08),
        Offset(w * 0.28, h * 0.92),
        [
          Colors.white.withValues(alpha: 0.4),
          Colors.black.withValues(alpha: 0.18),
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..isAntiAlias = true;
    canvas.drawPath(armPath, edgePaint);

    final groovePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.14),
      Offset(w * 0.314, h * 0.858),
      groovePaint,
    );

    final highlightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.47, h * 0.12),
        Offset(w * 0.34, h * 0.74),
        [
          Colors.white.withValues(alpha: 0.34),
          Colors.white.withValues(alpha: 0.02),
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(
      Offset(w * 0.472, h * 0.14),
      Offset(w * 0.35, h * 0.73),
      highlightPaint,
    );
  }

  void _drawCounterweight(Canvas canvas, double w, double h) {
    final counterweight = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.36, h * 0.072, w * 0.14, h * 0.06),
      Radius.circular(w * 0.03),
    );
    final counterweightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.36, h * 0.072),
        Offset(w * 0.5, h * 0.132),
        const [Color(0xFFE9E9E9), Color(0xFFADADAD), Color(0xFF6C6C6C)],
        const [0.0, 0.5, 1.0],
      )
      ..isAntiAlias = true;
    canvas.drawRRect(counterweight, counterweightPaint);

    final counterweightEdge = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;
    canvas.drawRRect(counterweight, counterweightEdge);
  }

  void _drawHeadShell(Canvas canvas, double w, double h) {
    canvas.save();
    canvas.translate(w * 0.275, h * 0.895);
    canvas.rotate(math.pi / 6);

    final shell = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w * 0.13, -h * 0.03, w * 0.27, h * 0.165),
      Radius.circular(w * 0.05),
    );
    final shellPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-w * 0.13, -h * 0.03),
        Offset(w * 0.14, h * 0.135),
        const [Color(0xFFCACACA), Color(0xFF999999), Color(0xFF5F5F5F)],
        const [0.0, 0.5, 1.0],
      )
      ..isAntiAlias = true;
    canvas.drawRRect(shell, shellPaint);

    final shellEdgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;
    canvas.drawRRect(shell, shellEdgePaint);

    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w * 0.08, h * 0.012, w * 0.15, h * 0.05),
      Radius.circular(w * 0.02),
    );
    final platePaint = Paint()
      ..color = const Color(0xFF4F4F4F)
      ..isAntiAlias = true;
    canvas.drawRRect(plate, platePaint);

    final needlePaint = Paint()
      ..color = const Color(0xFFD0A85B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(
      Offset(w * 0.015, h * 0.078),
      Offset(w * 0.055, h * 0.145),
      needlePaint,
    );

    final stylusTip = Paint()
      ..color = const Color(0xFFE6C67A)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.058, h * 0.148), w * 0.011, stylusTip);
    canvas.restore();
  }

  void _drawPivot(Canvas canvas, double w, double h) {
    final pivotX = w * 0.5;
    final pivotY = h * 0.1;
    final pivotR = w * 0.24;

    final pivotPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(pivotX - w * 0.03, pivotY - h * 0.018),
        pivotR,
        const [Color(0xFFF3F3F3), Color(0xFFBEBEBE), Color(0xFF787878)],
        const [0.0, 0.58, 1.0],
      )
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(pivotX, pivotY), pivotR, pivotPaint);

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(pivotX, pivotY), pivotR - 0.5, rimPaint);

    final pivotCenter = Paint()
      ..shader = ui.Gradient.radial(
        Offset(pivotX, pivotY),
        pivotR * 0.34,
        const [Color(0xFFD8D8D8), Color(0xFF8D8D8D)],
      )
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(pivotX, pivotY), pivotR * 0.34, pivotCenter);

    final boltPaint = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(pivotX, pivotY), pivotR * 0.12, boltPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..isAntiAlias = true;
    canvas.drawCircle(
      Offset(pivotX - pivotR * 0.22, pivotY - pivotR * 0.22),
      pivotR * 0.12,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final String? tooltip;
  final double? size;
  final double? iconSize;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isPrimary) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scale = _pressed ? 0.96 : (_hovered ? 1.04 : 1.0);
    final btnSize = widget.size ?? (widget.isPrimary ? 60 : 42);
    final icnSize = widget.iconSize ?? (widget.isPrimary ? 30 : 22);

    final backgroundColor = widget.isPrimary
        ? colorScheme.primary
        : (_pressed
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.72)
              : (_hovered
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent));
    final foregroundColor = widget.isPrimary
        ? colorScheme.onPrimary
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
          duration: const Duration(milliseconds: 140),
          scale: scale,
          child: widget.isPrimary
              ? AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final pulseScale = _hovered || _pressed
                        ? 1.0
                        : _pulseAnimation.value;
                    return Transform.scale(scale: pulseScale, child: child);
                  },
                  child: _buildButtonBody(
                    btnSize,
                    backgroundColor,
                    foregroundColor,
                    icnSize,
                    colorScheme,
                  ),
                )
              : _buildButtonBody(
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: btnSize,
      height: btnSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: widget.isPrimary
            ? null
            : Border.all(
                color: _hovered || _pressed
                    ? colorScheme.outlineVariant.withValues(alpha: 0.32)
                    : Colors.transparent,
              ),
        boxShadow: [
          if (widget.isPrimary)
            BoxShadow(
              color: colorScheme.primary.withValues(
                alpha: _hovered ? 0.42 : 0.2,
              ),
              blurRadius: _hovered ? 22 : 14,
              spreadRadius: _hovered ? 1 : 0,
              offset: const Offset(0, 6),
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
// Rotating artwork
// ---------------------------------------------------------------------------

class _RotatingArtwork extends StatefulWidget {
  const _RotatingArtwork({
    required this.imageUrl,
    required this.size,
    required this.isPlaying,
    required this.isLoading,
    this.isVinyl = false,
    this.sourceContext,
  });

  final String imageUrl;
  final double size;
  final bool isPlaying;
  final bool isLoading;
  final bool isVinyl;
  final ArtworkSourceContext? sourceContext;

  @override
  State<_RotatingArtwork> createState() => _RotatingArtworkState();
}

class _RotatingArtworkState extends State<_RotatingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _RotatingArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying ||
        oldWidget.isLoading != widget.isLoading ||
        oldWidget.imageUrl != widget.imageUrl) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isPlaying && !widget.isLoading) {
      _controller.repeat();
      return;
    }
    _controller.stop(canceled: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image = CachedArtwork(
      imageUrl: widget.imageUrl,
      size: widget.isVinyl ? widget.size * 0.65 : widget.size,
      borderRadius: widget.isVinyl ? widget.size * 0.325 : 30,
      sourceContext: widget.sourceContext,
    );

    if (widget.isVinyl) {
      image = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10, width: 1),
          gradient: const SweepGradient(
            colors: [
              Color(0xFF181818),
              Color(0xFF292929),
              Color(0xFF151515),
              Color(0xFF2C2C2C),
              Color(0xFF181818),
            ],
            stops: [0.0, 0.22, 0.5, 0.78, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 0.92,
              height: widget.size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            Container(
              width: widget.size * 0.82,
              height: widget.size * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.12),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
            image,
            Container(
              width: widget.size * 0.12,
              height: widget.size * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF111111),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.26),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: widget.size * 0.032,
                  height: widget.size * 0.032,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RotationTransition(turns: _controller, child: image);
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

                      // 引导操作按钮
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.library_music_rounded, size: 18),
                        label: const Text('返回浏览'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.52,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
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

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/lyric_view.dart';
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
// Mobile layout — stacked vertically: AppBar → Artwork → TrackInfo → Controls
// ---------------------------------------------------------------------------

class _MobileLayout extends StatefulWidget {
  const _MobileLayout({required this.state, required this.track});

  final PlayerViewState state;
  final MusicTrack track;

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // -- Top bar --
        _PlayerTopBar(track: widget.track, state: widget.state),

        // -- Main content: artwork or lyrics --
        Expanded(
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -200) {
                  setState(() => _showLyrics = true);
                } else if (details.primaryVelocity! > 200) {
                  setState(() => _showLyrics = false);
                }
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _showLyrics
                  ? _MobileLyricView(
                      key: const ValueKey('lyrics'),
                      track: widget.track,
                      onClose: () => setState(() => _showLyrics = false),
                    )
                  : _MobileArtworkStage(
                      key: const ValueKey('artwork'),
                      track: widget.track,
                    ),
            ),
          ),
        ),

        // -- Lyrics toggle hint --
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () => setState(() => _showLyrics = !_showLyrics),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Row(
                key: ValueKey(_showLyrics),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showLyrics ? Icons.album_rounded : Icons.lyrics_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showLyrics ? '查看封面' : '查看歌词',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // -- Track info --
        _MobileTrackInfo(track: widget.track),
        const SizedBox(height: 16),

        // -- Progress --
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _ProgressTimeline(),
        ),
        const SizedBox(height: 12),

        // -- Playback controls --
        const _PlaybackControls(),
        const SizedBox(height: 10),

        // -- Secondary actions --
        _MobileSecondaryActions(state: widget.state, track: widget.track),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
      ],
    );
  }
}

class _MobileArtworkStage extends StatelessWidget {
  const _MobileArtworkStage({super.key, required this.track});

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
                .clamp(200.0, 380.0);
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

class _MobileLyricView extends StatelessWidget {
  const _MobileLyricView({super.key, required this.track, this.onClose});

  final MusicTrack track;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: BlocBuilder<PlayerCubit, PlayerViewState>(
        buildWhen: (p, c) =>
            p.lyrics != c.lyrics ||
            p.currentLyricIndex != c.currentLyricIndex ||
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

          return LyricView(
            lines: state.lyrics,
            currentIndex: state.currentLyricIndex,
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  backgroundColor: Colors.transparent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MobileSecondaryActions extends StatelessWidget {
  const _MobileSecondaryActions({required this.state, required this.track});

  final PlayerViewState state;
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 6,
          children: [
            _SecondaryAction(
              icon: Icons.high_quality_rounded,
              tooltip: '音质',
              onTap: () => QualityPickerSheet.show(context),
            ),
            BlocBuilder<DownloadsCubit, DownloadsState>(
              buildWhen: (p, c) =>
                  p.completedTrackIds.contains(track.id) !=
                      c.completedTrackIds.contains(track.id) ||
                  p.jobs.containsKey(track.id) != c.jobs.containsKey(track.id),
              builder: (context, dlState) {
                final downloaded = dlState.completedTrackIds.contains(track.id);
                final running = dlState.jobs.containsKey(track.id);
                return _SecondaryAction(
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
                  active: downloaded,
                  onTap: downloaded || running
                      ? null
                      : () => context.read<DownloadsCubit>().enqueue(track),
                );
              },
            ),
            BlocBuilder<PlayerCubit, PlayerViewState>(
              buildWhen: (prev, next) => prev.volume != next.volume,
              builder: (context, playerState) {
                return _SecondaryAction(
                  icon: _volumeIcon(playerState.volume),
                  tooltip: '音量 ${_volumePercent(playerState.volume)}%',
                  active: playerState.volume > 0,
                  onTap: () => _showVolumeSheet(context),
                );
              },
            ),
            _SecondaryAction(
              icon: state.sleepRemaining != null || state.sleepEndOfTrack
                  ? Icons.bedtime_rounded
                  : Icons.bedtime_outlined,
              tooltip: '睡眠定时',
              active: state.sleepRemaining != null || state.sleepEndOfTrack,
              onTap: () => SleepTimerSheet.show(context),
            ),
            _SecondaryAction(
              icon: Icons.queue_music_rounded,
              tooltip: '播放队列',
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BlocProvider.value(
                    value: context.read<PlayerCubit>(),
                    child: const QueueSheet(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 22,
              color: active
                  ? colorScheme.primary
                  : onTap == null
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
    return Column(
      children: [
        _PlayerTopBar(track: track, state: state),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: BlocBuilder<PlayerCubit, PlayerViewState>(
                          buildWhen: (prev, next) =>
                              prev.isPlaying != next.isPlaying ||
                              prev.isLoading != next.isLoading,
                          builder: (context, s) {
                            return _VinylArtworkStage(
                              track: track,
                              isPlaying: s.isPlaying,
                              isLoading: s.isLoading,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 64),
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

class _DesktopLyricStage extends StatelessWidget {
  const _DesktopLyricStage({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Column(
            key: ValueKey(track.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                track.artistName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: BlocBuilder<PlayerCubit, PlayerViewState>(
            buildWhen: (p, c) =>
                p.lyrics != c.lyrics ||
                p.currentLyricIndex != c.currentLyricIndex ||
                p.isLyricsLoading != c.isLyricsLoading ||
                p.currentIndex != c.currentIndex,
            builder: (context, state) {
              if (state.isLyricsLoading && state.lyrics.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.lyrics.isEmpty) {
                return Center(
                  child: Text(
                    '暂无歌词',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return LyricView(
                lines: state.lyrics,
                currentIndex: state.currentLyricIndex,
                onLineTap: (i) =>
                    context.read<PlayerCubit>().seekToLyricIndex(i),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DesktopBottomBar extends StatelessWidget {
  const _DesktopBottomBar({required this.state, required this.track});

  final PlayerViewState state;
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final artworkSourceContext = ArtworkSourceContext.track(track);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        // Phase 4: Desktop bottom bar with surface alpha: 0.92
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left: track info
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: track.artworkUrl,
                    size: 52,
                    borderRadius: 18,
                    sourceContext: artworkSourceContext,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, favState) {
                      final isFav =
                          favState.entries[track.id] ?? track.isFavorite;
                      return IconButton(
                        onPressed: () => context.read<FavoritesCubit>().toggle(
                          track.id,
                          currentValue: isFav,
                        ),
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? colorScheme.primary : null,
                        ),
                        tooltip: isFav ? '取消收藏' : '收藏',
                        style: IconButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: Colors.transparent,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Center: controls + timeline
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PlaybackControls(),
                  const SizedBox(height: 4),
                  _ProgressTimeline(),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Right: secondary actions + volume
            Expanded(
              flex: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showInlineVolume = constraints.maxWidth >= 260;
                  final sliderWidth = (constraints.maxWidth - 116)
                      .clamp(104.0, 160.0)
                      .toDouble();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (showInlineVolume) ...[
                        SizedBox(
                          width: sliderWidth,
                          child: const _DesktopVolumeControl(),
                        ),
                        const SizedBox(width: 8),
                      ] else
                        BlocBuilder<PlayerCubit, PlayerViewState>(
                          buildWhen: (prev, next) => prev.volume != next.volume,
                          builder: (context, playerState) {
                            return IconButton(
                              onPressed: () => _showVolumeSheet(context),
                              icon: Icon(_volumeIcon(playerState.volume)),
                              tooltip:
                                  '音量 ${_volumePercent(playerState.volume)}%',
                              style: IconButton.styleFrom(
                                side: BorderSide.none,
                                backgroundColor: Colors.transparent,
                              ),
                            );
                          },
                        ),
                      IconButton(
                        onPressed: () => QualityPickerSheet.show(context),
                        icon: const Icon(Icons.high_quality_rounded),
                        tooltip: '音质',
                        style: IconButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => BlocProvider.value(
                              value: context.read<PlayerCubit>(),
                              child: const QueueSheet(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.queue_music_rounded),
                        tooltip: '播放队列',
                        style: IconButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared components
// ---------------------------------------------------------------------------

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({required this.track, required this.state});

  final MusicTrack track;
  final PlayerViewState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final needsTrafficLightPadding = Platform.isMacOS;

    return Padding(
      padding: EdgeInsets.only(
        left: needsTrafficLightPadding ? 78 : 8,
        right: 8,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '收起',
            style: IconButton.styleFrom(
              side: BorderSide.none,
              backgroundColor: Colors.transparent,
            ),
          ),
          const Spacer(),
          // Sleep timer indicator
          if (state.sleepRemaining != null || state.sleepEndOfTrack)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bedtime_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    if (state.sleepRemaining != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        _formatSleep(state.sleepRemaining!),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontFeatures: [const ui.FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          BlocBuilder<DownloadsCubit, DownloadsState>(
            buildWhen: (p, c) =>
                p.completedTrackIds.contains(track.id) !=
                    c.completedTrackIds.contains(track.id) ||
                p.jobs.containsKey(track.id) != c.jobs.containsKey(track.id),
            builder: (context, dlState) {
              final downloaded = dlState.completedTrackIds.contains(track.id);
              final running = dlState.jobs.containsKey(track.id);

              // Only show in desktop top bar
              if (AppBreakpoints.isCompactWidth(
                MediaQuery.sizeOf(context).width,
              )) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: downloaded
                    ? '已下载'
                    : running
                    ? '下载进行中'
                    : '下载当前曲目',
                onPressed: downloaded || running
                    ? null
                    : () => context.read<DownloadsCubit>().enqueue(track),
                icon: Icon(
                  downloaded
                      ? Icons.download_done_rounded
                      : running
                      ? Icons.downloading_rounded
                      : Icons.download_rounded,
                  color: downloaded ? colorScheme.primary : null,
                ),
                style: IconButton.styleFrom(
                  side: BorderSide.none,
                  backgroundColor: Colors.transparent,
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => SleepTimerSheet.show(context),
            tooltip: '睡眠定时',
            icon: Icon(
              state.sleepRemaining != null || state.sleepEndOfTrack
                  ? Icons.bedtime_rounded
                  : Icons.bedtime_outlined,
              color: state.sleepRemaining != null || state.sleepEndOfTrack
                  ? colorScheme.primary
                  : null,
            ),
            style: IconButton.styleFrom(
              side: BorderSide.none,
              backgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  onTap: context.read<PlayerCubit>().previous,
                  tooltip: '上一曲',
                  size: 48,
                  iconSize: 26,
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  icon: s.isLoading
                      ? Icons.downloading_rounded
                      : (s.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                  isPrimary: true,
                  onTap: context.read<PlayerCubit>().togglePlayback,
                  tooltip: s.isPlaying ? '暂停' : '播放',
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  icon: Icons.skip_next_rounded,
                  onTap: context.read<PlayerCubit>().next,
                  tooltip: '下一曲',
                  size: 48,
                  iconSize: 26,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PlaybackModeButton(
              mode: playbackMode,
              onTap: context.read<PlayerCubit>().cyclePlaybackMode,
            ),
          ],
        );
      },
    );
  }
}

class _PlaybackModeButton extends StatelessWidget {
  const _PlaybackModeButton({required this.mode, required this.onTap});

  final PlaybackModeOption mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDefaultMode = mode == PlaybackModeOption.sequence;
    final foregroundColor = isDefaultMode
        ? colorScheme.onSurfaceVariant
        : colorScheme.primary;

    return Tooltip(
      message: '播放模式：${_playbackModeLabel(mode)}，点击切换',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDefaultMode
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.52)
                  : colorScheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDefaultMode
                    ? colorScheme.outlineVariant.withValues(alpha: 0.26)
                    : colorScheme.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_playbackModeIcon(mode), size: 16, color: foregroundColor),
                const SizedBox(width: 6),
                Text(
                  _playbackModeLabel(mode),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
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

class _DesktopVolumeControl extends StatelessWidget {
  const _DesktopVolumeControl();

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
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.onSurface.withValues(
                    alpha: 0.16,
                  ),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                    elevation: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: state.volume,
                  onChanged: context.read<PlayerCubit>().setVolume,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 34,
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
                        activeTrackColor: colorScheme.primary,
                        inactiveTrackColor: colorScheme.onSurface.withValues(
                          alpha: 0.14,
                        ),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                          elevation: 0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
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

class _ProgressTimeline extends StatefulWidget {
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
              width: 42,
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
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                    elevation: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  trackShape: _GlowingSliderTrackShape(
                    glowColor: colorScheme.primary,
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
              width: 42,
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
          // Subtle glow behind the disc
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.09),
                color: colorScheme.surface.withValues(alpha: 0.35),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
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

    final paint = Paint()
      ..color = const Color(0xFFDCDCDC)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.save();
    canvas.translate(w * 0.05, h * 0.04);
    _drawArm(canvas, shadowPaint, w, h);
    canvas.restore();

    _drawArm(canvas, paint, w, h);

    final pivotPaint = Paint()..color = const Color(0xFFE0E0E0);
    final pivotX = w * 0.5;
    final pivotY = h * 0.1;
    final pivotR = w * 0.25;
    canvas.drawCircle(Offset(pivotX, pivotY), pivotR, shadowPaint);
    canvas.drawCircle(Offset(pivotX, pivotY), pivotR, pivotPaint);
    final pivotCenter = Paint()..color = const Color(0xFF9E9E9E);
    canvas.drawCircle(Offset(pivotX, pivotY), pivotR * 0.3, pivotCenter);
  }

  void _drawArm(Canvas canvas, Paint paint, double w, double h) {
    final path = Path();
    path.moveTo(w * 0.44, h * 0.1);
    path.lineTo(w * 0.56, h * 0.1);
    path.lineTo(w * 0.5, h * 0.7);
    path.lineTo(w * 0.31, h * 0.9);
    path.lineTo(w * 0.25, h * 0.89);
    path.lineTo(w * 0.44, h * 0.7);
    path.close();
    canvas.drawPath(path, paint);

    canvas.save();
    canvas.translate(w * 0.275, h * 0.895);
    canvas.rotate(math.pi / 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.12, -h * 0.025, w * 0.25, h * 0.15),
        Radius.circular(w * 0.05),
      ),
      paint..color = const Color(0xFF9E9E9E),
    );
    canvas.restore();
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
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
    final scale = _pressed ? 0.93 : (_hovered ? 1.05 : 1.0);
    final btnSize = widget.size ?? (widget.isPrimary ? 60 : 42);
    final icnSize = widget.iconSize ?? (widget.isPrimary ? 30 : 22);

    final backgroundColor = widget.isPrimary
        ? colorScheme.primary
        : Colors.transparent;
    final foregroundColor = widget.isPrimary
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

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
        boxShadow: [
          if (widget.isPrimary)
            BoxShadow(
              color: colorScheme.primary.withValues(
                alpha: _hovered ? 0.45 : 0.22,
              ),
              blurRadius: _hovered ? 24 : 16,
              spreadRadius: _hovered ? 2 : 0,
              offset: const Offset(0, 6),
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
          color: const Color(0xFF121212),
          border: Border.all(color: Colors.white10, width: 1),
          gradient: const SweepGradient(
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2A2A2A),
              Color(0xFF1A1A1A),
              Color(0xFF2A2A2A),
              Color(0xFF1A1A1A),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: image,
      );
    }

    return RotationTransition(turns: _controller, child: image);
  }
}

// ---------------------------------------------------------------------------
// Glowing slider track
// ---------------------------------------------------------------------------

/// Custom slider track that paints a soft glow beneath the active segment.
class _GlowingSliderTrackShape extends RoundedRectSliderTrackShape {
  const _GlowingSliderTrackShape({required this.glowColor});

  final Color glowColor;

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
    final trackHeight = sliderTheme.trackHeight ?? 3.5;
    final trackLeft =
        offset.dx +
        (sliderTheme.trackShape
                ?.getPreferredRect(
                  parentBox: parentBox,
                  sliderTheme: sliderTheme,
                  offset: offset,
                  isEnabled: isEnabled,
                  isDiscrete: isDiscrete,
                )
                .left ??
            14);
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final activeWidth = thumbCenter.dx - trackLeft;

    // Paint the glow behind the active track
    if (activeWidth > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final glowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(trackLeft, trackTop - 2, activeWidth, trackHeight + 4),
        Radius.circular(trackHeight),
      );
      canvas.drawRRect(glowRect, glowPaint);
    }

    // Delegate to the standard track painter
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
    // macOS 使用隐藏标题栏，红绿灯悬浮在左上角，需要额外左侧间距避让
    final needsTrafficLightPadding = Platform.isMacOS;

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
              // -- 顶部栏：与 _PlayerTopBar 保持一致的间距和按钮风格 --
              Padding(
                padding: EdgeInsets.only(
                  left: needsTrafficLightPadding ? 78 : 8,
                  right: 8,
                  top: 4,
                  bottom: 4,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 32,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '收起',
                      style: IconButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    const Spacer(),
                  ],
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

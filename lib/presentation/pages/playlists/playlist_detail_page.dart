import 'package:cross_platform_music_player/application/usecases/fetch_playlist_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlist_detail_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlist_detail_state.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlaylistDetailPage extends StatelessWidget {
  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    this.playlist,
  });

  final String playlistId;
  final MusicPlaylist? playlist;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlaylistDetailCubit(
        FetchPlaylistTracks(context.read<MusicRepository>()),
      )..load(playlistId),
      child: _PlaylistDetailView(playlist: playlist),
    );
  }
}

class _PlaylistDetailView extends StatelessWidget {
  const _PlaylistDetailView({required this.playlist});

  final MusicPlaylist? playlist;

  @override
  Widget build(BuildContext context) {
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<PlaylistDetailCubit, PlaylistDetailState>(
      builder: (context, state) {
        final isWide = AppBreakpoints.usesWideContent(context);

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              BlurredCoverBackground(imageUrl: playlist?.artworkUrl),
              SafeArea(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < 420) {
                      context.read<PlaylistDetailCubit>().loadMore();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    slivers: isWide
                        ? _buildDesktopSlivers(context, state, currentTrackId)
                        : _buildMobileSlivers(context, state, currentTrackId),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildDesktopSlivers(
    BuildContext context,
    PlaylistDetailState state,
    String? currentTrackId,
  ) {
    return [
      SliverPadding(
        padding: AppPageLayout.sectionPadding(context, top: 10, bottom: 8),
        sliver: SliverToBoxAdapter(
          child: AppDetailBackNav(onPressed: () => _goBackToPlaylists(context)),
        ),
      ),
      SliverPadding(
        padding: AppPageLayout.sectionPadding(context, top: 2, bottom: 24),
        sliver: SliverToBoxAdapter(
          child: _PlaylistHero(
            playlist: playlist,
            tracksCount: state.tracks.length,
            isLoading:
                state.status == PlaylistDetailStatus.loading ||
                state.isLoadingAll,
            onPlayAll: () => _playPlaylistFromIndex(context, 0),
            onShuffleAll: () =>
                _playPlaylistFromIndex(context, 0, shuffled: true),
          ),
        ),
      ),
      switch (state.status) {
        PlaylistDetailStatus.loading => const AppSliverStateView.loading(),
        PlaylistDetailStatus.failure => AppSliverStateView.message(
          message: state.errorMessage ?? '加载歌单详情失败',
        ),
        _ =>
          state.tracks.isEmpty
              ? const AppSliverStateView.message(message: '当前歌单还没有歌曲。')
              : SliverPadding(
                  padding: AppPageLayout.sectionPadding(
                    context,
                    bottom: state.isLoadingMore ? 12 : 28,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: MusicTrackTable(
                      tracks: state.tracks,
                      currentTrackId: currentTrackId,
                      showActionBar: false,
                      onTrackTap: (index, _) =>
                          _playPlaylistFromIndex(context, index),
                    ),
                  ),
                ),
      },
      if (state.status == PlaylistDetailStatus.success && state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 4, 0, 28),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }

  List<Widget> _buildMobileSlivers(
    BuildContext context,
    PlaylistDetailState state,
    String? currentTrackId,
  ) {
    final trackCount = _playlistTrackCount(playlist, state.tracks.length);
    final isBusy =
        state.status == PlaylistDetailStatus.loading || state.isLoadingAll;

    return [
      SliverPadding(
        padding: AppPageLayout.sectionPadding(context, top: 2, bottom: 0),
        sliver: SliverToBoxAdapter(
          child: AppDetailBackNav(onPressed: () => _goBackToPlaylists(context)),
        ),
      ),
      SliverPadding(
        padding: AppPageLayout.sectionPadding(context, top: 8, bottom: 14),
        sliver: SliverToBoxAdapter(
          child: _MobilePlaylistHero(
            playlist: playlist,
            tracksCount: trackCount,
            isBusy: isBusy,
            hasLoadedTracks: state.tracks.isNotEmpty,
            onPlayAll: () => _playPlaylistFromIndex(context, 0),
            onShuffleAll: () =>
                _playPlaylistFromIndex(context, 0, shuffled: true),
          ),
        ),
      ),
      switch (state.status) {
        PlaylistDetailStatus.loading => const AppSliverStateView.loading(),
        PlaylistDetailStatus.failure => AppSliverStateView.message(
          message: state.errorMessage ?? '加载歌单详情失败',
        ),
        _ =>
          state.tracks.isEmpty
              ? const AppSliverStateView.message(message: '当前歌单还没有歌曲。')
              : _MobilePlaylistTrackSliver(
                  tracks: state.tracks,
                  currentTrackId: currentTrackId,
                  isLoadingMore: state.isLoadingMore,
                  onTrackTap: (index) => _playPlaylistFromIndex(context, index),
                ),
      },
      if (state.status == PlaylistDetailStatus.success && state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 4, 0, 28),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }
}

Future<void> _playPlaylistFromIndex(
  BuildContext context,
  int startIndex, {
  bool shuffled = false,
}) async {
  final cubit = context.read<PlaylistDetailCubit>();
  final state = cubit.state;

  if (shuffled) {
    await PlayerNavigation.shuffleAllAndOpenPlayer(
      context,
      loadedTracks: state.tracks,
      allLoaded: !state.hasMore,
      fetchAll: cubit.fetchPlaybackQueueTracks,
    );
    return;
  }

  await PlayerNavigation.playAllAndOpenPlayer(
    context,
    loadedTracks: state.tracks,
    allLoaded: !state.hasMore,
    fetchAll: cubit.fetchPlaybackQueueTracks,
    startIndex: startIndex,
  );
}

class _MobilePlaylistHero extends StatelessWidget {
  const _MobilePlaylistHero({
    required this.playlist,
    required this.tracksCount,
    required this.isBusy,
    required this.hasLoadedTracks,
    required this.onPlayAll,
    required this.onShuffleAll,
  });

  final MusicPlaylist? playlist;
  final int tracksCount;
  final bool isBusy;
  final bool hasLoadedTracks;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffleAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _playlistTitle(playlist);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCoverSize = constraints.maxWidth - 64;
        final coverSize = maxCoverSize.clamp(132.0, 164.0).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MobilePlaylistArtwork(
              imageUrl: playlist?.artworkUrl ?? '',
              size: coverSize,
              semanticLabel: '《$title》歌单封面',
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$tracksCount 首歌曲',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MobilePlaylistActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: '播放',
                  primary: true,
                  isLoading: isBusy,
                  onPressed: hasLoadedTracks && !isBusy ? onPlayAll : null,
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: '随机播放',
                  child: IconButton(
                    onPressed: hasLoadedTracks && !isBusy ? onShuffleAll : null,
                    style: AppActionButtonStyle.icon(
                      context,
                      tone: AppActionButtonTone.secondary,
                    ),
                    icon: const Icon(Icons.shuffle_rounded),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MobilePlaylistArtwork extends StatelessWidget {
  const _MobilePlaylistArtwork({
    required this.imageUrl,
    required this.size,
    required this.semanticLabel,
  });

  final String imageUrl;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
        color: colorScheme.surface.withValues(alpha: 0.28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.46),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.musicRose.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.20 : 0.15,
            ),
            blurRadius: 32,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: CachedArtwork(
          imageUrl: imageUrl,
          size: size,
          borderRadius: AppRadiusTokens.mobileLg - 2,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

class _MobilePlaylistActionButton extends StatelessWidget {
  const _MobilePlaylistActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: isLoading
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary ? colorScheme.onPrimary : colorScheme.primary,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: AppActionButtonStyle.text(
          context,
          tone: primary
              ? AppActionButtonTone.primary
              : AppActionButtonTone.neutral,
          dense: false,
        ),
      ),
    );
  }
}

class _MobilePlaylistTrackSliver extends StatelessWidget {
  const _MobilePlaylistTrackSliver({
    required this.tracks,
    required this.currentTrackId,
    required this.isLoadingMore,
    required this.onTrackTap,
  });

  final List<MusicTrack> tracks;
  final String? currentTrackId;
  final bool isLoadingMore;
  final Future<void> Function(int index) onTrackTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = _mobileContentBottomInset(
      context,
      hasMiniPlayer: currentTrackId != null,
    );

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacingTokens.mobilePageX,
        0,
        AppSpacingTokens.mobilePageX,
        isLoadingMore ? 12 : bottomInset,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _MobilePlaylistSectionHeader(count: tracks.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final track = tracks[index];
              return _MobilePlaylistTrackRow(
                track: track,
                index: index,
                selected: track.id == currentTrackId,
                onTap: () => onTrackTap(index),
                onLongPress: () => showTrackActionsSheet(context, track),
              );
            }, childCount: tracks.length),
          ),
        ],
      ),
    );
  }
}

class _MobilePlaylistSectionHeader extends StatelessWidget {
  const _MobilePlaylistSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 8),
      child: Row(
        children: [
          Text(
            '歌曲',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count 首',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePlaylistTrackRow extends StatefulWidget {
  const _MobilePlaylistTrackRow({
    required this.track,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final MusicTrack track;
  final int index;
  final bool selected;
  final Future<void> Function() onTap;
  final VoidCallback onLongPress;

  @override
  State<_MobilePlaylistTrackRow> createState() =>
      _MobilePlaylistTrackRowState();
}

class _MobilePlaylistTrackRowState extends State<_MobilePlaylistTrackRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = widget.selected;

    return Semantics(
      label: '播放《${widget.track.title}》',
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: selected
                ? theme.selectedWash
                : _pressed
                ? theme.hoverWash
                : Colors.transparent,
            borderRadius: selected || _pressed
                ? BorderRadius.circular(AppRadiusTokens.mobileSm)
                : BorderRadius.zero,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.mobileSm),
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              hoverColor: Colors.transparent,
              focusColor: colorScheme.primary.withValues(alpha: 0.08),
              splashColor: colorScheme.primary.withValues(alpha: 0.06),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: selected
                          ? Icon(
                              Icons.graphic_eq_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            )
                          : Text(
                              '${widget.index + 1}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.78,
                                ),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _trackSubtitle(widget.track),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MobilePlaylistTrackActions(
                      track: widget.track,
                      onPlay: widget.onTap,
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

class _MobilePlaylistTrackActions extends StatelessWidget {
  const _MobilePlaylistTrackActions({
    required this.track,
    required this.onPlay,
  });

  final MusicTrack track;
  final Future<void> Function() onPlay;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      buildWhen: (previous, next) =>
          previous.entries[track.id] != next.entries[track.id] ||
          previous.pending.contains(track.id) !=
              next.pending.contains(track.id),
      builder: (context, favoritesState) {
        final isFavorite = favoritesState.entries[track.id] ?? track.isFavorite;
        final isPending = favoritesState.pending.contains(track.id);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MobilePlaylistTrackIconButton(
              icon: Icons.play_arrow_rounded,
              tooltip: '播放歌曲',
              onPressed: onPlay,
            ),
            _MobilePlaylistTrackIconButton(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              tooltip: isFavorite ? '取消收藏' : '收藏',
              selected: isFavorite,
              enabled: !isPending,
              onPressed: () async {
                await context.read<FavoritesCubit>().toggle(
                  track.id,
                  currentValue: isFavorite,
                );
              },
            ),
            _MobilePlaylistTrackIconButton(
              icon: Icons.playlist_add_rounded,
              tooltip: '加入队列',
              onPressed: () => _addTrackToQueue(context, track),
            ),
          ],
        );
      },
    );
  }
}

class _MobilePlaylistTrackIconButton extends StatelessWidget {
  const _MobilePlaylistTrackIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function() onPressed;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        style: AppActionButtonStyle.icon(
          context,
          selected: selected,
          iconSize: 18,
        ),
      ),
    );
  }
}

Future<void> _addTrackToQueue(BuildContext context, MusicTrack track) async {
  await context.read<PlayerCubit>().addToQueue(track);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('已加入队列：${track.title}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

class _PlaylistHero extends StatelessWidget {
  const _PlaylistHero({
    required this.playlist,
    required this.tracksCount,
    required this.onPlayAll,
    required this.onShuffleAll,
    required this.isLoading,
  });

  final MusicPlaylist? playlist;
  final int tracksCount;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffleAll;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trackCountLabel = tracksCount == 0
        ? (playlist?.trackCount ?? 0)
        : tracksCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final coverSize = constraints.maxWidth < 820 ? 172.0 : 200.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _PlaylistHeroArtwork(
              imageUrl: playlist?.artworkUrl ?? '',
              size: coverSize,
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '歌单',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.32,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      playlist?.name ?? '歌单详情',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 32,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$trackCountLabel 首歌曲',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    PlayAllButton(
                      variant: PlayAllButtonVariant.primary,
                      onPressed: tracksCount == 0 || isLoading
                          ? null
                          : onPlayAll,
                      onShufflePressed: tracksCount == 0 || isLoading
                          ? null
                          : onShuffleAll,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void _goBackToPlaylists(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).maybePop();
    return;
  }
  context.go('/playlists');
}

int _playlistTrackCount(MusicPlaylist? playlist, int loadedCount) {
  return loadedCount == 0 ? (playlist?.trackCount ?? 0) : loadedCount;
}

String _playlistTitle(MusicPlaylist? playlist) {
  final name = playlist?.name.trim();
  if (name == null || name.isEmpty) return '歌单详情';
  return name;
}

String _trackSubtitle(MusicTrack track) {
  final parts = [
    track.artistName.trim(),
    track.albumTitle.trim(),
  ].where((value) => value.isNotEmpty).toList();
  return parts.isEmpty ? '未知艺术家' : parts.join(' · ');
}

double _mobileContentBottomInset(
  BuildContext context, {
  required bool hasMiniPlayer,
}) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  return safeBottom +
      AppSpacingTokens.mobileTabContentHeight +
      (hasMiniPlayer ? AppSpacingTokens.mobileMiniPlayerHeight + 48 : 38);
}

class _PlaylistHeroArtwork extends StatelessWidget {
  const _PlaylistHeroArtwork({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadiusTokens.coverDetail),
        color: colorScheme.surface.withValues(alpha: 0.24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorTokens.darkScaffold.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: CachedArtwork(
          imageUrl: imageUrl,
          size: size,
          borderRadius: AppRadiusTokens.coverDetail - 4,
        ),
      ),
    );
  }
}

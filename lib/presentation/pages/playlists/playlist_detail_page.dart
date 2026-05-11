import 'package:cross_platform_music_player/application/usecases/fetch_playlist_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlist_detail_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlist_detail_state.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(backgroundColor: Colors.transparent),
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
                    slivers: [
                      SliverPadding(
                        padding: AppPageLayout.sectionPadding(
                          context,
                          top: 10,
                          bottom: 18,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _PlaylistHero(
                            playlist: playlist,
                            tracksCount: state.tracks.length,
                          ),
                        ),
                      ),
                      switch (state.status) {
                        PlaylistDetailStatus.loading =>
                          const AppSliverStateView.loading(),
                        PlaylistDetailStatus.failure =>
                          AppSliverStateView.message(
                            message: state.errorMessage ?? '加载歌单详情失败',
                          ),
                        _ =>
                          state.tracks.isEmpty
                              ? const AppSliverStateView.message(
                                  message: '当前歌单还没有歌曲。',
                                )
                              : SliverPadding(
                                  padding: AppPageLayout.sectionPadding(
                                    context,
                                    bottom: state.isLoadingMore ? 12 : 28,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      if (index == 0) {
                                        return _PlaylistTracksHeader(
                                          tracksCount: state.tracks.length,
                                          totalTracksCount:
                                              playlist?.trackCount,
                                          onPlayAll: () =>
                                              _playPlaylistFromIndex(
                                                context,
                                                0,
                                              ),
                                        );
                                      }

                                      final trackIndex = index - 1;
                                      final track = state.tracks[trackIndex];
                                      return _PlaylistTrackRow(
                                        isFirst: false,
                                        isLast:
                                            trackIndex ==
                                                state.tracks.length - 1 &&
                                            !state.isLoadingMore,
                                        child: MusicTrackTile.row(
                                          isCurrent: track.id == currentTrackId,
                                          artworkUrl: track.artworkUrl,
                                          title: track.title,
                                          subtitle:
                                              '${track.artistName} · ${track.albumTitle}',
                                          onTap: () => _playPlaylistFromIndex(
                                            context,
                                            trackIndex,
                                          ),
                                        ),
                                      );
                                    }, childCount: state.tracks.length + 1),
                                  ),
                                ),
                      },
                      if (state.status == PlaylistDetailStatus.success &&
                          state.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 4, 0, 28),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
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

Future<void> _playPlaylistFromIndex(
  BuildContext context,
  int startIndex,
) async {
  final tracks = await context
      .read<PlaylistDetailCubit>()
      .ensureAllTracksLoaded();
  if (!context.mounted || tracks.isEmpty) return;
  final safeIndex = startIndex.clamp(0, tracks.length - 1).toInt();
  PlayerNavigation.playTracksAndOpenPlayer(
    context,
    tracks: tracks,
    startIndex: safeIndex,
  );
}

class _PlaylistTracksHeader extends StatelessWidget {
  const _PlaylistTracksHeader({
    required this.tracksCount,
    required this.onPlayAll,
    this.totalTracksCount,
  });

  final int tracksCount;
  final int? totalTracksCount;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = totalTracksCount ?? tracksCount;
    final subtitle = total > tracksCount
        ? '已加载 $tracksCount / $total 首'
        : '$tracksCount 首歌曲';

    return _PlaylistTrackRow(
      isFirst: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: FilledButton(
                onPressed: tracksCount == 0 ? null : onPlayAll,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 30),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '播放全部',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: null,
              tooltip: '筛选',
              icon: const Icon(Icons.filter_list_rounded),
            ),
            IconButton(
              onPressed: null,
              tooltip: '排序',
              icon: const Icon(Icons.sort_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistTrackRow extends StatelessWidget {
  const _PlaylistTrackRow({
    required this.child,
    this.isFirst = false,
    this.isLast = false,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(28) : Radius.zero,
          bottom: isLast ? const Radius.circular(28) : Radius.zero,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          isFirst ? 12 : 0,
          14,
          isLast ? 18 : 12,
        ),
        child: child,
      ),
    );
  }
}

class _PlaylistHero extends StatelessWidget {
  const _PlaylistHero({required this.playlist, required this.tracksCount});

  final MusicPlaylist? playlist;
  final int tracksCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.usesWideContentWidth(
          constraints.maxWidth,
        );
        final coverSize = isWide ? 220.0 : 128.0;
        final titleStyle = isWide
            ? theme.textTheme.headlineMedium
            : theme.textTheme.headlineSmall;

        return Padding(
          padding: EdgeInsets.fromLTRB(0, isWide ? 8 : 10, 0, isWide ? 8 : 4),
          child: Flex(
            direction: isWide ? Axis.horizontal : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PlaylistHeroArtwork(
                imageUrl: playlist?.artworkUrl ?? '',
                size: coverSize,
              ),
              SizedBox(width: isWide ? 28 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const MetaPill(label: '歌单', size: MetaPillSize.compact),
                        MetaPill(
                          label:
                              '${tracksCount == 0 ? (playlist?.trackCount ?? 0) : tracksCount} 首',
                          size: MetaPillSize.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      playlist?.name ?? '歌单详情',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playlist == null ? '正在加载歌单歌曲' : '轻触歌曲开始播放，继续下滑查看更多',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surface.withValues(alpha: 0.24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: CachedArtwork(imageUrl: imageUrl, size: size, borderRadius: 18),
      ),
    );
  }
}

// Phase 4: Track row with hover shadow

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
                          bottom: 10,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _PlaylistHero(
                            playlist: playlist,
                            tracksCount: state.tracks.length,
                            isLoading:
                                state.status == PlaylistDetailStatus.loading ||
                                state.isLoadingAll,
                            onPlayAll: () => _playPlaylistFromIndex(context, 0),
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
                                      final track = state.tracks[index];
                                      final isWide =
                                          AppBreakpoints.usesWideContent(
                                            context,
                                          );
                                      return _PlaylistTrackRow(
                                        isFirst:
                                            index == 0 &&
                                            (isWide || state.tracks.isNotEmpty),
                                        isLast:
                                            index == state.tracks.length - 1 &&
                                            !state.isLoadingMore,
                                        isWide: isWide,
                                        child: MusicTrackTile.row(
                                          isCurrent: track.id == currentTrackId,
                                          artworkUrl: track.artworkUrl,
                                          title: track.title,
                                          subtitle:
                                              '${track.artistName} · ${track.albumTitle}',
                                          onTap: () => _playPlaylistFromIndex(
                                            context,
                                            index,
                                          ),
                                        ),
                                      );
                                    }, childCount: state.tracks.length),
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

class _PlaylistTrackRow extends StatelessWidget {
  const _PlaylistTrackRow({
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.isWide = true,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = isWide ? 28.0 : 14.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: isWide ? 0.94 : 0.92),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(radius) : Radius.zero,
          bottom: isLast ? Radius.circular(radius) : Radius.zero,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isWide ? 14 : 12,
          isFirst ? 12 : 0,
          isWide ? 14 : 12,
          isLast ? 18 : 12,
        ),
        child: child,
      ),
    );
  }
}

class _PlaylistHero extends StatelessWidget {
  const _PlaylistHero({
    required this.playlist,
    required this.tracksCount,
    required this.onPlayAll,
    required this.isLoading,
  });

  final MusicPlaylist? playlist;
  final int tracksCount;
  final VoidCallback onPlayAll;
  final bool isLoading;

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (!isWide) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: tracksCount == 0 || isLoading
                            ? null
                            : onPlayAll,
                        icon: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: const Text('播放全部'),
                      ),
                    ],
                    if (isWide) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: tracksCount == 0 || isLoading
                            ? null
                            : onPlayAll,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: const Text('播放全部'),
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

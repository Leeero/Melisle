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
                    slivers: [
                      if (!isWide)
                        SliverPadding(
                          padding: AppPageLayout.sectionPadding(
                            context,
                            top: 2,
                            bottom: 0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: AppDetailBackNav(
                              onPressed: () => _goBackToPlaylists(context),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: AppPageLayout.sectionPadding(
                          context,
                          top: isWide ? 10 : 2,
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
                                  sliver: isWide
                                      ? SliverToBoxAdapter(
                                          child: MusicTrackTable(
                                            tracks: state.tracks,
                                            currentTrackId: currentTrackId,
                                            showActionBar: false,
                                            onTrackTap: (index, _) =>
                                                _playPlaylistFromIndex(
                                                  context,
                                                  index,
                                                ),
                                          ),
                                        )
                                      : SliverList(
                                          delegate: SliverChildBuilderDelegate((
                                            context,
                                            index,
                                          ) {
                                            final track = state.tracks[index];
                                            return MusicTrackTile.row(
                                              isCurrent:
                                                  track.id == currentTrackId,
                                              artworkUrl: track.artworkUrl,
                                              title: track.title,
                                              subtitle:
                                                  '${track.artistName} · ${track.albumTitle}',
                                              onTap: () =>
                                                  _playPlaylistFromIndex(
                                                    context,
                                                    index,
                                                  ),
                                              onLongPress: () =>
                                                  showTrackActionsSheet(
                                                    context,
                                                    track,
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
  final cubit = context.read<PlaylistDetailCubit>();
  final state = cubit.state;
  await PlayerNavigation.playAllAndOpenPlayer(
    context,
    loadedTracks: state.tracks,
    allLoaded: !state.hasMore,
    fetchAll: cubit.fetchPlaybackQueueTracks,
    startIndex: startIndex,
  );
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
        final titleStyle = isWide
            ? theme.textTheme.headlineMedium
            : theme.textTheme.headlineSmall;

        return AppDetailHeroFrame(
          padding: isWide
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(0, 16, 0, 24),
          compactGap: 16,
          spacing: 28,
          coverBuilder: (context, isWide) {
            return _PlaylistHeroArtwork(
              imageUrl: playlist?.artworkUrl ?? '',
              size: isWide ? 188 : 208,
            );
          },
          contentBuilder: (context, isWide) {
            final alignment = isWide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center;
            final trackCountLabel = tracksCount == 0
                ? (playlist?.trackCount ?? 0)
                : tracksCount;
            return Column(
              crossAxisAlignment: alignment,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: isWide
                      ? WrapAlignment.start
                      : WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const MetaPill(label: '歌单', size: MetaPillSize.compact),
                    MetaPill(
                      label: '$trackCountLabel 首',
                      size: MetaPillSize.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  playlist?.name ?? '歌单详情',
                  maxLines: isWide ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isWide ? TextAlign.start : TextAlign.center,
                  style: titleStyle?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$trackCountLabel 首歌曲',
                  textAlign: isWide ? TextAlign.start : TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: isWide ? 24 : 14),
                Wrap(
                  alignment: isWide
                      ? WrapAlignment.start
                      : WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    PlayAllButton(
                      variant: isWide
                          ? PlayAllButtonVariant.primary
                          : PlayAllButtonVariant.compact,
                      onPressed: tracksCount == 0 || isLoading
                          ? null
                          : onPlayAll,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ],
            );
          },
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

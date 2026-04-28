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
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Stack(
            fit: StackFit.expand,
            children: [
              BlurredCoverBackground(imageUrl: playlist?.artworkUrl),
              SafeArea(
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
                      _ => SliverPadding(
                        padding: AppPageLayout.sectionPadding(
                          context,
                          bottom: 28,
                        ),
                        sliver: state.tracks.isEmpty
                            ? const AppSliverStateView.message(
                                message: '当前歌单还没有歌曲。',
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final track = state.tracks[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: MusicTrackTile.row(
                                      isCurrent: track.id == currentTrackId,
                                      artworkUrl: track.artworkUrl,
                                      title: track.title,
                                      subtitle:
                                          '${track.artistName} · ${track.albumTitle}',
                                      onTap: () =>
                                          PlayerNavigation.playTracksAndOpenPlayer(
                                            context,
                                            tracks: state.tracks,
                                            startIndex: index,
                                          ),
                                    ),
                                  );
                                }, childCount: state.tracks.length),
                              ),
                      ),
                    },
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

class _PlaylistHero extends StatelessWidget {
  const _PlaylistHero({required this.playlist, required this.tracksCount});

  final MusicPlaylist? playlist;
  final int tracksCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDetailHeroFrame(
      coverBuilder: (context, isWide) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: colorScheme.surface.withValues(alpha: 0.22),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
            // Phase 4: Cover BoxShadow
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CachedArtwork(
              imageUrl: playlist?.artworkUrl ?? '',
              size: isWide ? 250 : 210,
              borderRadius: 24,
            ),
          ),
        );
      },
      contentBuilder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const MetaPill(label: '歌单详情', size: MetaPillSize.compact),
                MetaPill(
                  label:
                      '${tracksCount == 0 ? (playlist?.trackCount ?? 0) : tracksCount} 首',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              playlist?.name ?? '歌单详情',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              playlist == null ? '正在从 Emby 加载歌单歌曲。' : '进入更沉浸、更轻盈的歌单播放模式。',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: tracksCount == 0
                      ? null
                      : () => PlayerNavigation.playTracksAndOpenPlayer(
                          context,
                          tracks: context
                              .read<PlaylistDetailCubit>()
                              .state
                              .tracks,
                          startIndex: 0,
                        ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('播放歌单'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/playlists'),
                  icon: const Icon(Icons.queue_music_rounded),
                  label: const Text('返回歌单'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// Phase 4: Track row with hover shadow

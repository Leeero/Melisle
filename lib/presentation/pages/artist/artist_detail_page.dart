import 'package:cross_platform_music_player/application/usecases/fetch_artist_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_artist_top_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/section_header.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ArtistDetailPage extends StatelessWidget {
  const ArtistDetailPage({super.key, required this.artistId, this.artist});

  final String artistId;
  final MusicArtist? artist;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final repository = context.read<MusicRepository>();
        return ArtistCubit(
          fetchArtistAlbums: FetchArtistAlbums(repository),
          fetchArtistTopTracks: FetchArtistTopTracks(repository),
        )..load(artistId, seed: artist);
      },
      child: _ArtistDetailView(seed: artist),
    );
  }
}

class _ArtistDetailView extends StatelessWidget {
  const _ArtistDetailView({required this.seed});

  final MusicArtist? seed;

  @override
  Widget build(BuildContext context) {
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<ArtistCubit, ArtistState>(
      builder: (context, state) {
        final artist = state.artist ?? seed;
        final coverUrl =
            artist?.artworkUrl ??
            (state.albums.isNotEmpty ? state.albums.first.artworkUrl : null);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Stack(
            fit: StackFit.expand,
            children: [
              BlurredCoverBackground(imageUrl: coverUrl),
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
                        child: _ArtistHero(
                          artist: artist,
                          albumCount: state.albums.length,
                          topTrackCount: state.topTracks.length,
                        ),
                      ),
                    ),
                    if (state.status == ArtistStatus.loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.status == ArtistStatus.failure)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(state.errorMessage ?? '加载艺术家失败'),
                          ),
                        ),
                      )
                    else ...[
                      if (state.topTracks.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: '热门曲目',
                            trailing: FilledButton.tonalIcon(
                              onPressed: () =>
                                  PlayerNavigation.playAllAndOpenPlayer(
                                    context,
                                    loadedTracks: state.topTracks,
                                    allLoaded: true,
                                    fetchAll: () async => state.topTracks,
                                  ),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: const Text('播放全部'),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final track = state.topTracks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: MusicTrackTile.row(
                                  isCurrent: track.id == currentTrackId,
                                  artworkUrl: track.artworkUrl,
                                  title: track.title,
                                  subtitle: track.albumTitle,
                                  onTap: () =>
                                      PlayerNavigation.playTracksAndOpenPlayer(
                                        context,
                                        tracks: state.topTracks,
                                        startIndex: index,
                                      ),
                                  onLongPress: () =>
                                      showTrackActionsSheet(context, track),
                                ),
                              );
                            }, childCount: state.topTracks.length),
                          ),
                        ),
                      ],
                      if (state.albums.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: SectionHeader(title: '专辑'),
                        ),
                        SliverPadding(
                          padding: AppPageLayout.sectionPadding(
                            context,
                            bottom: 28,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.78,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final album = state.albums[index];
                              return MusicAlbumCompactCard(
                                album: album,
                                onTap: () => context.push(
                                  '/album/${album.id}',
                                  extra: album,
                                ),
                              );
                            }, childCount: state.albums.length),
                          ),
                        ),
                      ],
                      if (state.albums.isEmpty && state.topTracks.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('这位艺术家暂无内容。'),
                            ),
                          ),
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

class _ArtistHero extends StatelessWidget {
  const _ArtistHero({
    required this.artist,
    required this.albumCount,
    required this.topTrackCount,
  });

  final MusicArtist? artist;
  final int albumCount;
  final int topTrackCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveAlbumCount = albumCount > 0
        ? albumCount
        : (artist?.albumCount ?? 0);
    final effectiveTrackCount = topTrackCount > 0
        ? topTrackCount
        : (artist?.trackCount ?? 0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // Phase 4: Hero background surfaceContainerHighest alpha: 0.4
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = AppBreakpoints.usesWideContentWidth(
            constraints.maxWidth,
          );

          final cover = ClipOval(
            child: SizedBox(
              width: isWide ? 180 : 150,
              height: isWide ? 180 : 150,
              child: CachedArtwork(
                imageUrl: artist?.artworkUrl ?? '',
                size: isWide ? 180 : 150,
                borderRadius: 999,
              ),
            ),
          );

          final meta = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  const MetaPill(label: '艺术家', size: MetaPillSize.compact),
                  MetaPill(
                    label: '$effectiveAlbumCount 张专辑',
                    size: MetaPillSize.compact,
                  ),
                  MetaPill(
                    label: '$effectiveTrackCount 首热门',
                    size: MetaPillSize.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                artist?.name ?? '艺术家',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '来自媒体库的全部作品',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: cover),
                const SizedBox(height: 18),
                meta,
              ],
            );
          }

          return Row(
            children: [
              cover,
              const SizedBox(width: 24),
              Expanded(child: meta),
            ],
          );
        },
      ),
    );
  }
}

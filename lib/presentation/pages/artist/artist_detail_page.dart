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
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
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
        final isWide = AppBreakpoints.usesWideContent(context);
        final artist = state.artist ?? seed;
        final coverUrl =
            artist?.artworkUrl ??
            (state.albums.isNotEmpty ? state.albums.first.artworkUrl : null);

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              BlurredCoverBackground(imageUrl: coverUrl),
              SafeArea(
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
                            onPressed: () => _goBackToLibrary(context),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: AppPageLayout.sectionPadding(
                        context,
                        top: isWide ? 10 : 2,
                        bottom: 18,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _ArtistHero(
                          artist: artist,
                          albumCount: state.albums.length,
                          topTrackCount: state.topTracks.length,
                          onPlayTopTracks: state.topTracks.isEmpty
                              ? null
                              : () => PlayerNavigation.playAllAndOpenPlayer(
                                  context,
                                  loadedTracks: state.topTracks,
                                  allLoaded: true,
                                  fetchAll: () async => state.topTracks,
                                ),
                        ),
                      ),
                    ),
                    if (state.status == ArtistStatus.loading)
                      const AppSliverStateView.loading()
                    else if (state.status == ArtistStatus.failure)
                      AppSliverStateView.message(
                        message: state.errorMessage ?? '加载艺术家失败',
                      )
                    else ...[
                      if (state.topTracks.isNotEmpty) ...[
                        SliverPadding(
                          padding: AppPageLayout.sectionPadding(
                            context,
                            bottom: 0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: AppSectionTitleRow(
                              title: '热门曲目',
                              action: PlayAllButton(
                                variant: PlayAllButtonVariant.compact,
                                onPressed: () =>
                                    PlayerNavigation.playAllAndOpenPlayer(
                                      context,
                                      loadedTracks: state.topTracks,
                                      allLoaded: true,
                                      fetchAll: () async => state.topTracks,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: AppPageLayout.sectionPadding(
                            context,
                            bottom: 16,
                          ),
                          sliver: isWide
                              ? SliverToBoxAdapter(
                                  child: MusicTrackTable(
                                    tracks: state.topTracks,
                                    currentTrackId: currentTrackId,
                                    showActionBar: false,
                                    onTrackTap: (index, _) =>
                                        PlayerNavigation.playTracksAndOpenPlayer(
                                          context,
                                          tracks: state.topTracks,
                                          startIndex: index,
                                        ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final track = state.topTracks[index];
                                    return MusicTrackTile.row(
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
                                    );
                                  }, childCount: state.topTracks.length),
                                ),
                        ),
                      ],
                      if (state.albums.isNotEmpty) ...[
                        SliverPadding(
                          padding: AppPageLayout.sectionPadding(
                            context,
                            bottom: 0,
                          ),
                          sliver: const SliverToBoxAdapter(
                            child: AppSectionTitleRow(title: '专辑'),
                          ),
                        ),
                        SliverPadding(
                          padding: AppPageLayout.sectionPadding(
                            context,
                            bottom: 28,
                          ),
                          sliver: isWide
                              ? SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 200,
                                        mainAxisSpacing: 22,
                                        crossAxisSpacing: 18,
                                        childAspectRatio: 0.78,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final album = state.albums[index];
                                    return MusicAlbumGridCard(
                                      album: album,
                                      onTap: () => context.push(
                                        '/album/${album.id}',
                                        extra: album,
                                      ),
                                    );
                                  }, childCount: state.albums.length),
                                )
                              : SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: 216,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: state.albums.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final album = state.albums[index];
                                        return SizedBox(
                                          width: 150,
                                          child: MusicAlbumGridCard(
                                            album: album,
                                            onTap: () => context.push(
                                              '/album/${album.id}',
                                              extra: album,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      ],
                      if (state.albums.isEmpty && state.topTracks.isEmpty)
                        const AppSliverStateView.message(message: '这位艺术家暂无内容。'),
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
    required this.onPlayTopTracks,
  });

  final MusicArtist? artist;
  final int albumCount;
  final int topTrackCount;
  final VoidCallback? onPlayTopTracks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveAlbumCount = albumCount > 0
        ? albumCount
        : (artist?.albumCount ?? 0);
    final effectiveTrackCount = topTrackCount > 0
        ? topTrackCount
        : (artist?.trackCount ?? 0);

    return AppDetailHeroFrame(
      padding: AppBreakpoints.usesWideContent(context)
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(0, 16, 0, 24),
      compactGap: 16,
      coverBuilder: (context, isWide) {
        return ClipOval(
          child: SizedBox(
            width: isWide ? 200 : 220,
            height: isWide ? 200 : 220,
            child: CachedArtwork(
              imageUrl: artist?.artworkUrl ?? '',
              size: isWide ? 200 : 220,
              borderRadius: 999,
            ),
          ),
        );
      },
      contentBuilder: (context, isWide) {
        final alignment = isWide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center;
        return Column(
          crossAxisAlignment: alignment,
          children: [
            Wrap(
              alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
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
              textAlign: isWide ? TextAlign.start : TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              '来自媒体库的全部作品',
              textAlign: isWide ? TextAlign.start : TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            PlayAllButton(
              variant: isWide
                  ? PlayAllButtonVariant.primary
                  : PlayAllButtonVariant.compact,
              onPressed: onPlayTopTracks,
            ),
          ],
        );
      },
    );
  }
}

void _goBackToLibrary(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).maybePop();
    return;
  }
  context.go('/library');
}

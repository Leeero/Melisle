import 'package:cross_platform_music_player/application/usecases/fetch_artist_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_artist_top_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
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
                          child: _SectionHeaderWithPlayAll(
                            title: '热门曲目',
                            tracks: state.topTracks,
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
                                child: _TrackRow(
                                  trackId: track.id,
                                  currentTrackId: currentTrackId,
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
                          child: _SectionHeader(title: '专辑'),
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
                              return _AlbumCard(album: album);
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
          final isWide = constraints.maxWidth >= 720;

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
                  _MetaPill(label: '艺术家'),
                  _MetaPill(label: '$effectiveAlbumCount 张专辑'),
                  _MetaPill(label: '$effectiveTrackCount 首热门'),
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

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final MusicAlbum album;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/album/${album.id}', extra: album),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedArtwork(
                    imageUrl: album.artworkUrl,
                    size: 160,
                    borderRadius: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  album.year == null ? album.artistName : '${album.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

// Phase 4: Track row with hover shadow
class _TrackRow extends StatefulWidget {
  const _TrackRow({
    required this.trackId,
    required this.currentTrackId,
    required this.artworkUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  final String trackId;
  final String? currentTrackId;
  final String artworkUrl;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;
  final VoidCallback? onLongPress;

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrent = widget.trackId == widget.currentTrackId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isCurrent
              ? colorScheme.primaryContainer.withValues(alpha: 0.8)
              : colorScheme.surface.withValues(alpha: _hovered ? 0.82 : 0.62),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary.withValues(alpha: 0.28)
                : colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
          boxShadow: _hovered && !isCurrent
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: widget.artworkUrl,
                    size: 48,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isCurrent
                        ? Icons.graphic_eq_rounded
                        : Icons.play_arrow_rounded,
                    color: isCurrent
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionHeaderWithPlayAll extends StatelessWidget {
  const _SectionHeaderWithPlayAll({required this.title, required this.tracks});

  final String title;
  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (tracks.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: () => PlayerNavigation.playAllAndOpenPlayer(
                context,
                loadedTracks: tracks,
                allLoaded: true, // 艺术家热门曲目一次加载完毕
                fetchAll: () async => tracks,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('播放全部'),
            ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

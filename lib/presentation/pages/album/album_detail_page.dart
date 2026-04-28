import 'package:cross_platform_music_player/application/usecases/fetch_album_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AlbumDetailPage extends StatelessWidget {
  const AlbumDetailPage({super.key, required this.albumId, this.album});

  final String albumId;
  final MusicAlbum? album;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AlbumCubit(FetchAlbumTracks(context.read<MusicRepository>()))
            ..load(albumId),
      child: _AlbumDetailView(album: album),
    );
  }
}

class _AlbumDetailView extends StatelessWidget {
  const _AlbumDetailView({required this.album});

  final MusicAlbum? album;

  @override
  Widget build(BuildContext context) {
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<AlbumCubit, AlbumState>(
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Stack(
            fit: StackFit.expand,
            children: [
              BlurredCoverBackground(imageUrl: album?.artworkUrl),
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                      sliver: SliverToBoxAdapter(
                        child: _AlbumHero(
                          album: album,
                          tracksCount: state.tracks.length,
                        ),
                      ),
                    ),
                    switch (state.status) {
                      AlbumStatus.loading => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      AlbumStatus.failure => SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(state.errorMessage ?? '加载专辑失败'),
                          ),
                        ),
                      ),
                      _ => SliverPadding(
                        padding: AppPageLayout.sectionPadding(
                          context,
                          bottom: 28,
                        ),
                        sliver: state.tracks.isEmpty
                            ? const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 28),
                                  child: Center(child: Text('当前专辑还没有曲目。')),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final track = state.tracks[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _TrackRow(
                                      trackId: track.id,
                                      currentTrackId: currentTrackId,
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
                                      onLongPress: () =>
                                          showTrackActionsSheet(context, track),
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

class _AlbumHero extends StatelessWidget {
  const _AlbumHero({required this.album, required this.tracksCount});

  final MusicAlbum? album;
  final int tracksCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          final meta = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaPill(label: '专辑详情'),
                  _MetaPill(
                    label:
                        '${tracksCount == 0 ? (album?.trackCount ?? 0) : tracksCount} 首',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                album?.title ?? '专辑详情',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _AlbumArtistLine(album: album),
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
                            tracks: context.read<AlbumCubit>().state.tracks,
                            startIndex: 0,
                          ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('播放专辑'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/library'),
                    icon: const Icon(Icons.library_music_rounded),
                    label: const Text('返回媒体库'),
                  ),
                ],
              ),
            ],
          );

          final cover = DecoratedBox(
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
                imageUrl: album?.artworkUrl ?? '',
                size: isWide ? 250 : 210,
                borderRadius: 24,
              ),
            ),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: cover),
                const SizedBox(height: 20),
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
          borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: widget.artworkUrl,
                    size: 56,
                    borderRadius: 18,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
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

/// 专辑 hero 区的副标题：艺术家名 · 年份。艺术家名在有 artistId 时可点击。
class _AlbumArtistLine extends StatelessWidget {
  const _AlbumArtistLine({required this.album});

  final MusicAlbum? album;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant);

    if (album == null) {
      return Text('正在从 Emby 加载专辑曲目。', style: textStyle);
    }

    final year = album!.year?.toString() ?? '未知年份';
    final artistId = album!.artistId;
    final artistName = album!.artistName.isEmpty ? '未知艺术家' : album!.artistName;

    if (artistId == null || artistId.isEmpty) {
      return Text('$artistName · $year', style: textStyle);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => context.push('/artist/$artistId'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              artistName,
              style: textStyle?.copyWith(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.primary.withValues(alpha: 0.48),
              ),
            ),
          ),
        ),
        Text(' · $year', style: textStyle),
      ],
    );
  }
}

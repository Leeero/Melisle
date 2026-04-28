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
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
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
                      padding: AppPageLayout.sectionPadding(
                        context,
                        top: 10,
                        bottom: 18,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _AlbumHero(
                          album: album,
                          tracksCount: state.tracks.length,
                        ),
                      ),
                    ),
                    switch (state.status) {
                      AlbumStatus.loading => const AppSliverStateView.loading(),
                      AlbumStatus.failure => AppSliverStateView.message(
                        message: state.errorMessage ?? '加载专辑失败',
                      ),
                      _ => SliverPadding(
                        padding: AppPageLayout.sectionPadding(
                          context,
                          bottom: 28,
                        ),
                        sliver: state.tracks.isEmpty
                            ? const AppSliverStateView.message(
                                message: '当前专辑还没有曲目。',
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
              imageUrl: album?.artworkUrl ?? '',
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
                const MetaPill(label: '专辑详情', size: MetaPillSize.compact),
                MetaPill(
                  label:
                      '${tracksCount == 0 ? (album?.trackCount ?? 0) : tracksCount} 首',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              album?.title ?? '专辑详情',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
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
      },
    );
  }
}

// Phase 4: Track row with hover shadow

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

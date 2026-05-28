import 'package:cross_platform_music_player/application/usecases/fetch_album_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
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
        final isWide = AppBreakpoints.usesWideContent(context);
        final bottomInset = _contentBottomInset(
          context,
          currentTrackId != null,
        );

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
                        top: isWide ? 4 : 10,
                        bottom: isWide ? 18 : 10,
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
                          bottom: bottomInset,
                        ),
                        sliver: state.tracks.isEmpty
                            ? const AppSliverStateView.message(
                                message: '当前专辑还没有曲目。',
                              )
                            : isWide
                            ? SliverToBoxAdapter(
                                child: MusicTrackTable(
                                  tracks: state.tracks,
                                  currentTrackId: currentTrackId,
                                  showActionBar: false,
                                  onTrackTap: (index, _) =>
                                      _playAlbumFromIndex(context, index),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final track = state.tracks[index];
                                  final trackTile = MusicTrackTile.row(
                                    isCurrent: track.id == currentTrackId,
                                    artworkUrl: track.artworkUrl,
                                    title: track.title,
                                    subtitle:
                                        '${track.artistName} · ${track.albumTitle}',
                                    onTap: () =>
                                        _playAlbumFromIndex(context, index),
                                    onLongPress: () =>
                                        showTrackActionsSheet(context, track),
                                  );

                                  return _AlbumTrackRow(
                                    isFirst: index == 0,
                                    isLast: index == state.tracks.length - 1,
                                    child: trackTile,
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
    final title = album?.title.trim();
    final displayTitle = title == null || title.isEmpty ? '专辑详情' : title;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.usesWideContentWidth(
          constraints.maxWidth,
        );

        return AppDetailHeroFrame(
          padding: isWide
              ? const EdgeInsets.all(22)
              : const EdgeInsets.fromLTRB(0, 10, 0, 4),
          compactGap: 18,
          spacing: 28,
          coverBuilder: (context, isWide) {
            return _AlbumHeroArtwork(
              imageUrl: album?.artworkUrl ?? '',
              size: isWide ? 220 : 128,
              semanticLabel: '《$displayTitle》封面',
            );
          },
          contentBuilder: (context, isWide) {
            return _AlbumHeroSummary(
              album: album,
              tracksCount: tracksCount,
              isWide: isWide,
              displayTitle: displayTitle,
            );
          },
        );
      },
    );
  }
}

class _AlbumHeroSummary extends StatelessWidget {
  const _AlbumHeroSummary({
    required this.album,
    required this.tracksCount,
    required this.isWide,
    required this.displayTitle,
  });

  final MusicAlbum? album;
  final int tracksCount;
  final bool isWide;
  final String displayTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = isWide
        ? theme.textTheme.headlineMedium
        : theme.textTheme.headlineSmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const MetaPill(label: '专辑', size: MetaPillSize.compact),
            MetaPill(
              label: '${_trackCountLabel(album, tracksCount)} 首',
              size: MetaPillSize.compact,
            ),
          ],
        ),
        SizedBox(height: isWide ? 16 : 14),
        Text(
          displayTitle,
          maxLines: isWide ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _AlbumArtistLine(album: album),
        SizedBox(height: isWide ? 22 : 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            PlayAllButton(
              variant: isWide
                  ? PlayAllButtonVariant.primary
                  : PlayAllButtonVariant.compact,
              onPressed: tracksCount == 0
                  ? null
                  : () => PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: context.read<AlbumCubit>().state.tracks,
                      startIndex: 0,
                    ),
            ),
            if (isWide)
              AppActionButton(
                onPressed: () => context.go('/library'),
                icon: Icons.library_music_rounded,
                label: '返回媒体库',
              ),
          ],
        ),
      ],
    );
  }
}

class _AlbumHeroArtwork extends StatelessWidget {
  const _AlbumHeroArtwork({
    required this.imageUrl,
    required this.size,
    required this.semanticLabel,
  });

  final String imageUrl;
  final double size;
  final String semanticLabel;

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
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

Future<void> _playAlbumFromIndex(BuildContext context, int startIndex) async {
  final tracks = context.read<AlbumCubit>().state.tracks;
  if (tracks.isEmpty) return;
  final safeIndex = startIndex.clamp(0, tracks.length - 1).toInt();
  await PlayerNavigation.playTracksAndOpenPlayer(
    context,
    tracks: tracks,
    startIndex: safeIndex,
  );
}

int _trackCountLabel(MusicAlbum? album, int tracksCount) {
  return tracksCount == 0 ? (album?.trackCount ?? 0) : tracksCount;
}

double _contentBottomInset(BuildContext context, bool hasMiniPlayer) {
  if (AppBreakpoints.usesWideContent(context)) {
    return 28;
  }

  return hasMiniPlayer ? 168 : 96;
}

class _AlbumTrackRow extends StatelessWidget {
  const _AlbumTrackRow({
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
    const radius = 14.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(radius) : Radius.zero,
          bottom: isLast ? const Radius.circular(radius) : Radius.zero,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          isFirst ? 12 : 0,
          12,
          isLast ? 18 : 12,
        ),
        child: child,
      ),
    );
  }
}

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
      return Text('正在加载专辑曲目', textAlign: TextAlign.start, style: textStyle);
    }

    final year = album!.year?.toString() ?? '未知年份';
    final artistId = album!.artistId;
    final artistName = album!.artistName.isEmpty ? '未知艺术家' : album!.artistName;

    if (artistId == null || artistId.isEmpty) {
      return Text(
        '$artistName · $year',
        textAlign: TextAlign.start,
        style: textStyle,
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/artist/$artistId'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Text(
                  artistName,
                  style: textStyle?.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colorScheme.primary.withValues(
                      alpha: 0.48,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(' · $year', style: textStyle),
      ],
    );
  }
}

import 'package:cross_platform_music_player/application/usecases/fetch_album_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/album/album_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
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
      child: _AlbumDetailView(albumId: albumId, album: album),
    );
  }
}

class _AlbumDetailView extends StatelessWidget {
  const _AlbumDetailView({required this.albumId, required this.album});

  final String albumId;
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
          body: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    if (!isWide)
                      SliverPadding(
                        padding: AppPageLayout.sectionPadding(
                          context,
                          top: 0,
                          bottom: 0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _AlbumMobileToolbar(
                            onBack: () => _goBackToLibrary(context),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: AppPageLayout.sectionPadding(
                        context,
                        top: isWide ? 4 : 2,
                        bottom: isWide ? 18 : 10,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _AlbumHero(
                          album: album,
                          tracksCount: state.tracks.length,
                          totalDuration: _totalDuration(state.tracks),
                          isLoading: state.status == AlbumStatus.loading,
                        ),
                      ),
                    ),
                    switch (state.status) {
                      AlbumStatus.loading => const AppSliverStateView.loading(),
                      AlbumStatus.failure => AppSliverStateView.message(
                        message: state.errorMessage ?? '加载专辑失败',
                        action: OutlinedButton.icon(
                          onPressed: () =>
                              context.read<AlbumCubit>().load(albumId),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('重试'),
                        ),
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
                                  return _AlbumMobileTrackRow(
                                    index: index,
                                    track: track,
                                    isCurrent: track.id == currentTrackId,
                                    onPlay: () =>
                                        _playAlbumFromIndex(context, index),
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
  const _AlbumHero({
    required this.album,
    required this.tracksCount,
    required this.totalDuration,
    required this.isLoading,
  });

  final MusicAlbum? album;
  final int tracksCount;
  final Duration totalDuration;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final displayTitle = album == null
        ? '专辑详情'
        : MediaDisplayText.albumTitle(album!.title);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.usesWideContentWidth(
          constraints.maxWidth,
        );

        return AppDetailHeroFrame(
          padding: isWide
              ? const EdgeInsets.only(bottom: 24)
              : const EdgeInsets.fromLTRB(0, 16, 0, 24),
          compactGap: 16,
          spacing: 24,
          coverBuilder: (context, isWide) {
            return _AlbumHeroArtwork(
              imageUrl: album?.artworkUrl ?? '',
              size: isWide ? 240 : 200,
              semanticLabel: '《$displayTitle》封面',
            );
          },
          contentBuilder: (context, isWide) {
            return _AlbumHeroSummary(
              album: album,
              tracksCount: tracksCount,
              totalDuration: totalDuration,
              isLoading: isLoading,
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
    required this.totalDuration,
    required this.isLoading,
  });

  final MusicAlbum? album;
  final int tracksCount;
  final bool isWide;
  final String displayTitle;
  final Duration totalDuration;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = isWide
        ? theme.textTheme.headlineMedium
        : theme.textTheme.headlineSmall;
    final horizontalAlignment = isWide
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    final textAlign = isWide ? TextAlign.start : TextAlign.center;

    return Column(
      crossAxisAlignment: horizontalAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWide) ...[
          Text(
            '专辑',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          displayTitle,
          maxLines: isWide ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: titleStyle?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        _AlbumArtistLine(album: album, centered: !isWide),
        const SizedBox(height: 6),
        _AlbumMetaLine(
          album: album,
          count: _trackCountLabel(album, tracksCount),
          duration: totalDuration,
          centered: !isWide,
        ),
        SizedBox(height: isWide ? 24 : 20),
        Wrap(
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            PlayAllButton(
              variant: isWide
                  ? PlayAllButtonVariant.primary
                  : PlayAllButtonVariant.compact,
              isLoading: isLoading,
              onPressed: isLoading || tracksCount == 0
                  ? null
                  : () => PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: context.read<AlbumCubit>().state.tracks,
                      startIndex: 0,
                    ),
              onShufflePressed: isLoading || tracksCount == 0
                  ? null
                  : () => PlayerNavigation.shuffleTracksAndOpenPlayer(
                      context,
                      tracks: context.read<AlbumCubit>().state.tracks,
                    ),
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
            color: colorScheme.scrim.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: CachedArtwork(
        imageUrl: imageUrl,
        size: size,
        borderRadius: AppRadiusTokens.coverDetail,
        semanticLabel: semanticLabel,
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

void _goBackToLibrary(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).maybePop();
    return;
  }
  context.go('/library');
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

Duration _totalDuration(List<MusicTrack> tracks) {
  return tracks.fold(Duration.zero, (total, track) => total + track.duration);
}

class _AlbumMobileToolbar extends StatelessWidget {
  const _AlbumMobileToolbar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            tooltip: '返回',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Expanded(
            child: Text(
              '专辑详情',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _AlbumMetaLine extends StatelessWidget {
  const _AlbumMetaLine({
    required this.album,
    required this.count,
    required this.duration,
    required this.centered,
  });

  final MusicAlbum? album;
  final int count;
  final Duration duration;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final year = MediaDisplayText.year(album?.year);
    final totalMinutes = duration.inMinutes;
    final labels = <String>[year, '$count 首歌曲'];
    if (totalMinutes > 0) labels.add('$totalMinutes 分钟');
    return Text(
      labels.join(' · '),
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _AlbumMobileTrackRow extends StatelessWidget {
  const _AlbumMobileTrackRow({
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.onPlay,
  });

  final int index;
  final MusicTrack track;
  final bool isCurrent;
  final Future<void> Function() onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = MediaDisplayText.trackTitle(track.title);
    return Semantics(
      label: '播放《$title》',
      button: true,
      selected: isCurrent,
      child: Material(
        color: isCurrent ? Theme.of(context).selectedWash : Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          onLongPress: () => showTrackActionsSheet(context, track),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: isCurrent
                        ? Icon(
                            Icons.graphic_eq_rounded,
                            color: colors.primary,
                            size: 20,
                          )
                        : Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCurrent ? colors.primary : colors.onSurface,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '更多操作',
                  onPressed: () => showTrackActionsSheet(context, track),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isCurrent ? colors.primary : colors.onSurfaceVariant,
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

class _AlbumArtistLine extends StatelessWidget {
  const _AlbumArtistLine({required this.album, required this.centered});

  final MusicAlbum? album;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant);

    if (album == null) {
      return Text(
        '正在加载专辑曲目',
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: textStyle,
      );
    }

    final year = MediaDisplayText.year(album!.year);
    final artistId = album!.artistId;
    final artistName = MediaDisplayText.artistName(album!.artistName);

    if (artistId == null || artistId.isEmpty) {
      return Text(
        '$artistName · $year',
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: textStyle,
      );
    }

    return Wrap(
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/artist/$artistId'),
              mouseCursor: SystemMouseCursors.click,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Text(
                  artistName,
                  style: textStyle?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
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

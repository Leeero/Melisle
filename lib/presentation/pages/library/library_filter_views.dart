import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_artist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_playlist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef LibraryTrackItemBuilder =
    Widget Function(
      BuildContext context,
      MusicTrack track,
      int index,
      bool isCurrent,
    );

enum LibraryAlbumGridDensity { compact, comfortable }

class LibraryTrackSliver extends StatelessWidget {
  const LibraryTrackSliver({
    super.key,
    required this.state,
    required this.horizontalPadding,
    required this.currentTrackId,
    required this.onTrackTap,
    required this.desktopTrailingBuilder,
    required this.mobileItemBuilder,
    this.onPlayAll,
    this.onShuffleAll,
    this.density = MusicTrackTableDensity.comfortable,
  });

  final LibraryState state;
  final double horizontalPadding;
  final String? currentTrackId;
  final ValueChanged<int> onTrackTap;
  final MusicTrackTableTrailingBuilder desktopTrailingBuilder;
  final LibraryTrackItemBuilder mobileItemBuilder;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffleAll;
  final MusicTrackTableDensity density;

  @override
  Widget build(BuildContext context) {
    if (state.tracks.isEmpty) {
      return const AppSliverStateView.message(message: '当前还没有歌曲。');
    }
    final wide = AppBreakpoints.usesWideContent(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppPageLayout.contentBottomInset,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          if (wide)
            SliverToBoxAdapter(
              child: MusicTrackTable(
                tracks: state.tracks,
                currentTrackId: currentTrackId,
                showActionBar: false,
                libraryStyle: true,
                onTrackTap: (index, _) => onTrackTap(index),
                trailingBuilder: desktopTrailingBuilder,
                density: density,
              ),
            )
          else ...[
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final track = state.tracks[index];
                return mobileItemBuilder(
                  context,
                  track,
                  index,
                  track.id == currentTrackId,
                );
              }, childCount: state.tracks.length),
            ),
          ],
        ],
      ),
    );
  }
}

class LibraryAlbumSliver extends StatelessWidget {
  const LibraryAlbumSliver({
    super.key,
    required this.state,
    required this.horizontalPadding,
    this.density = LibraryAlbumGridDensity.comfortable,
  });

  final LibraryState state;
  final double horizontalPadding;
  final LibraryAlbumGridDensity density;

  @override
  Widget build(BuildContext context) {
    if (state.albums.isEmpty) {
      return const AppSliverStateView.message(message: '当前还没有专辑。');
    }
    final compact = AppBreakpoints.isCompact(context);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final mainAxisSpacing = compact ? 18.0 : 28.0;
        final crossAxisSpacing = compact ? 12.0 : 20.0;
        final availableWidth =
            constraints.crossAxisExtent - horizontalPadding * 2;
        final crossAxisCount = libraryAlbumGridCount(
          availableWidth,
          compactViewport: compact,
          density: density,
          gap: crossAxisSpacing,
        );
        final artworkWidth =
            (availableWidth - crossAxisSpacing * (crossAxisCount - 1)) /
            crossAxisCount;
        final metadataExtent = compact
            ? 62.0
            : density == LibraryAlbumGridDensity.compact
            ? 68.0
            : 78.0;

        return _LibraryGridSliver(
          horizontalPadding: horizontalPadding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisExtent: artworkWidth + metadataExtent,
          ),
          childCount: state.albums.length,
          itemBuilder: (context, index) {
            final album = state.albums[index];
            return MusicAlbumGridCard(
              album: album,
              onTap: () => context.push('/album/${album.id}', extra: album),
              artworkRadius: compact
                  ? AppRadiusTokens.mobileMd
                  : AppRadiusTokens.coverGrid,
              compact: compact,
              dense: density == LibraryAlbumGridDensity.compact,
            );
          },
        );
      },
    );
  }
}

int libraryAlbumGridCount(
  double availableWidth, {
  required bool compactViewport,
  required LibraryAlbumGridDensity density,
  required double gap,
}) {
  final minTileWidth = compactViewport
      ? 148.0
      : density == LibraryAlbumGridDensity.compact
      ? 148.0
      : 190.0;
  final maxColumns = compactViewport
      ? 2
      : density == LibraryAlbumGridDensity.compact
      ? 7
      : 6;
  return ((availableWidth + gap) / (minTileWidth + gap)).floor().clamp(
    2,
    maxColumns,
  );
}

class LibraryArtistSliver extends StatelessWidget {
  const LibraryArtistSliver({
    super.key,
    required this.state,
    required this.horizontalPadding,
  });

  final LibraryState state;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (state.artists.isEmpty && state.genres.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.only(bottom: AppPageLayout.contentBottomInset),
        sliver: AppSliverStateView.message(message: '当前还没有歌手。'),
      );
    }
    final compact = AppBreakpoints.isCompact(context);
    final artists = sortLibraryArtists(state.artists);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppPageLayout.contentBottomInset,
      ),
      sliver: compact
          ? SliverList.builder(
              itemCount: state.artists.length,
              itemBuilder: (context, index) {
                final artist = state.artists[index];
                return _MobileArtistRow(
                  artist: artist,
                  onTap: () =>
                      context.push('/artist/${artist.id}', extra: artist),
                );
              },
            )
          : SliverLayoutBuilder(
              builder: (context, constraints) {
                return SliverGrid.builder(
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return MusicArtistGridCard(
                      artist: artist,
                      onTap: () =>
                          context.push('/artist/${artist.id}', extra: artist),
                    );
                  },
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: libraryArtistGridCount(
                      constraints.crossAxisExtent,
                    ),
                    mainAxisSpacing: libraryArtistGridMainAxisSpacing,
                    crossAxisSpacing: libraryArtistGridCrossAxisSpacing,
                    mainAxisExtent: libraryArtistGridMainAxisExtent,
                  ),
                );
              },
            ),
    );
  }
}

const double libraryArtistGridMainAxisSpacing = 28;
const double libraryArtistGridCrossAxisSpacing = 20;
const double libraryArtistGridMainAxisExtent = 236;

int libraryArtistGridCount(double availableWidth) {
  return ((availableWidth + libraryArtistGridCrossAxisSpacing) /
          (146 + libraryArtistGridCrossAxisSpacing))
      .floor()
      .clamp(3, 6);
}

List<MusicArtist> sortLibraryArtists(List<MusicArtist> artists) =>
    [...artists]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

class _MobileArtistRow extends StatelessWidget {
  const _MobileArtistRow({required this.artist, required this.onTap});

  final MusicArtist artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = MediaDisplayText.artistName(artist.name);
    return Semantics(
      button: true,
      label: '打开歌手《$name》',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
              width: 0.5,
            ),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.mobileSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacingTokens.listTileVPadding,
              ),
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: artist.artworkUrl,
                    size: 64,
                    borderRadius: AppRadiusTokens.full,
                    semanticLabel: '$name 头像',
                    placeholderBuilder: (_) =>
                        const MusicArtistArtworkPlaceholder(size: 64),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MediaDisplayText.artistItemCount(artist),
                          maxLines: 1,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox.square(
                    dimension: 44,
                    child: Icon(Icons.chevron_right_rounded),
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

class LibraryPlaylistSliver extends StatelessWidget {
  const LibraryPlaylistSliver({
    super.key,
    required this.state,
    required this.horizontalPadding,
  });

  final LibraryState state;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (state.playlists.isEmpty) {
      return const AppSliverStateView.message(message: '当前还没有歌单。');
    }
    final width = MediaQuery.sizeOf(context).width;
    final compact = AppBreakpoints.isCompact(context);
    return _LibraryGridSliver(
      horizontalPadding: horizontalPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: libraryGridCount(width),
        mainAxisSpacing: compact ? 14 : 22,
        crossAxisSpacing: compact ? 12 : 18,
        childAspectRatio: compact ? 0.80 : 0.72,
      ),
      childCount: state.playlists.length,
      itemBuilder: (context, index) {
        final playlist = state.playlists[index];
        return MusicPlaylistGridCard(
          playlist: playlist,
          onTap: () =>
              context.push('/playlists/${playlist.id}', extra: playlist),
          artworkRadius: compact
              ? AppRadiusTokens.mobileMd
              : AppRadiusTokens.coverGrid,
          compact: compact,
        );
      },
    );
  }
}

class _LibraryGridSliver extends StatelessWidget {
  const _LibraryGridSliver({
    required this.horizontalPadding,
    required this.gridDelegate,
    required this.childCount,
    required this.itemBuilder,
  });

  final double horizontalPadding;
  final SliverGridDelegate gridDelegate;
  final int childCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppPageLayout.contentBottomInset,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: childCount,
            ),
            gridDelegate: gridDelegate,
          ),
        ],
      ),
    );
  }
}

int libraryGridCount(double width) {
  if (AppBreakpoints.isCompactWidth(width)) {
    const minTileWidth = 118.0;
    const gap = 12.0;
    final availableWidth = width - AppSpacingTokens.pageHorizontalCompact * 2;
    return ((availableWidth + gap) / (minTileWidth + gap)).floor().clamp(2, 4);
  }
  return AppBreakpoints.adaptiveAlbumGridCount(width);
}

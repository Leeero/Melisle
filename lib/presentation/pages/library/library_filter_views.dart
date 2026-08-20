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

class LibraryTrackSliver extends StatelessWidget {
  const LibraryTrackSliver({
    super.key,
    required this.state,
    required this.horizontalPadding,
    required this.currentTrackId,
    required this.onPlayAll,
    required this.onShuffleAll,
    required this.onTrackTap,
    required this.desktopTrailingBuilder,
    required this.mobileItemBuilder,
    this.desktopToolbarTrailing,
  });

  final LibraryState state;
  final double horizontalPadding;
  final String? currentTrackId;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffleAll;
  final ValueChanged<int> onTrackTap;
  final MusicTrackTableTrailingBuilder desktopTrailingBuilder;
  final LibraryTrackItemBuilder mobileItemBuilder;
  final Widget? desktopToolbarTrailing;

  @override
  Widget build(BuildContext context) {
    if (state.tracks.isEmpty) {
      return const AppSliverStateView.message(message: '当前还没有歌曲。');
    }
    final wide = AppBreakpoints.usesWideContent(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverMainAxisGroup(
        slivers: [
          if (wide)
            SliverToBoxAdapter(
              child: MusicTrackTable(
                tracks: state.tracks,
                currentTrackId: currentTrackId,
                showActionBar: true,
                libraryStyle: true,
                trackCountLabel:
                    '${state.totalTrackCount ?? state.tracks.length} 首',
                onTrackTap: (index, _) => onTrackTap(index),
                onPlayAll: onPlayAll,
                onShuffleAll: onShuffleAll,
                trailingBuilder: desktopTrailingBuilder,
                actionBarTrailing: desktopToolbarTrailing,
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
  });

  final LibraryState state;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (state.albums.isEmpty) {
      return const AppSliverStateView.message(message: '当前还没有专辑。');
    }
    final width = MediaQuery.sizeOf(context).width;
    final compact = AppBreakpoints.isCompact(context);
    return _LibraryGridSliver(
      horizontalPadding: horizontalPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: libraryGridCount(width),
        mainAxisSpacing: compact ? 14 : 18,
        crossAxisSpacing: compact ? 12 : 18,
        childAspectRatio: compact ? 0.80 : 0.72,
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
        );
      },
    );
  }
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
        padding: EdgeInsets.only(bottom: 18),
        sliver: AppSliverStateView.message(message: '当前还没有艺术家。'),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    final compact = AppBreakpoints.isCompact(context);
    final desktop = AppBreakpoints.usesDesktopToolbar(context);
    final artists = sortLibraryArtists(state.artists);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
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
          : SliverGrid.builder(
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
                crossAxisCount: libraryGridCount(width),
                mainAxisSpacing: desktop ? 56 : 24,
                crossAxisSpacing: desktop ? 48 : 32,
                mainAxisExtent: desktop ? 288 : 206,
              ),
            ),
    );
  }
}

List<MusicArtist> sortLibraryArtists(List<MusicArtist> artists) => [...artists]
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
      label: '打开艺术家《$name》',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadiusTokens.mobileSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacingTokens.listTileVPadding),
            child: Row(
              children: [
                CachedArtwork(
                  imageUrl: artist.artworkUrl,
                  size: 64,
                  borderRadius: AppRadiusTokens.full,
                  semanticLabel: '$name 头像',
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
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
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

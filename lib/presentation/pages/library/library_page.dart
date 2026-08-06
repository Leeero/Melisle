import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_favorite_tracks.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_scope_tabs.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/app_skeleton.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_artist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_playlist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, this.initialFilter = LibraryFilter.tracks});

  final LibraryFilter initialFilter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(initialFilter),
      create: (context) => LibraryCubit(
        FetchLibraryTracks(context.read<MusicRepository>()),
        FetchLibraryAlbums(context.read<MusicRepository>()),
        FetchLibraryArtists(context.read<MusicRepository>()),
        context.read<MusicRepository>(),
        initialFilter: initialFilter,
      )..load(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels >= threshold) {
      context.read<LibraryCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        return AppContentPage(
          header: _LibraryHeader(state: state),
          body: _buildBody(context, state, horizontalPadding, currentTrackId),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
    String? currentTrackId,
  ) {
    if (state.status == LibraryStatus.loading && state.isCurrentFilterEmpty) {
      return Padding(
        padding: AppPageLayout.pagePadding(context),
        child: Semantics(
          label: '正在加载歌曲',
          liveRegion: true,
          child: AppSkeleton.grid(count: 6),
        ),
      );
    }

    if (state.status == LibraryStatus.failure && state.isCurrentFilterEmpty) {
      return AppBodyStateView.message(
        message: state.errorMessage ?? '加载媒体库失败',
        action: FilledButton.icon(
          onPressed: () => context.read<LibraryCubit>().load(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重新加载'),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: CustomScrollView(
        key: ValueKey('filter-${state.currentFilter.index}'),
        controller: _scrollController,
        slivers: [
          switch (state.currentFilter) {
            LibraryFilter.tracks => _buildTrackSliver(
              context,
              state,
              horizontalPadding,
              currentTrackId,
            ),
            LibraryFilter.albums => _buildAlbumSliver(
              context,
              state,
              horizontalPadding,
            ),
            LibraryFilter.artists => _buildArtistSliver(
              context,
              state,
              horizontalPadding,
            ),
            LibraryFilter.playlists => _buildPlaylistSliver(
              context,
              state,
              horizontalPadding,
            ),
            LibraryFilter.favorites => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                18,
              ),
              sliver: const _LibraryFavoritesSliver(),
            ),
          },
          if (state.currentFilter != LibraryFilter.favorites)
            _buildFooterSliver(state),
        ],
      ),
    );
  }

  Widget _buildTrackSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
    String? currentTrackId,
  ) {
    if (state.tracks.isEmpty) {
      return const AppSliverStateView.message(message: '当前还没有歌曲。');
    }

    final isWide = AppBreakpoints.usesWideContent(context);

    if (isWide) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          18,
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: _LibrarySectionHeader(
                title: '歌曲',
                countLabel: _libraryTrackCountLabel(state),
                action: PlayAllButton(
                  onPressed: () => _playAllLibraryTracks(context, state),
                  onShufflePressed: () =>
                      _playAllLibraryTracks(context, state, shuffled: true),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MusicTrackTable(
                tracks: state.tracks,
                currentTrackId: currentTrackId,
                showActionBar: false,
                onTrackTap: (index, _) =>
                    PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: state.tracks,
                      startIndex: index,
                    ),
                onPlayAll: () => _playAllLibraryTracks(context, state),
                onShuffleAll: () =>
                    _playAllLibraryTracks(context, state, shuffled: true),
                trailingBuilder: (context, track, hovered) =>
                    hovered || track.isFavorite
                    ? _LibraryTrackFavoriteButton(track: track)
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _MobileLibraryTrackSectionHeader(
              countLabel: _libraryTrackSummaryCountLabel(state),
              onPlayAll: () => _playAllLibraryTracks(context, state),
              onShuffleAll: () =>
                  _playAllLibraryTracks(context, state, shuffled: true),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final track = state.tracks[index];
              return _MobileLibraryTrackRow(
                track: track,
                index: index,
                isCurrent: track.id == currentTrackId,
                onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                  context,
                  tracks: state.tracks,
                  startIndex: index,
                ),
                onMore: () => showTrackActionsSheet(context, track),
              );
            }, childCount: state.tracks.length),
          ),
        ],
      ),
    );
  }

  Future<void> _playAllLibraryTracks(
    BuildContext context,
    LibraryState state, {
    bool shuffled = false,
  }) {
    if (shuffled) {
      return PlayerNavigation.shuffleAllAndOpenPlayer(
        context,
        loadedTracks: state.tracks,
        allLoaded: !state.hasMore,
        fetchAll: () async {
          final result = await context.read<MusicRepository>().fetchTracks(
            limit: 500,
            startIndex: 0,
          );
          return result.items;
        },
      );
    }

    return PlayerNavigation.playAllAndOpenPlayer(
      context,
      loadedTracks: state.tracks,
      allLoaded: !state.hasMore,
      fetchAll: () async {
        final result = await context.read<MusicRepository>().fetchTracks(
          limit: 500,
          startIndex: 0,
        );
        return result.items;
      },
    );
  }

  Widget _buildAlbumSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
  ) {
    if (state.albums.isEmpty) {
      return const AppSliverStateView.message(message: '当前还没有专辑。');
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = AppBreakpoints.isCompact(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _LibrarySectionHeader(
              title: '专辑',
              countLabel: '${state.albums.length} 张',
            ),
          ),
          SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final album = state.albums[index];
              return MusicAlbumGridCard(
                album: album,
                onTap: () => context.push('/album/${album.id}', extra: album),
                artworkRadius: isCompact
                    ? AppRadiusTokens.mobileMd
                    : AppRadiusTokens.coverGrid,
                compact: isCompact,
              );
            }, childCount: state.albums.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _albumGridCount(screenWidth),
              mainAxisSpacing: isCompact ? 14 : 18,
              crossAxisSpacing: isCompact ? 12 : 18,
              childAspectRatio: isCompact ? 0.80 : 0.72,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
  ) {
    if (state.artists.isEmpty && state.genres.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.only(bottom: 18),
        sliver: AppSliverStateView.message(message: '当前还没有艺术家。'),
      );
    }

    final isWide = AppBreakpoints.usesWideContent(context);
    final isCompact = AppBreakpoints.isCompact(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _LibrarySectionHeader(
              title: '艺术家',
              countLabel: '${state.artists.length} 位',
            ),
          ),
          if (isWide && state.genres.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.genres.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _GenreChip(
                          label: '全部',
                          selected: state.selectedGenreId == null,
                          onTap: () =>
                              context.read<LibraryCubit>().changeGenre(null),
                        );
                      }
                      final genre = state.genres[index - 1];
                      return _GenreChip(
                        label: genre.name,
                        selected: state.selectedGenreId == genre.id,
                        onTap: () =>
                            context.read<LibraryCubit>().changeGenre(genre.id),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (state.artists.isEmpty)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: Center(child: Text('当前还没有艺术家。')),
              ),
            )
          else
            SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final artist = state.artists[index];
                return MusicArtistGridCard(
                  artist: artist,
                  onTap: () =>
                      context.push('/artist/${artist.id}', extra: artist),
                  compact: isCompact,
                );
              }, childCount: state.artists.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _artistGridCount(
                  MediaQuery.sizeOf(context).width,
                ),
                mainAxisSpacing: isWide ? 18 : 14,
                crossAxisSpacing: isWide ? 18 : 12,
                childAspectRatio: isWide ? 0.7 : 0.96,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaylistSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
  ) {
    if (state.playlists.isEmpty) {
      return const AppSliverStateView.message(message: '当前还没有歌单。');
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = AppBreakpoints.isCompact(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _LibrarySectionHeader(
              title: '歌单',
              countLabel: '${state.playlists.length} 个',
            ),
          ),
          SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final playlist = state.playlists[index];
              return MusicPlaylistGridCard(
                playlist: playlist,
                onTap: () =>
                    context.push('/playlists/${playlist.id}', extra: playlist),
                artworkRadius: isCompact
                    ? AppRadiusTokens.mobileMd
                    : AppRadiusTokens.coverGrid,
                compact: isCompact,
              );
            }, childCount: state.playlists.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _albumGridCount(screenWidth),
              mainAxisSpacing: isCompact ? 14 : 22,
              crossAxisSpacing: isCompact ? 12 : 18,
              childAspectRatio: isCompact ? 0.80 : 0.78,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSliver(LibraryState state) {
    if (state.isCurrentFilterEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // loadMore 失败的 inline 提示
    if (state.errorMessage != null &&
        !state.isLoadingMore &&
        state.status == LibraryStatus.success) {
      final colorScheme = Theme.of(context).colorScheme;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Center(
            child: Text(
              state.errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
        ),
      );
    }

    if (state.isLoadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (!state.hasMore) {
      final colorScheme = Theme.of(context).colorScheme;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
          child: Center(
            child: Text(
              '— · — · —',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox(height: 14));
  }

  int _albumGridCount(double width) {
    if (AppBreakpoints.isCompactWidth(width)) {
      return _mobileLibraryGridCount(width);
    }
    return AppBreakpoints.adaptiveAlbumGridCount(width);
  }

  int _artistGridCount(double width) {
    if (AppBreakpoints.isCompactWidth(width)) {
      return _mobileLibraryGridCount(width);
    }
    if (width >= 1200) return 8;
    if (width >= 900) return 6;
    if (width >= 600) return 4;
    return 3;
  }

  int _mobileLibraryGridCount(double width) {
    const minTileWidth = 118.0;
    const gap = 12.0;
    const horizontalPadding = AppSpacingTokens.pageHorizontalCompact * 2;
    final availableWidth = width - horizontalPadding;
    final count = ((availableWidth + gap) / (minTileWidth + gap)).floor();
    return count.clamp(2, 4).toInt();
  }
}

String _librarySummaryLabel(LibraryState state) {
  final trackCount = state.totalTrackCount ?? state.tracks.length;
  final parts = <String>[
    if (trackCount > 0) '$trackCount 首',
    if (state.albums.isNotEmpty) '${state.albums.length} 专辑',
    if (state.artists.isNotEmpty) '${state.artists.length} 艺术家',
    if (state.playlists.isNotEmpty) '${state.playlists.length} 歌单',
  ];

  if (state.status == LibraryStatus.loading && parts.isEmpty) {
    return '正在整理你的媒体库。';
  }
  return parts.isEmpty ? '歌曲、专辑、艺术家和歌单会按音乐源实时展示。' : parts.join(' · ');
}

String _libraryTrackCountLabel(LibraryState state) {
  final totalTrackCount = state.totalTrackCount;
  if (totalTrackCount == null) {
    return '${state.currentFilterCount} 首';
  }
  return '${state.currentFilterCount} / $totalTrackCount 首';
}

String _libraryTrackSummaryCountLabel(LibraryState state) {
  return '${state.totalTrackCount ?? state.currentFilterCount} 首';
}

String _formatTrackDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _LibrarySectionHeader extends StatelessWidget {
  const _LibrarySectionHeader({
    required this.title,
    required this.countLabel,
    this.action,
  });

  final String title;
  final String countLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppSectionTitleRow(
      title: title,
      badge: MetaPill(label: countLabel, size: MetaPillSize.compact),
      action: action,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
    );
  }
}

class _MobileTrackActionBar extends StatelessWidget {
  const _MobileTrackActionBar({
    this.trackCount,
    required this.onPlayAll,
    required this.onShuffleAll,
  });

  final int? trackCount;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffleAll;

  @override
  Widget build(BuildContext context) {
    final trackCount = this.trackCount;
    final countLabel = trackCount == null ? null : '$trackCount 首';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _MobileLibraryPlayAllButton(
          onPressed: onPlayAll,
          onShufflePressed: onShuffleAll,
          countLabel: countLabel,
        ),
      ),
    );
  }
}

class _MobileLibraryTrackSectionHeader extends StatelessWidget {
  const _MobileLibraryTrackSectionHeader({
    required this.countLabel,
    required this.onPlayAll,
    required this.onShuffleAll,
  });

  final String countLabel;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffleAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: [
                Text(
                  '歌曲',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  countLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _MobileLibraryPlayAllInlineButton(
            onPressed: onPlayAll,
            onShufflePressed: onShuffleAll,
          ),
        ],
      ),
    );
  }
}

class _MobileLibraryPlayAllInlineButton extends StatefulWidget {
  const _MobileLibraryPlayAllInlineButton({
    required this.onPressed,
    required this.onShufflePressed,
  });

  final VoidCallback onPressed;
  final VoidCallback onShufflePressed;

  @override
  State<_MobileLibraryPlayAllInlineButton> createState() =>
      _MobileLibraryPlayAllInlineButtonState();
}

class _MobileLibraryPlayAllInlineButtonState
    extends State<_MobileLibraryPlayAllInlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final playButton = Semantics(
      label: '播放全部歌曲',
      button: true,
      child: Tooltip(
        message: '播放全部',
        child: SizedBox(
          height: 44,
          child: Center(
            child: AnimatedScale(
              duration: AppMotion.micro,
              curve: AppMotion.enter,
              scale: _pressed ? 0.98 : 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadiusTokens.button),
                  onTap: widget.onPressed,
                  mouseCursor: SystemMouseCursors.click,
                  onHighlightChanged: (pressed) =>
                      setState(() => _pressed = pressed),
                  splashColor: colorScheme.primary.withValues(alpha: 0.08),
                  highlightColor: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: theme.brightness == Brightness.dark
                            ? 0.54
                            : 0.72,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppRadiusTokens.button,
                      ),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 34,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 17,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '播放全部',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        playButton,
        const SizedBox(width: 6),
        Tooltip(
          message: '随机播放',
          child: IconButton(
            onPressed: widget.onShufflePressed,
            icon: Icon(
              Icons.shuffle_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileLibraryPlayAllButton extends StatefulWidget {
  const _MobileLibraryPlayAllButton({
    required this.onPressed,
    required this.onShufflePressed,
    this.countLabel,
  });

  final VoidCallback onPressed;
  final VoidCallback onShufflePressed;
  final String? countLabel;

  @override
  State<_MobileLibraryPlayAllButton> createState() =>
      _MobileLibraryPlayAllButtonState();
}

class _MobileLibraryPlayAllButtonState
    extends State<_MobileLibraryPlayAllButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countLabel = widget.countLabel;

    final playButton = Semantics(
      label: '全部播放',
      button: true,
      child: Tooltip(
        message: '全部播放',
        child: AnimatedScale(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          scale: _pressed ? 0.98 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.button),
              onTap: widget.onPressed,
              mouseCursor: SystemMouseCursors.click,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              splashColor: colorScheme.onPrimary.withValues(alpha: 0.08),
              highlightColor: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.button),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      6,
                      countLabel == null ? 14 : 12,
                      6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.16,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 19,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '全部播放',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                        if (countLabel != null) ...[
                          const SizedBox(width: 9),
                          Container(
                            width: 1,
                            height: 14,
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.22,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            countLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.78,
                              ),
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        playButton,
        const SizedBox(width: 8),
        Tooltip(
          message: '随机播放',
          child: IconButton(
            onPressed: widget.onShufflePressed,
            style: AppActionButtonStyle.icon(
              context,
              tone: AppActionButtonTone.secondary,
            ),
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ),
      ],
    );
  }
}

class _LibraryTrackFavoriteButton extends StatelessWidget {
  const _LibraryTrackFavoriteButton({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        onPressed: () async {
          final cubit = context.read<LibraryCubit>();
          final isFavorite = track.isFavorite;
          try {
            await cubit.toggleTrackFavorite(track.id);
            if (!context.mounted) return;
            AppSnackBar.show(context, isFavorite ? '已取消收藏' : '已收藏歌曲');
          } catch (_) {
            if (!context.mounted) return;
            AppSnackBar.show(context, '操作失败，请重试');
          }
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            track.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            key: ValueKey(track.isFavorite),
            size: 18,
            color: track.isFavorite
                ? Colors.redAccent
                : colorScheme.onSurfaceVariant,
          ),
        ),
        padding: EdgeInsets.zero,
        tooltip: track.isFavorite ? '取消收藏' : '收藏',
        visualDensity: VisualDensity.standard,
        style: AppActionButtonStyle.icon(
          context,
          selected: track.isFavorite,
          iconSize: 18,
        ),
      ),
    );
  }
}

class _MobileLibraryTrackRow extends StatefulWidget {
  const _MobileLibraryTrackRow({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onMore,
  });

  final MusicTrack track;
  final int index;
  final bool isCurrent;
  final Future<void> Function() onTap;
  final VoidCallback onMore;

  @override
  State<_MobileLibraryTrackRow> createState() => _MobileLibraryTrackRowState();
}

class _MobileLibraryTrackRowState extends State<_MobileLibraryTrackRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = [
      widget.track.artistName,
      widget.track.albumTitle,
    ].where((item) => item.isNotEmpty).join(' · ');
    final selected = widget.isCurrent;

    return Semantics(
      label: '播放《${widget.track.title}》',
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: selected
                ? theme.selectedWash
                : _pressed
                ? theme.hoverWash
                : Colors.transparent,
            borderRadius: selected || _pressed
                ? BorderRadius.circular(AppRadiusTokens.mobileSm)
                : BorderRadius.zero,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.mobileSm),
              onTap: widget.onTap,
              mouseCursor: SystemMouseCursors.click,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              hoverColor: Colors.transparent,
              focusColor: colorScheme.primary.withValues(alpha: 0.08),
              splashColor: colorScheme.primary.withValues(alpha: 0.06),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${widget.index + 1}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.78,
                                ),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTrackDuration(widget.track.duration),
                      maxLines: 1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        onPressed: widget.onMore,
                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                        tooltip: '更多操作',
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        style: AppActionButtonStyle.icon(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.usesWideContent(context);
    final hasDesktopToolbar = AppBreakpoints.usesDesktopToolbar(context);
    final tabs = AppScopeTabs<LibraryFilter>(
      semanticLabel: '媒体库分类',
      variant: isWide
          ? AppScopeTabsVariant.underline
          : AppScopeTabsVariant.pill,
      selectedValue: state.currentFilter,
      onChanged: (filter) => context.read<LibraryCubit>().changeFilter(filter),
      fillWidth: !isWide,
      tabGap: isWide ? 34 : null,
      items: isWide
          ? const [
              AppScopeTabItem(value: LibraryFilter.tracks, label: '歌曲'),
              AppScopeTabItem(value: LibraryFilter.albums, label: '专辑'),
              AppScopeTabItem(value: LibraryFilter.artists, label: '艺术家'),
            ]
          : const [
              AppScopeTabItem(value: LibraryFilter.tracks, label: '歌曲'),
              AppScopeTabItem(value: LibraryFilter.albums, label: '专辑'),
              AppScopeTabItem(value: LibraryFilter.artists, label: '艺术家'),
              AppScopeTabItem(value: LibraryFilter.playlists, label: '歌单'),
            ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasDesktopToolbar) ...[
          AppPageHeader(
            title: '媒体库',
            description: _librarySummaryLabel(state),
            automaticImplyLeading: false,
            hideTitleOnCompactWithCenter: false,
          ),
          const SizedBox(height: 14),
        ],
        if (isWide) SizedBox(width: 420, child: tabs) else tabs,
      ],
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.85)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.25)
                  : colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryFavoritesSliver extends StatelessWidget {
  const _LibraryFavoritesSliver();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavoritesListCubit(
        FetchFavoriteTracks(context.read<MusicRepository>()),
        context.read<FavoritesCubit>(),
      )..load(),
      child: BlocBuilder<FavoritesListCubit, FavoritesListState>(
        builder: (context, state) {
          if (state.status == FavoritesListStatus.loading &&
              state.tracks.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (state.status == FavoritesListStatus.failure &&
              state.tracks.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    state.errorMessage ?? '加载收藏失败',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            );
          }

          final filteredTracks = state.tracks;

          if (filteredTracks.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    '还没有收藏歌曲，去媒体库挑几首喜欢的吧。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }

          final currentTrackId = context.select<PlayerCubit, String?>(
            (cubit) => cubit.state.currentTrack?.id,
          );

          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: _MobileTrackActionBar(
                  trackCount: filteredTracks.length,
                  onPlayAll: () => PlayerNavigation.playAllAndOpenPlayer(
                    context,
                    loadedTracks: filteredTracks,
                    allLoaded: !state.hasMore,
                    fetchAll: () async {
                      final cubit = context.read<FavoritesListCubit>();
                      final tracks = <MusicTrack>[...state.tracks];
                      while (cubit.state.hasMore) {
                        await cubit.loadMore();
                        final nextState = cubit.state;
                        tracks
                          ..clear()
                          ..addAll(nextState.tracks);
                      }
                      return tracks;
                    },
                  ),
                  onShuffleAll: () => PlayerNavigation.shuffleAllAndOpenPlayer(
                    context,
                    loadedTracks: filteredTracks,
                    allLoaded: !state.hasMore,
                    fetchAll: () async {
                      final cubit = context.read<FavoritesListCubit>();
                      final tracks = <MusicTrack>[...state.tracks];
                      while (cubit.state.hasMore) {
                        await cubit.loadMore();
                        final nextState = cubit.state;
                        tracks
                          ..clear()
                          ..addAll(nextState.tracks);
                      }
                      return tracks;
                    },
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final track = filteredTracks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MusicTrackTile.card(
                      isCurrent: track.id == currentTrackId,
                      artworkUrl: track.artworkUrl,
                      title: track.title,
                      subtitle: [
                        track.artistName,
                        track.albumTitle,
                      ].where((item) => item.isNotEmpty).join(' · '),
                      onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                        context,
                        tracks: filteredTracks,
                        startIndex: index,
                      ),
                    ),
                  );
                }, childCount: filteredTracks.length),
              ),
              _LibraryFavoritesFooter(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _LibraryFavoritesFooter extends StatelessWidget {
  const _LibraryFavoritesFooter({required this.state});

  final FavoritesListState state;

  @override
  Widget build(BuildContext context) {
    if (state.errorMessage != null &&
        !state.isLoadingMore &&
        state.status == FavoritesListStatus.failure) {
      final colorScheme = Theme.of(context).colorScheme;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Center(
            child: Text(
              state.errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
        ),
      );
    }

    if (state.hasMore && !state.isLoadingMore) {
      unawaited(context.read<FavoritesListCubit>().loadMore());
      return const SliverToBoxAdapter(child: SizedBox(height: 14));
    }

    if (state.isLoadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
        child: Center(
          child: Text(
            '— · — · —',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}

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
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_scope_tabs.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_artist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LibraryCubit(
        FetchLibraryTracks(context.read<MusicRepository>()),
        FetchLibraryAlbums(context.read<MusicRepository>()),
        FetchLibraryArtists(context.read<MusicRepository>()),
        context.read<MusicRepository>(),
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
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
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

    return BlocConsumer<LibraryCubit, LibraryState>(
      listener: (context, state) {
        if (_searchController.text == state.searchQuery) return;
        _searchController.value = TextEditingValue(
          text: state.searchQuery,
          selection: TextSelection.collapsed(offset: state.searchQuery.length),
        );
      },
      builder: (context, state) {
        return DefaultTabController(
          key: ValueKey(state.currentFilter.index),
          length: 4,
          initialIndex: state.currentFilter.index,
          child: AppContentPage(
            header: _LibraryHeader(state: state, controller: _searchController),
            body: _buildBody(context, state, horizontalPadding, currentTrackId),
          ),
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
    // 初始加载（所有列表都空时显示全屏加载）
    if (state.status == LibraryStatus.loading &&
        state.tracks.isEmpty &&
        state.albums.isEmpty &&
        state.artists.isEmpty) {
      return const AppBodyStateView.loading();
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
            LibraryFilter.favorites => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                18,
              ),
              sliver: _LibraryFavoritesSliver(searchQuery: state.searchQuery),
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
      return const AppSliverStateView.message(message: '当前没有匹配的歌曲。试试其他关键词吧。');
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
              child: MusicTrackTable(
                tracks: state.tracks,
                currentTrackId: currentTrackId,
                trackCountLabel: state.totalTrackCount != null
                    ? '${state.currentFilterCount} / ${state.totalTrackCount} 首'
                    : '${state.currentFilterCount} 首',
                onTrackTap: (index, _) =>
                    PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: state.tracks,
                      startIndex: index,
                    ),
                onPlayAll: () => _playAllLibraryTracks(context, state),
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
            child: _MobileTrackActionBar(
              trackCount: state.currentFilterCount,
              totalTrackCount: state.totalTrackCount,
              onPlayAll: () => _playAllLibraryTracks(context, state),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final track = state.tracks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MusicTrackTile.card(
                  isCurrent: track.id == currentTrackId,
                  artworkUrl: track.artworkUrl,
                  title: track.title,
                  subtitle: '${track.artistName} · ${track.albumTitle}',
                  onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                    context,
                    tracks: state.tracks,
                    startIndex: index,
                  ),
                ),
              );
            }, childCount: state.tracks.length),
          ),
        ],
      ),
    );
  }

  Future<void> _playAllLibraryTracks(BuildContext context, LibraryState state) {
    return PlayerNavigation.playAllAndOpenPlayer(
      context,
      loadedTracks: state.tracks,
      allLoaded: !state.hasMore,
      fetchAll: () async {
        final result = await context.read<MusicRepository>().fetchTracks(
          limit: 500,
          startIndex: 0,
          searchQuery: state.searchQuery.trim().isEmpty
              ? null
              : state.searchQuery.trim(),
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
      return const AppSliverStateView.message(message: '当前没有匹配的专辑。试试其他关键词吧。');
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 380;

    if (isNarrow) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          18,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final album = state.albums[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CachedArtwork(
                  imageUrl: album.artworkUrl,
                  size: 48,
                  borderRadius: 14,
                ),
                title: Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    album.artistName,
                    if (album.year != null) '${album.year}',
                    '${album.trackCount} 首',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.push('/album/${album.id}', extra: album),
              ),
            );
          }, childCount: state.albums.length),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final album = state.albums[index];
          return MusicAlbumGridCard(
            album: album,
            onTap: () => context.push('/album/${album.id}', extra: album),
          );
        }, childCount: state.albums.length),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _albumGridCount(MediaQuery.sizeOf(context).width),
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: 0.72,
        ),
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
        sliver: AppSliverStateView.message(message: '当前没有匹配的艺术家。试试其他关键词吧。'),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverMainAxisGroup(
        slivers: [
          // Genre 筛选器
          if (state.genres.isNotEmpty)
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
          // 艺术家列表
          if (state.artists.isEmpty)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: Center(child: Text('当前没有匹配的艺术家。')),
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
                );
              }, childCount: state.artists.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _artistGridCount(
                  MediaQuery.sizeOf(context).width,
                ),
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.7,
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
    return AppBreakpoints.adaptiveAlbumGridCount(width);
  }

  int _artistGridCount(double width) {
    if (width >= 1200) return 8;
    if (width >= 900) return 6;
    if (width >= 600) return 4;
    return 3;
  }
}

class _MobileTrackActionBar extends StatelessWidget {
  const _MobileTrackActionBar({
    required this.trackCount,
    this.totalTrackCount,
    required this.onPlayAll,
  });

  final int trackCount;
  final int? totalTrackCount;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Row(
        children: [
          MetaPill(
            label: totalTrackCount != null
                ? '$trackCount / $totalTrackCount 首'
                : '$trackCount 首',
            size: MetaPillSize.compact,
          ),
          const Spacer(),
          PlayAllButton(onPressed: onPlayAll),
        ],
      ),
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
          final messenger = ScaffoldMessenger.of(context);
          final isFavorite = track.isFavorite;
          try {
            await cubit.toggleTrackFavorite(track.id);
            if (!context.mounted) return;
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(isFavorite ? '已取消收藏' : '已收藏歌曲'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (_) {
            if (!context.mounted) return;
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: const Text('操作失败，请重试'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colorScheme.error,
              ),
            );
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
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.padded,
          side: BorderSide.none,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.state, required this.controller});

  final LibraryState state;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: '媒体库',
          automaticImplyLeading: false,
          hideTitleOnCompactWithCenter: false,
          center: AppSearchField(
            controller: controller,
            dense: true,
            hintText: _searchHint(state.currentFilter),
            semanticLabel: '搜索媒体库',
            onClear: () {
              controller.clear();
              context.read<LibraryCubit>().search('');
            },
            onSubmitted: (value) => context.read<LibraryCubit>().search(value),
          ),
        ),
        const SizedBox(height: 14),
        AppScopeTabs<LibraryFilter>(
          semanticLabel: '媒体库分类',
          variant: AppBreakpoints.usesWideContent(context)
              ? AppScopeTabsVariant.underline
              : AppScopeTabsVariant.pill,
          selectedValue: state.currentFilter,
          onChanged: (filter) =>
              context.read<LibraryCubit>().changeFilter(filter),
          items: const [
            AppScopeTabItem(value: LibraryFilter.tracks, label: '歌曲'),
            AppScopeTabItem(value: LibraryFilter.albums, label: '专辑'),
            AppScopeTabItem(value: LibraryFilter.artists, label: '艺术家'),
            AppScopeTabItem(value: LibraryFilter.favorites, label: '收藏'),
          ],
        ),
      ],
    );
  }

  String _searchHint(LibraryFilter filter) {
    return switch (filter) {
      LibraryFilter.tracks => '搜索当前歌曲',
      LibraryFilter.albums => '搜索当前专辑',
      LibraryFilter.artists => '搜索当前艺术家',
      LibraryFilter.favorites => '搜索当前歌曲',
    };
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
  const _LibraryFavoritesSliver({this.searchQuery});

  final String? searchQuery;

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

          final query = searchQuery?.trim().toLowerCase() ?? '';
          final filteredTracks = query.isEmpty
              ? state.tracks
              : state.tracks.where((track) {
                  return track.title.toLowerCase().contains(query) ||
                      track.artistName.toLowerCase().contains(query) ||
                      track.albumTitle.toLowerCase().contains(query);
                }).toList();

          if (filteredTracks.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    query.isEmpty
                        ? '还没有收藏歌曲，去媒体库挑几首喜欢的吧。'
                        : '没有找到匹配的收藏歌曲，换个关键词试试。',
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
                    allLoaded: !state.hasMore || query.isNotEmpty,
                    fetchAll: () async {
                      if (query.isNotEmpty) return filteredTracks;
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
              _LibraryFavoritesFooter(state: state, query: query),
            ],
          );
        },
      ),
    );
  }
}

class _LibraryFavoritesFooter extends StatelessWidget {
  const _LibraryFavoritesFooter({required this.state, required this.query});

  final FavoritesListState state;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isNotEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 14));
    }

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

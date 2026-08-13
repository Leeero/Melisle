import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/track_sort_option.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/library/library_filter_views.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_scope_tabs.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/app_skeleton.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        if (_searchController.text != state.searchQuery) {
          _searchController.value = TextEditingValue(
            text: state.searchQuery,
            selection: TextSelection.collapsed(
              offset: state.searchQuery.length,
            ),
          );
        }
        return AppContentPage(
          header: _LibraryHeader(
            state: state,
            searchController: _searchController,
          ),
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
          label: '正在加载${_libraryFilterLabel(state.currentFilter)}',
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

    final scrollView = CustomScrollView(
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
        },
        _buildFooterSliver(state),
      ],
    );
    final body =
        state.currentFilter == LibraryFilter.artists &&
            AppBreakpoints.usesWideContent(context)
        ? Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: scrollView,
              ),
              const Positioned(
                right: 4,
                top: 12,
                bottom: 20,
                child: _ArtistAlphabetRail(),
              ),
            ],
          )
        : scrollView;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: body,
    );
  }

  Widget _buildTrackSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
    String? currentTrackId,
  ) {
    return LibraryTrackSliver(
      state: state,
      horizontalPadding: horizontalPadding,
      currentTrackId: currentTrackId,
      desktopToolbarTrailing: AppBreakpoints.usesDesktopToolbar(context)
          ? _LibraryTrackTools(
              state: state,
              searchController: _searchController,
            )
          : null,
      onPlayAll: () => _playAllLibraryTracks(context, state),
      onShuffleAll: () => _playAllLibraryTracks(context, state, shuffled: true),
      onTrackTap: (index) => PlayerNavigation.playTracksAndOpenPlayer(
        context,
        tracks: state.tracks,
        startIndex: index,
      ),
      desktopTrailingBuilder: (context, track, hovered) =>
          !hovered && track.isFavorite
          ? _LibraryTrackFavoriteButton(track: track)
          : null,
      mobileItemBuilder: (context, track, index, isCurrent) =>
          _MobileLibraryTrackRow(
            track: track,
            index: index,
            isCurrent: isCurrent,
            onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
              context,
              tracks: state.tracks,
              startIndex: index,
            ),
            onMore: () => showTrackActionsSheet(context, track),
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
        fetchAll: context.read<LibraryCubit>().fetchAllTracks,
      );
    }

    return PlayerNavigation.playAllAndOpenPlayer(
      context,
      loadedTracks: state.tracks,
      allLoaded: !state.hasMore,
      fetchAll: context.read<LibraryCubit>().fetchAllTracks,
    );
  }

  Widget _buildAlbumSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
  ) {
    return LibraryAlbumSliver(
      state: state,
      horizontalPadding: horizontalPadding,
    );
  }

  Widget _buildArtistSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
  ) {
    return LibraryArtistSliver(
      state: state,
      horizontalPadding: horizontalPadding,
    );
  }

  Widget _buildPlaylistSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
  ) {
    return LibraryPlaylistSliver(
      state: state,
      horizontalPadding: horizontalPadding,
    );
  }

  Widget _buildFooterSliver(LibraryState state) {
    if (state.isCurrentFilterEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final hasLoadMoreError =
        state.appendErrorMessage != null &&
        !state.isLoadingMore &&
        state.status == LibraryStatus.success;

    return AppSliverPaginationFooter(
      status: hasLoadMoreError
          ? AppPaginationStatus.failed
          : state.isLoadingMore
          ? AppPaginationStatus.loading
          : state.hasMore
          ? AppPaginationStatus.idle
          : AppPaginationStatus.complete,
      errorMessage: state.appendErrorMessage,
      onRetry: hasLoadMoreError
          ? () => context.read<LibraryCubit>().loadMore()
          : null,
    );
  }
}

class _ArtistAlphabetRail extends StatelessWidget {
  const _ArtistAlphabetRail();

  static const _labels = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '艺术家字母索引',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final label in _labels)
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}

String _librarySummaryLabel(LibraryState state) {
  final trackCount = state.totalTrackCount ?? state.tracks.length;
  final parts = <String>[
    if (trackCount > 0) '$trackCount 首',
    if (state.albums.isNotEmpty) '${state.albums.length} 专辑',
    if (state.artists.isNotEmpty) '${state.artists.length} 艺术家',
    if (state.playlists.isNotEmpty) '${state.playlists.length} 播放列表',
  ];

  if (state.status == LibraryStatus.loading && parts.isEmpty) {
    return '正在整理你的媒体库。';
  }
  return parts.isEmpty ? '歌曲、专辑、艺术家和播放列表会按音乐源实时展示。' : parts.join(' · ');
}

String _libraryFilterLabel(LibraryFilter filter) => switch (filter) {
  LibraryFilter.tracks => '歌曲',
  LibraryFilter.albums => '专辑',
  LibraryFilter.artists => '艺术家',
  LibraryFilter.playlists => '播放列表',
};

String _formatTrackDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
  const _LibraryHeader({required this.state, required this.searchController});

  final LibraryState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.usesWideContent(context);
    final trackToolsInList =
        state.currentFilter == LibraryFilter.tracks &&
        state.tracks.isNotEmpty &&
        AppBreakpoints.usesDesktopToolbar(context);
    final cubit = context.read<LibraryCubit>();
    final tabs = AppScopeTabs<LibraryFilter>(
      semanticLabel: '媒体库分类',
      variant: isWide
          ? AppScopeTabsVariant.underline
          : AppScopeTabsVariant.pill,
      selectedValue: state.currentFilter,
      onChanged: cubit.changeFilter,
      fillWidth: !isWide,
      tabGap: isWide ? 34 : null,
      items: isWide
          ? const [
              AppScopeTabItem(value: LibraryFilter.tracks, label: '歌曲'),
              AppScopeTabItem(value: LibraryFilter.albums, label: '专辑'),
              AppScopeTabItem(value: LibraryFilter.artists, label: '艺术家'),
              AppScopeTabItem(value: LibraryFilter.playlists, label: '播放列表'),
            ]
          : const [
              AppScopeTabItem(value: LibraryFilter.tracks, label: '歌曲'),
              AppScopeTabItem(value: LibraryFilter.albums, label: '专辑'),
              AppScopeTabItem(value: LibraryFilter.artists, label: '艺术家'),
              AppScopeTabItem(value: LibraryFilter.playlists, label: '播放列表'),
            ],
    );

    final search = AppSearchField(
      controller: searchController,
      dense: true,
      showCancelAction: false,
      hintText: '在${_libraryFilterLabel(state.currentFilter)}中搜索',
      semanticLabel: '搜索${_libraryFilterLabel(state.currentFilter)}',
      onChanged: cubit.search,
      onClear: () {
        searchController.clear();
        cubit.search('');
      },
    );
    final filterButton =
        state.currentFilter == LibraryFilter.artists && state.genres.isNotEmpty
        ? _LibraryGenreMenu(state: state)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (AppBreakpoints.isCompact(context)) ...[
          AppPageHeader(
            title: '媒体库',
            description: _librarySummaryLabel(state),
            automaticImplyLeading: false,
            hideTitleOnCompactWithCenter: false,
          ),
          const SizedBox(height: 14),
        ],
        if (isWide)
          Row(
            children: [
              SizedBox(width: 420, child: tabs),
              if (!trackToolsInList) ...[
                const Spacer(),
                SizedBox(width: 280, child: search),
              ],
              if (filterButton != null) ...[
                const SizedBox(width: 8),
                filterButton,
              ],
            ],
          )
        else ...[
          Row(
            children: [
              Expanded(child: search),
              if (filterButton != null) ...[
                const SizedBox(width: 8),
                filterButton,
              ],
            ],
          ),
          const SizedBox(height: 12),
          tabs,
        ],
      ],
    );
  }
}

class _LibraryTrackTools extends StatelessWidget {
  const _LibraryTrackTools({
    required this.state,
    required this.searchController,
  });

  final LibraryState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 250,
          child: AppSearchField(
            controller: searchController,
            dense: true,
            showCancelAction: false,
            hintText: '在列表中搜索…',
            semanticLabel: '在歌曲列表中搜索',
            onChanged: cubit.search,
            onClear: () {
              searchController.clear();
              cubit.search('');
            },
          ),
        ),
        if (state.supportedTrackSortOptions.isNotEmpty) ...[
          const SizedBox(width: 12),
          _TrackSortMenu(state: state),
        ],
      ],
    );
  }
}

class _TrackSortMenu extends StatelessWidget {
  const _TrackSortMenu({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.trackSortOption ?? TrackSortOption.title;
    final theme = Theme.of(context);
    return PopupMenuButton<TrackSortOption>(
      tooltip: '选择歌曲排序方式',
      onSelected: context.read<LibraryCubit>().changeTrackSort,
      itemBuilder: (context) => [
        for (final option in state.supportedTrackSortOptions)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: option == selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                Text(_trackSortLabel(option)),
              ],
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 132, minHeight: 46),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '按${_trackSortLabel(selected)}排序',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

String _trackSortLabel(TrackSortOption option) => switch (option) {
  TrackSortOption.title => '标题',
  TrackSortOption.artist => '艺术家',
  TrackSortOption.album => '专辑',
  TrackSortOption.dateAdded => '添加时间',
};

class _LibraryGenreMenu extends StatelessWidget {
  const _LibraryGenreMenu({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '筛选艺术家',
      initialValue: state.selectedGenreId ?? '',
      onSelected: (value) => context.read<LibraryCubit>().changeGenre(
        value.isEmpty ? null : value,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: '', child: Text('全部类型')),
        for (final genre in state.genres)
          PopupMenuItem(value: genre.id, child: Text(genre.name)),
      ],
      icon: Badge(
        isLabelVisible: state.selectedGenreId != null,
        smallSize: 7,
        child: const Icon(Icons.tune_rounded),
      ),
    );
  }
}

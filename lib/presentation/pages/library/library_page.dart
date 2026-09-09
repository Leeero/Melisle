import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/artist_sort_option.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/track_sort_option.dart';
import 'package:cross_platform_music_player/domain/entities/track_filter_option.dart';
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
import 'package:cross_platform_music_player/presentation/widgets/layout/fade_slide_transition.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_library_track_row.dart';
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
  MusicTrackTableDensity _trackDensity = MusicTrackTableDensity.comfortable;
  LibraryAlbumGridDensity _albumDensity = LibraryAlbumGridDensity.comfortable;

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
        final desktopTrackActions =
            state.currentFilter == LibraryFilter.tracks &&
                state.tracks.isNotEmpty &&
                AppBreakpoints.usesWideContent(context)
            ? _LibraryTrackPlaybackActions(
                onPlayAll: () => _playAllLibraryTracks(context, state),
                onShuffleAll: () =>
                    _playAllLibraryTracks(context, state, shuffled: true),
              )
            : null;
        return AppContentPage(
          header: _LibraryHeader(
            state: state,
            searchController: _searchController,
            desktopTrackActions: desktopTrackActions,
            trackDensity: _trackDensity,
            onTrackDensityChanged: (density) {
              setState(() => _trackDensity = density);
            },
            albumDensity: _albumDensity,
            onAlbumDensityChanged: (density) {
              setState(() => _albumDensity = density);
            },
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
      return SingleChildScrollView(
        key: const ValueKey('library-loading-scroll-view'),
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
                padding: const EdgeInsets.only(
                  right: AppSpacingTokens.sectionPadding,
                ),
                child: scrollView,
              ),
              Positioned(
                right: 4,
                top: 12,
                bottom: 20,
                child: _ArtistAlphabetRail(
                  artists: sortLibraryArtists(state.artists),
                  onSelected: (label) =>
                      _scrollToArtistLabel(label, state.artists),
                ),
              ),
            ],
          )
        : scrollView;

    return AnimatedSwitcher(duration: AppMotion.micro, child: body);
  }

  void _scrollToArtistLabel(String label, List<MusicArtist> artists) {
    if (!_scrollController.hasClients) return;

    final sortedArtists = sortLibraryArtists(artists);
    final targetIndex = sortedArtists.indexWhere(
      (artist) => _artistIndexLabel(artist.name) == label,
    );
    if (targetIndex < 0) return;

    final viewportWidth =
        context.size?.width ?? MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    final availableGridWidth =
        viewportWidth - AppSpacingTokens.sectionPadding - horizontalPadding * 2;
    if (availableGridWidth <= 0) return;
    final crossAxisCount = libraryArtistGridCount(availableGridWidth);
    final row = targetIndex ~/ crossAxisCount;
    const rowExtent =
        libraryArtistGridMainAxisExtent + libraryArtistGridMainAxisSpacing;
    final offset = (row * rowExtent)
        .toDouble()
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    _scrollController.animateTo(
      offset,
      duration: AppMotion.state,
      curve: AppMotion.standard,
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
      density: _trackDensity,
      onTrackTap: (index) => PlayerNavigation.playTracksAndOpenPlayer(
        context,
        tracks: state.tracks,
        startIndex: index,
      ),
      desktopTrailingBuilder: (context, track, hovered) =>
          _LibraryTrackActions(track: track),
      mobileItemBuilder: (context, track, index, isCurrent) =>
          StaggeredFadeSlide(
            index: index,
            delay: const Duration(milliseconds: 30),
            child: MusicLibraryTrackRow(
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
      density: _albumDensity,
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
  const _ArtistAlphabetRail({required this.artists, required this.onSelected});

  final List<MusicArtist> artists;
  final ValueChanged<String> onSelected;

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
    final availableLabels = artists
        .map((artist) => _artistIndexLabel(artist.name))
        .toSet();
    return Semantics(
      label: '歌手字母索引',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final label in _labels) ...[
            Builder(
              builder: (context) {
                final enabled = availableLabels.contains(label);
                final color = enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
                return Semantics(
                  button: enabled,
                  enabled: enabled,
                  label: '$label 开头的歌手',
                  child: MouseRegion(
                    cursor: enabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: enabled ? () => onSelected(label) : null,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

String _artistIndexLabel(String name) {
  final trimmed = name.trimLeft();
  if (trimmed.isEmpty) return '#';
  final first = trimmed.codeUnitAt(0);
  if (first >= 65 && first <= 90) return String.fromCharCode(first);
  if (first >= 97 && first <= 122) return String.fromCharCode(first - 32);
  return '#';
}

String _librarySummaryLabel(LibraryState state) {
  final trackCount = state.totalTrackCount ?? state.tracks.length;
  final parts = <String>[
    if (trackCount > 0) '$trackCount 首',
    if (state.albums.isNotEmpty) '${state.albums.length} 专辑',
    if (state.artists.isNotEmpty) '${state.artists.length} 歌手',
    if (state.playlists.isNotEmpty) '${state.playlists.length} 歌单',
  ];

  if (state.status == LibraryStatus.loading && parts.isEmpty) {
    return '正在整理你的媒体库。';
  }
  return parts.isEmpty ? '歌曲、专辑、歌手和歌单会按音乐源实时展示。' : parts.join(' · ');
}

String _libraryFilterLabel(LibraryFilter filter) => switch (filter) {
  LibraryFilter.tracks => '歌曲',
  LibraryFilter.albums => '专辑',
  LibraryFilter.artists => '歌手',
  LibraryFilter.playlists => '歌单',
};

String _libraryFilterCountLabel(LibraryState state) {
  if (state.status == LibraryStatus.loading && state.isCurrentFilterEmpty) {
    return '正在加载';
  }
  return switch (state.currentFilter) {
    LibraryFilter.tracks => _trackResultCountLabel(state),
    LibraryFilter.albums => '已显示 ${state.albums.length} 张',
    LibraryFilter.artists => '已显示 ${state.artists.length} 位',
    LibraryFilter.playlists => '已显示 ${state.playlists.length} 个',
  };
}

String _trackResultCountLabel(LibraryState state) {
  final count = _formatCount(state.totalTrackCount ?? state.tracks.length);
  if (state.trackFilters.isEmpty) return '共 $count 首';
  return '$count 首 · ${state.trackFilters.map(_trackFilterLabel).join('、')}';
}

String _formatCount(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          duration: AppMotion.micro,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            track.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            key: ValueKey(track.isFavorite),
            size: 18,
            color: track.isFavorite
                ? colorScheme.primary
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

class _LibraryTrackPlaybackActions extends StatelessWidget {
  const _LibraryTrackPlaybackActions({
    required this.onPlayAll,
    required this.onShuffleAll,
  });

  final VoidCallback onPlayAll;
  final VoidCallback onShuffleAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppActionButton(
          icon: Icons.shuffle_rounded,
          label: '随机播放',
          onPressed: onShuffleAll,
        ),
        const SizedBox(width: 10),
        AppActionButton(
          icon: Icons.play_arrow_rounded,
          label: '播放全部',
          tone: AppActionButtonTone.primary,
          onPressed: onPlayAll,
        ),
      ],
    );
  }
}

class _LibraryTrackActions extends StatelessWidget {
  const _LibraryTrackActions({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _LibraryTrackFavoriteButton(track: track),
        SizedBox.square(
          dimension: 44,
          child: IconButton(
            onPressed: () => showTrackActionsSheet(context, track),
            icon: const Icon(Icons.more_horiz_rounded, size: 20),
            tooltip: '更多操作',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            style: AppActionButtonStyle.icon(context, size: 44),
          ),
        ),
      ],
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
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacingTokens.compactGap,
                ),
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
  const _LibraryHeader({
    required this.state,
    required this.searchController,
    this.desktopTrackActions,
    required this.trackDensity,
    required this.onTrackDensityChanged,
    required this.albumDensity,
    required this.onAlbumDensityChanged,
  });

  final LibraryState state;
  final TextEditingController searchController;
  final Widget? desktopTrackActions;
  final MusicTrackTableDensity trackDensity;
  final ValueChanged<MusicTrackTableDensity> onTrackDensityChanged;
  final LibraryAlbumGridDensity albumDensity;
  final ValueChanged<LibraryAlbumGridDensity> onAlbumDensityChanged;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.usesWideContent(context);
    final cubit = context.read<LibraryCubit>();
    final tabs = AppScopeTabs<LibraryFilter>(
      semanticLabel: '媒体库分类',
      variant: AppScopeTabsVariant.pill,
      selectedValue: state.currentFilter,
      onChanged: cubit.changeFilter,
      fillWidth: true,
      items: const [
        AppScopeTabItem(value: LibraryFilter.tracks, label: '歌曲'),
        AppScopeTabItem(value: LibraryFilter.albums, label: '专辑'),
        AppScopeTabItem(value: LibraryFilter.artists, label: '歌手'),
        AppScopeTabItem(value: LibraryFilter.playlists, label: '歌单'),
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
    final artistFilterButton =
        state.currentFilter == LibraryFilter.artists &&
            state.supportedArtistSortOptions.isNotEmpty
        ? _ArtistFilterMenu(state: state)
        : null;
    final headerTrailing = state.currentFilter == LibraryFilter.tracks
        ? desktopTrackActions
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
        if (isWide) ...[
          AppPageHeader(
            title: _libraryFilterLabel(state.currentFilter),
            description: _libraryFilterCountLabel(state),
            trailing: headerTrailing,
            automaticImplyLeading: false,
          ),
          if (state.currentFilter == LibraryFilter.tracks) ...[
            const SizedBox(height: 24),
            _DesktopTrackToolbar(
              state: state,
              search: search,
              density: trackDensity,
              onDensityChanged: onTrackDensityChanged,
            ),
          ] else if (state.currentFilter == LibraryFilter.albums) ...[
            const SizedBox(height: 24),
            _DesktopAlbumToolbar(
              search: search,
              density: albumDensity,
              onDensityChanged: onAlbumDensityChanged,
            ),
          ] else if (state.currentFilter == LibraryFilter.artists) ...[
            const SizedBox(height: 24),
            _DesktopArtistToolbar(state: state, search: search),
          ],
        ] else ...[
          search,
          if (artistFilterButton != null) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: artistFilterButton),
          ],
          const SizedBox(height: 12),
          tabs,
        ],
      ],
    );
  }
}

class _DesktopArtistToolbar extends StatelessWidget {
  const _DesktopArtistToolbar({required this.state, required this.search});

  final LibraryState state;
  final Widget search;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadiusTokens.desktopMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: search),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _ArtistSortDropdown(state: state)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _ArtistGenreDropdown(state: state)),
        ],
      ),
    );
  }
}

class _ArtistSortDropdown extends StatelessWidget {
  const _ArtistSortDropdown({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final options = ArtistSortOption.values
        .where(state.supportedArtistSortOptions.contains)
        .toList(growable: false);
    final selected = state.artistSortOption;
    return PopupMenuButton<ArtistSortOption>(
      tooltip: '选择歌手排序方式',
      enabled: options.isNotEmpty,
      onSelected: context.read<LibraryCubit>().changeArtistSort,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            child: _TrackMenuRow(
              label: option == ArtistSortOption.name
                  ? '默认顺序'
                  : _artistSortLabel(option),
              icon: _artistSortIcon(option),
              selected: option == selected,
            ),
          ),
      ],
      child: _ToolbarDropdown(
        icon: Icons.sort_by_alpha_rounded,
        label: selected == null || selected == ArtistSortOption.name
            ? '默认顺序'
            : _artistSortLabel(selected),
      ),
    );
  }
}

class _ArtistGenreDropdown extends StatelessWidget {
  const _ArtistGenreDropdown({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final selectedGenre = state.genres
        .where((genre) => genre.id == state.selectedGenreId)
        .firstOrNull;
    return PopupMenuButton<_ArtistGenreSelection>(
      tooltip: '按音乐风格筛选歌手',
      enabled: state.genres.isNotEmpty,
      onSelected: (selection) =>
          context.read<LibraryCubit>().changeGenre(selection.genreId),
      itemBuilder: (context) => [
        _ArtistGenrePopupItem(
          value: const _ArtistGenreSelection(null),
          label: '全部风格',
          icon: Icons.library_music_outlined,
          selected: state.selectedGenreId == null,
        ),
        for (final genre in state.genres)
          _ArtistGenrePopupItem(
            value: _ArtistGenreSelection(genre.id),
            label: genre.name,
            icon: Icons.music_note_outlined,
            selected: genre.id == state.selectedGenreId,
          ),
      ],
      child: _ToolbarDropdown(
        icon: Icons.tune_rounded,
        label: selectedGenre?.name ?? '全部风格',
      ),
    );
  }
}

class _ArtistGenreSelection {
  const _ArtistGenreSelection(this.genreId);

  final String? genreId;
}

class _ArtistGenrePopupItem extends PopupMenuItem<_ArtistGenreSelection> {
  _ArtistGenrePopupItem({
    required super.value,
    required String label,
    required IconData icon,
    required bool selected,
  }) : super(
         child: _TrackMenuRow(label: label, icon: icon, selected: selected),
       );
}

class _DesktopAlbumToolbar extends StatelessWidget {
  const _DesktopAlbumToolbar({
    required this.search,
    required this.density,
    required this.onDensityChanged,
  });

  final Widget search;
  final LibraryAlbumGridDensity density;
  final ValueChanged<LibraryAlbumGridDensity> onDensityChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadiusTokens.desktopMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 16),
          _AlbumDensityMenu(value: density, onChanged: onDensityChanged),
        ],
      ),
    );
  }
}

class _AlbumDensityMenu extends StatelessWidget {
  const _AlbumDensityMenu({required this.value, required this.onChanged});

  final LibraryAlbumGridDensity value;
  final ValueChanged<LibraryAlbumGridDensity> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LibraryAlbumGridDensity>(
      tooltip: '调整专辑封面尺寸',
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final density in LibraryAlbumGridDensity.values)
          PopupMenuItem(
            value: density,
            child: _TrackMenuRow(
              label: density == LibraryAlbumGridDensity.comfortable
                  ? '大封面'
                  : '紧凑网格',
              icon: density == LibraryAlbumGridDensity.comfortable
                  ? Icons.grid_view_rounded
                  : Icons.apps_rounded,
              selected: density == value,
            ),
          ),
      ],
      child: SizedBox(
        width: 166,
        child: _ToolbarDropdown(
          icon: value == LibraryAlbumGridDensity.comfortable
              ? Icons.grid_view_rounded
              : Icons.apps_rounded,
          label: value == LibraryAlbumGridDensity.comfortable ? '大封面' : '紧凑网格',
        ),
      ),
    );
  }
}

class _DesktopTrackToolbar extends StatelessWidget {
  const _DesktopTrackToolbar({
    required this.state,
    required this.search,
    required this.density,
    required this.onDensityChanged,
  });

  final LibraryState state;
  final Widget search;
  final MusicTrackTableDensity density;
  final ValueChanged<MusicTrackTableDensity> onDensityChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadiusTokens.desktopMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: search),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _TrackFilterMenu(state: state)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _TrackSortMenu(state: state)),
          const SizedBox(width: 16),
          _TrackDensityMenu(value: density, onChanged: onDensityChanged),
        ],
      ),
    );
  }
}

class _TrackSortMenu extends StatelessWidget {
  const _TrackSortMenu({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.trackSortOption ?? TrackSortOption.title;
    final options = TrackSortOption.values
        .where(state.supportedTrackSortOptions.contains)
        .toList(growable: false);
    return PopupMenuButton<TrackSortOption>(
      tooltip: '选择排序方式',
      enabled: options.isNotEmpty,
      onSelected: context.read<LibraryCubit>().changeTrackSort,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            child: _TrackMenuRow(
              label: option == TrackSortOption.title
                  ? '默认顺序'
                  : _trackSortLabel(option),
              icon: _trackSortIcon(option),
              selected: option == selected,
            ),
          ),
      ],
      child: _ToolbarDropdown(
        icon: Icons.swap_vert_rounded,
        label: selected == TrackSortOption.title
            ? '默认顺序'
            : _trackSortLabel(selected),
      ),
    );
  }
}

enum _TrackFilterSelection { all, favorite }

class _TrackFilterMenu extends StatelessWidget {
  const _TrackFilterMenu({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final favoriteSelected = state.trackFilters.contains(
      TrackFilterOption.favorite,
    );
    final favoriteSupported = state.supportedTrackFilterOptions.contains(
      TrackFilterOption.favorite,
    );
    return PopupMenuButton<_TrackFilterSelection>(
      tooltip: '筛选歌曲',
      onSelected: (selection) {
        final cubit = context.read<LibraryCubit>();
        if (selection == _TrackFilterSelection.all) {
          cubit.clearTrackFilters();
        } else {
          cubit.toggleTrackFilter(TrackFilterOption.favorite);
        }
      },
      itemBuilder: (context) => [
        _TrackFilterPopupItem(
          value: _TrackFilterSelection.all,
          label: '全部歌曲',
          icon: Icons.library_music_outlined,
          selected: !favoriteSelected,
        ),
        if (favoriteSupported)
          _TrackFilterPopupItem(
            value: _TrackFilterSelection.favorite,
            label: '仅显示收藏',
            icon: Icons.favorite_border_rounded,
            selected: favoriteSelected,
          ),
      ],
      child: _ToolbarDropdown(
        icon: favoriteSelected
            ? Icons.favorite_rounded
            : Icons.library_music_outlined,
        label: favoriteSelected ? '仅显示收藏' : '全部歌曲',
      ),
    );
  }
}

class _TrackFilterPopupItem extends PopupMenuItem<_TrackFilterSelection> {
  _TrackFilterPopupItem({
    required super.value,
    required String label,
    required IconData icon,
    required bool selected,
  }) : super(
         child: _TrackMenuRow(label: label, icon: icon, selected: selected),
       );
}

class _TrackDensityMenu extends StatelessWidget {
  const _TrackDensityMenu({required this.value, required this.onChanged});

  final MusicTrackTableDensity value;
  final ValueChanged<MusicTrackTableDensity> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MusicTrackTableDensity>(
      tooltip: '调整显示密度',
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final density in MusicTrackTableDensity.values)
          PopupMenuItem(
            value: density,
            child: _TrackMenuRow(
              label: density == MusicTrackTableDensity.comfortable
                  ? '舒适'
                  : '紧凑',
              icon: density == MusicTrackTableDensity.comfortable
                  ? Icons.view_agenda_outlined
                  : Icons.density_small_rounded,
              selected: density == value,
            ),
          ),
      ],
      child: const SizedBox(
        width: 154,
        child: _ToolbarDropdown(icon: Icons.view_list_rounded, label: '显示密度'),
      ),
    );
  }
}

class _ToolbarDropdown extends StatelessWidget {
  const _ToolbarDropdown({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadiusTokens.button),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _TrackMenuRow extends StatelessWidget {
  const _TrackMenuRow({
    required this.label,
    required this.icon,
    required this.selected,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Center(
            child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        if (selected) Icon(Icons.check_rounded, color: colorScheme.primary),
      ],
    );
  }
}

class _ArtistFilterMenu extends StatefulWidget {
  const _ArtistFilterMenu({required this.state});

  final LibraryState state;

  @override
  State<_ArtistFilterMenu> createState() => _ArtistFilterMenuState();
}

class _ArtistFilterMenuState extends State<_ArtistFilterMenu> {
  final GlobalKey _triggerKey = GlobalKey();

  Future<void> _showMenu() async {
    final triggerContext = _triggerKey.currentContext;
    if (triggerContext == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final trigger = triggerContext.findRenderObject() as RenderBox;
    final triggerRect =
        trigger.localToGlobal(Offset.zero, ancestor: overlay) & trigger.size;
    final anchor = Rect.fromCenter(
      center: Offset(triggerRect.right, triggerRect.center.dy),
      width: 1,
      height: 1,
    );
    final action = await showMenu<_ArtistMenuAction>(
      context: context,
      position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
      constraints: const BoxConstraints.tightFor(width: 240),
      items: _menuItems(widget.state),
    );
    if (!mounted || action == null) return;

    final cubit = context.read<LibraryCubit>();
    switch (action.type) {
      case _ArtistMenuActionType.sort:
        cubit.changeArtistSort(action.sortOption!);
      case _ArtistMenuActionType.genre:
        cubit.changeGenre(action.genreId);
    }
  }

  List<PopupMenuEntry<_ArtistMenuAction>> _menuItems(LibraryState state) {
    final selectedSort = state.artistSortOption ?? ArtistSortOption.name;
    final items = <PopupMenuEntry<_ArtistMenuAction>>[
      const PopupMenuItem(enabled: false, height: 36, child: Text('排序方式')),
    ];

    for (final option in ArtistSortOption.values) {
      if (!state.supportedArtistSortOptions.contains(option)) continue;
      items.add(
        PopupMenuItem(
          value: _ArtistMenuAction.sort(option),
          mouseCursor: SystemMouseCursors.click,
          child: _TrackMenuRow(
            label: _artistSortLabel(option),
            icon: _artistSortIcon(option),
            selected: option == selectedSort,
          ),
        ),
      );
    }

    if (state.genres.isEmpty) return items;

    items.addAll([
      const PopupMenuDivider(),
      const PopupMenuItem(enabled: false, height: 36, child: Text('音乐风格')),
      PopupMenuItem(
        value: const _ArtistMenuAction.genre(null),
        mouseCursor: SystemMouseCursors.click,
        child: _TrackMenuRow(
          label: '全部风格',
          icon: Icons.library_music_outlined,
          selected: state.selectedGenreId == null,
        ),
      ),
      for (final genre in state.genres)
        PopupMenuItem(
          value: _ArtistMenuAction.genre(genre.id),
          mouseCursor: SystemMouseCursors.click,
          child: _TrackMenuRow(
            label: genre.name,
            icon: Icons.music_note_outlined,
            selected: genre.id == state.selectedGenreId,
          ),
        ),
    ]);
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final selectedGenre = widget.state.genres
        .where((genre) => genre.id == widget.state.selectedGenreId)
        .firstOrNull;
    final selectedGenreName = selectedGenre?.name;
    final buttonLabel = selectedGenreName == null
        ? '筛选与排序'
        : '筛选与排序 · $selectedGenreName';
    final semanticLabel = selectedGenreName == null
        ? '歌手筛选与排序，当前未按风格筛选'
        : '歌手筛选与排序，当前风格$selectedGenreName';
    return Semantics(
      button: true,
      label: semanticLabel,
      child: TextButton.icon(
        key: _triggerKey,
        onPressed: _showMenu,
        style: AppActionButtonStyle.text(context),
        icon: Badge(
          isLabelVisible: selectedGenre != null,
          smallSize: 7,
          child: const Icon(Icons.tune_rounded, size: 18),
        ),
        label: Text(buttonLabel),
      ),
    );
  }
}

enum _ArtistMenuActionType { sort, genre }

class _ArtistMenuAction {
  const _ArtistMenuAction.sort(this.sortOption)
    : type = _ArtistMenuActionType.sort,
      genreId = null;

  const _ArtistMenuAction.genre(this.genreId)
    : type = _ArtistMenuActionType.genre,
      sortOption = null;

  final _ArtistMenuActionType type;
  final ArtistSortOption? sortOption;
  final String? genreId;
}

String _trackSortLabel(TrackSortOption option) => switch (option) {
  TrackSortOption.title => '标题',
  TrackSortOption.artist => '歌手',
  TrackSortOption.album => '专辑',
  TrackSortOption.dateAdded => '添加时间',
};

IconData _trackSortIcon(TrackSortOption option) => switch (option) {
  TrackSortOption.title => Icons.sort_by_alpha_rounded,
  TrackSortOption.artist => Icons.person_outline_rounded,
  TrackSortOption.album => Icons.album_outlined,
  TrackSortOption.dateAdded => Icons.calendar_today_outlined,
};

String _trackFilterLabel(TrackFilterOption option) => switch (option) {
  TrackFilterOption.favorite => '仅显示收藏',
};

String _artistSortLabel(ArtistSortOption option) => switch (option) {
  ArtistSortOption.name => '名称',
  ArtistSortOption.dateAdded => '添加时间',
};

IconData _artistSortIcon(ArtistSortOption option) => switch (option) {
  ArtistSortOption.name => Icons.sort_by_alpha_rounded,
  ArtistSortOption.dateAdded => Icons.calendar_today_outlined,
};

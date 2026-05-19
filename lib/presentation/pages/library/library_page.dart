import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
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
          length: 3,
          initialIndex: state.currentFilter.index,
          child: AppContentPage(
            header: _LibraryHeader(
              state: state,
              controller: _searchController,
              tracks: state.tracks,
            ),
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
          },
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
              child: _TrackTableActionBar(
                trackCount: state.currentFilterCount,
                totalTrackCount: state.totalTrackCount,
                onPlayAll: () => PlayerNavigation.playAllAndOpenPlayer(
                  context,
                  loadedTracks: state.tracks,
                  allLoaded: !state.hasMore,
                  fetchAll: () async {
                    final result = await context
                        .read<MusicRepository>()
                        .fetchTracks(
                          limit: 500,
                          startIndex: 0,
                          searchQuery: state.searchQuery.trim().isEmpty
                              ? null
                              : state.searchQuery.trim(),
                        );
                    return result.items;
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _TrackTableHeader()),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final track = state.tracks[index];
                return _TrackTableRow(
                  index: index + 1,
                  track: track,
                  isCurrent: track.id == currentTrackId,
                  onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                    context,
                    tracks: state.tracks,
                    startIndex: index,
                  ),
                );
              }, childCount: state.tracks.length),
            ),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverList(
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
          childAspectRatio: 0.76,
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
                  height: 32,
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
                return _ArtistCircleCard(artist: artist);
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

class _TrackTableActionBar extends StatelessWidget {
  const _TrackTableActionBar({
    required this.trackCount,
    this.totalTrackCount,
    required this.onPlayAll,
  });

  final int trackCount;
  final int? totalTrackCount;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Row(
        children: [
          MetaPill(
            label: totalTrackCount != null
                ? '$trackCount / $totalTrackCount 首'
                : '$trackCount 首',
            size: MetaPillSize.compact,
          ),
          const Spacer(),
          InkWell(
            onTap: onPlayAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '播放全部',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackTableHeader extends StatelessWidget {
  const _TrackTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('#', style: labelStyle, textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          const SizedBox(width: 48),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text('歌曲', style: labelStyle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text('歌手', style: labelStyle),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text('专辑', style: labelStyle),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 60,
            child: Text('时长', textAlign: TextAlign.right, style: labelStyle),
          ),
        ],
      ),
    );
  }
}

class _TrackTableRow extends StatefulWidget {
  const _TrackTableRow({
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.onTap,
  });

  final int index;
  final MusicTrack track;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  State<_TrackTableRow> createState() => _TrackTableRowState();
}

class _TrackTableRowState extends State<_TrackTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final indexText = widget.index.toString().padLeft(2, '0');

    return Semantics(
      label: '歌曲: ${widget.track.title}, 歌手: ${widget.track.artistName}',
      selected: widget.isCurrent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? colorScheme.primaryContainer.withValues(alpha: 0.8)
                : _hovered
                ? colorScheme.surface.withValues(alpha: 0.92)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: widget.isCurrent
                ? Border.all(color: colorScheme.primary.withValues(alpha: 0.28))
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                child: Row(
                  children: [
                    // Index / playing indicator / play on hover
                    SizedBox(
                      width: 36,
                      child: Center(
                        child: widget.isCurrent
                            ? Icon(
                                Icons.graphic_eq_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              )
                            : _hovered
                            ? Icon(
                                Icons.play_arrow_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              )
                            : Text(
                                indexText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Album artwork
                    CachedArtwork(
                      imageUrl: widget.track.artworkUrl,
                      size: 48,
                      borderRadius: 14,
                    ),
                    const SizedBox(width: 12),
                    // Title + Hi-Res badge
                    Expanded(
                      flex: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: widget.isCurrent
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  fontWeight: widget.isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (widget.track.codec?.toLowerCase() == 'flac')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: MetaPill(
                                  label: 'Hi-Res',
                                  size: MetaPillSize.compact,
                                  backgroundColor: colorScheme.tertiary
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Artist
                    Expanded(
                      flex: 2,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          widget.track.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Album
                    Expanded(
                      flex: 3,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          widget.track.albumTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Duration + favorite on hover
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hovered)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                onPressed: () async {
                                  final cubit = context.read<LibraryCubit>();
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final isFavorite = widget.track.isFavorite;
                                  try {
                                    await cubit.toggleTrackFavorite(
                                      widget.track.id,
                                    );
                                    if (!context.mounted) return;
                                    messenger.clearSnackBars();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isFavorite ? '已取消收藏' : '已收藏歌曲',
                                        ),
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
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    widget.track.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    key: ValueKey(widget.track.isFavorite),
                                    size: 18,
                                    color: widget.track.isFavorite
                                        ? Colors.redAccent
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            _formatDuration(widget.track.duration),
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Phase 4: Search PrefixIcon focus animation
class _LibraryHeader extends StatefulWidget {
  const _LibraryHeader({
    required this.state,
    required this.controller,
    required this.tracks,
  });

  final LibraryState state;
  final TextEditingController controller;
  final List<MusicTrack> tracks;

  @override
  State<_LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends State<_LibraryHeader> {
  late final FocusNode _searchFocusNode;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode()..addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    setState(() => _searchFocused = _searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageTitleRow(title: '媒体库'),
        const SizedBox(height: 14),
        // ── Search field ──
        TextField(
          controller: widget.controller,
          focusNode: _searchFocusNode,
          onChanged: context.read<LibraryCubit>().search,
          decoration: InputDecoration(
            hintText: _searchHint(widget.state.currentFilter),
            prefixIcon: AnimatedScale(
              scale: _searchFocused ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Filter tabs/pills ──
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = AppBreakpoints.usesWideContentWidth(
              constraints.maxWidth,
            );

            if (isWide) {
              return _LibraryPCFilterTabs(
                selectedFilter: widget.state.currentFilter,
                onFilterChanged: (filter) =>
                    context.read<LibraryCubit>().changeFilter(filter),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FilterPill(
                  label: '歌曲',
                  icon: Icons.music_note_rounded,
                  selected: widget.state.currentFilter == LibraryFilter.tracks,
                  onTap: () => context.read<LibraryCubit>().changeFilter(
                    LibraryFilter.tracks,
                  ),
                ),
                _FilterPill(
                  label: '专辑',
                  icon: Icons.album_rounded,
                  selected: widget.state.currentFilter == LibraryFilter.albums,
                  onTap: () => context.read<LibraryCubit>().changeFilter(
                    LibraryFilter.albums,
                  ),
                ),
                _FilterPill(
                  label: '艺术家',
                  icon: Icons.mic_external_on_rounded,
                  selected: widget.state.currentFilter == LibraryFilter.artists,
                  onTap: () => context.read<LibraryCubit>().changeFilter(
                    LibraryFilter.artists,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _searchHint(LibraryFilter filter) {
    return switch (filter) {
      LibraryFilter.tracks => '搜索当前歌曲',
      LibraryFilter.albums => '搜索当前专辑',
      LibraryFilter.artists => '搜索当前艺术家',
    };
  }
}

class _LibraryPCFilterTabs extends StatelessWidget {
  const _LibraryPCFilterTabs({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final LibraryFilter selectedFilter;
  final ValueChanged<LibraryFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        onTap: (index) => onFilterChanged(LibraryFilter.values[index]),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: colorScheme.primary,
        indicatorWeight: 3,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          _HoverTab(
            label: '歌曲',
            isSelected: selectedFilter == LibraryFilter.tracks,
          ),
          _HoverTab(
            label: '专辑',
            isSelected: selectedFilter == LibraryFilter.albums,
          ),
          _HoverTab(
            label: '艺术家',
            isSelected: selectedFilter == LibraryFilter.artists,
          ),
        ],
      ),
    );
  }
}

class _HoverTab extends StatefulWidget {
  const _HoverTab({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  State<_HoverTab> createState() => _HoverTabState();
}

class _HoverTabState extends State<_HoverTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final textColor = widget.isSelected
        ? colorScheme.primary
        : _hovered
        ? colorScheme.primary.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tab(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: theme.textTheme.titleMedium!.copyWith(
            color: textColor,
            fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          child: Text(widget.label),
        ),
      ),
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

class _ArtistCircleCard extends StatelessWidget {
  const _ArtistCircleCard({required this.artist});

  final MusicArtist artist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/artist/${artist.id}', extra: artist),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final artworkSize = constraints.maxWidth * 0.78;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 圆形头像
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.11,
                ),
                child: CachedArtwork(
                  imageUrl: artist.artworkUrl,
                  size: artworkSize,
                  borderRadius: artworkSize / 2,
                ),
              ),
              const SizedBox(height: 10),
              // 艺术家名称
              Text(
                artist.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              // 歌曲计数
              Text(
                '${artist.trackCount} 首歌曲',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.92)
                : colorScheme.surface.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

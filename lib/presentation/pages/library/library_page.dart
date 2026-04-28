import 'package:cross_platform_music_player/application/usecases/fetch_library_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_artists.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_library_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
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
        return AppContentPage(
          header: _LibraryHeader(
            state: state,
            controller: _searchController,
            tracks: state.tracks,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == LibraryStatus.failure && state.isCurrentFilterEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? '加载媒体库失败',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.read<LibraryCubit>().load(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
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
    );
  }

  Widget _buildTrackSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
    String? currentTrackId,
  ) {
    if (state.tracks.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('当前没有匹配的歌曲。')),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final track = state.tracks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TrackCard(
              trackId: track.id,
              currentTrackId: currentTrackId,
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
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('当前没有匹配的专辑。')),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _AlbumCard(album: state.albums[index]),
          childCount: state.albums.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _albumGridCount(MediaQuery.sizeOf(context).width),
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: 0.82,
        ),
      ),
    );
  }

  Widget _buildArtistSliver(
    BuildContext context,
    LibraryState state,
    double horizontalPadding,
  ) {
    if (state.artists.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('当前没有匹配的艺术家。')),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ArtistCard(artist: state.artists[index]),
          ),
          childCount: state.artists.length,
        ),
      ),
    );
  }

  Widget _buildFooterSliver(LibraryState state) {
    if (state.isCurrentFilterEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
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
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Center(child: Text('已经到底了')),
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox(height: 14));
  }

  int _albumGridCount(double width) {
    return AppBreakpoints.adaptiveAlbumGridCount(width);
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title row ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('媒体库', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '在歌曲、专辑和艺术家之间快速切换',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _MetaPill(label: '${widget.state.currentFilterCount} 项'),
            ],
          ),
        ),
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
        // ── Filter pills + Play All ──
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FilterPill(
                    label: '歌曲',
                    icon: Icons.music_note_rounded,
                    selected:
                        widget.state.currentFilter == LibraryFilter.tracks,
                    onTap: () => context.read<LibraryCubit>().changeFilter(
                      LibraryFilter.tracks,
                    ),
                  ),
                  _FilterPill(
                    label: '专辑',
                    icon: Icons.album_rounded,
                    selected:
                        widget.state.currentFilter == LibraryFilter.albums,
                    onTap: () => context.read<LibraryCubit>().changeFilter(
                      LibraryFilter.albums,
                    ),
                  ),
                  _FilterPill(
                    label: '艺术家',
                    icon: Icons.mic_external_on_rounded,
                    selected:
                        widget.state.currentFilter == LibraryFilter.artists,
                    onTap: () => context.read<LibraryCubit>().changeFilter(
                      LibraryFilter.artists,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.state.currentFilter == LibraryFilter.tracks &&
                widget.tracks.isNotEmpty) ...[
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () => PlayerNavigation.playAllAndOpenPlayer(
                  context,
                  loadedTracks: widget.tracks,
                  allLoaded: !widget.state.hasMore,
                  fetchAll: () => context.read<MusicRepository>().fetchTracks(
                    limit: 500,
                    startIndex: 0,
                    searchQuery: widget.state.searchQuery.trim().isEmpty
                        ? null
                        : widget.state.searchQuery.trim(),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('播放全部'),
              ),
            ],
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
    };
  }
}

class _TrackCard extends StatefulWidget {
  const _TrackCard({
    required this.trackId,
    required this.currentTrackId,
    required this.artworkUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String trackId;
  final String? currentTrackId;
  final String artworkUrl;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  @override
  State<_TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends State<_TrackCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrent = widget.trackId == widget.currentTrackId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isCurrent
              ? colorScheme.primaryContainer.withValues(alpha: 0.82)
              : colorScheme.surface.withValues(alpha: _hovered ? 0.92 : 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.68),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: widget.artworkUrl,
                    size: 58,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              _MetaPill(label: '当前播放'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isCurrent
                          ? Icons.graphic_eq_rounded
                          : Icons.play_arrow_rounded,
                      color: isCurrent
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
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

class _AlbumCard extends StatefulWidget {
  const _AlbumCard({required this.album});

  final MusicAlbum album;

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _hovered ? 1.012 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/album/${album.id}', extra: album),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.82,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: CachedArtwork(
                            imageUrl: album.artworkUrl,
                            size: 162,
                            borderRadius: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaPill(
                      label: '${album.trackCount} 首 · ${album.year ?? '未知年份'}',
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

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist});

  final MusicArtist artist;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/artist/${artist.id}', extra: artist),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CachedArtwork(
                imageUrl: artist.artworkUrl,
                size: 72,
                borderRadius: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${artist.albumCount} 张专辑 · ${artist.trackCount} 首歌曲',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _MetaPill(label: '艺术家档案'),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

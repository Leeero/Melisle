import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/search/search_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/search/search_state.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = SearchCubit(
          context.read<MusicRepository>(),
          database: _tryReadDatabase(context),
        );
        if (initialQuery != null && initialQuery!.trim().isNotEmpty) {
          cubit.submit(initialQuery!);
        }
        return cubit;
      },
      child: _SearchView(initialQuery: initialQuery),
    );
  }

  static AppDatabase? _tryReadDatabase(BuildContext context) {
    try {
      return context.read<AppDatabase>();
    } catch (_) {
      return null;
    }
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({this.initialQuery});

  final String? initialQuery;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode()..addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          // Phase 4: Search box focus scale 1.0→1.02
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: AnimatedScale(
              scale: _focused ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '搜索曲目 / 专辑 / 艺术家 / 歌单',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          context.read<SearchCubit>().onQueryChanged('');
                        },
                      );
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                ),
                onChanged: context.read<SearchCubit>().onQueryChanged,
                onSubmitted: context.read<SearchCubit>().submit,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state.query.trim().isEmpty) {
                  return _RecentSearches(queries: state.recentQueries);
                }
                if (state.status == SearchStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == SearchStatus.failure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(state.errorMessage ?? '搜索失败'),
                    ),
                  );
                }
                final results = state.results;
                if (results.isEmpty) {
                  return const Center(child: Text('没有找到结果'));
                }
                // Phase 4: Build flat widget list for staggered animation
                final items = <Widget>[];
                if (results.tracks.isNotEmpty) {
                  items.add(
                    const SectionHeader(
                      title: '曲目',
                      padding: EdgeInsets.only(bottom: 8, top: 6),
                      bold: false,
                    ),
                  );
                  for (var i = 0; i < results.tracks.length; i++) {
                    items.add(
                      MusicTrackTile.list(
                        artworkUrl: results.tracks[i].artworkUrl,
                        title: results.tracks[i].title,
                        subtitle:
                            '${results.tracks[i].artistName} · ${results.tracks[i].albumTitle}',
                        onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                          context,
                          tracks: results.tracks,
                          startIndex: i,
                        ),
                      ),
                    );
                  }
                  items.add(const SizedBox(height: 18));
                }
                if (results.albums.isNotEmpty) {
                  items.add(
                    const SectionHeader(
                      title: '专辑',
                      padding: EdgeInsets.only(bottom: 8, top: 6),
                      bold: false,
                    ),
                  );
                  for (final album in results.albums) {
                    items.add(_AlbumRow(album: album));
                  }
                  items.add(const SizedBox(height: 18));
                }
                if (results.artists.isNotEmpty) {
                  items.add(
                    const SectionHeader(
                      title: '艺术家',
                      padding: EdgeInsets.only(bottom: 8, top: 6),
                      bold: false,
                    ),
                  );
                  for (final artist in results.artists) {
                    items.add(_ArtistRow(artist: artist));
                  }
                  items.add(const SizedBox(height: 18));
                }
                if (results.playlists.isNotEmpty) {
                  items.add(
                    const SectionHeader(
                      title: '歌单',
                      padding: EdgeInsets.only(bottom: 8, top: 6),
                      bold: false,
                    ),
                  );
                  for (final p in results.playlists) {
                    items.add(_PlaylistRow(playlist: p));
                  }
                }
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    AppPageLayout.contentBottomInset,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    // Staggered slide-in animation: 50ms delay per item
                    return _StaggeredSlideIn(index: index, child: items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.queries});

  final List<String> queries;

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) {
      return const Center(child: Text('输入关键词开始搜索'));
    }
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppPageLayout.contentBottomInset,
      ),
      children: [
        Row(
          children: [
            Text('最近搜索', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () => context.read<SearchCubit>().clearRecent(),
              child: const Text('清空'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in queries)
              // Phase 4: Recent search tag with hover Primary background
              ActionChip(
                label: Text(q),
                backgroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                onPressed: () => context.read<SearchCubit>().submit(q),
              ),
          ],
        ),
      ],
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.album});

  final MusicAlbum album;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedArtwork(
        imageUrl: album.artworkUrl,
        size: 48,
        borderRadius: 14,
      ),
      title: Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        album.artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.push('/album/${album.id}', extra: album),
    );
  }
}

class _ArtistRow extends StatelessWidget {
  const _ArtistRow({required this.artist});

  final MusicArtist artist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedArtwork(
        imageUrl: artist.artworkUrl,
        size: 48,
        borderRadius: 24,
      ),
      title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => context.push('/artist/${artist.id}', extra: artist),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({required this.playlist});

  final MusicPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedArtwork(
        imageUrl: playlist.artworkUrl,
        size: 48,
        borderRadius: 14,
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${playlist.trackCount} 首'),
      onTap: () => context.push('/playlists/${playlist.id}', extra: playlist),
    );
  }
}

// Phase 4: Staggered slide-in animation for search results (50ms/item)
class _StaggeredSlideIn extends StatefulWidget {
  const _StaggeredSlideIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredSlideIn> createState() => _StaggeredSlideInState();
}

class _StaggeredSlideInState extends State<_StaggeredSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    // Stagger: 50ms delay per item, max 500ms total delay
    final delay = Duration(milliseconds: (widget.index * 50).clamp(0, 500));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

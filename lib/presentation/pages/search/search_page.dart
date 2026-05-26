import 'dart:math' as math;

import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/search/search_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/search/search_state.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
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
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _submitQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (_controller.text != trimmed) {
      _controller.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }
    context.read<SearchCubit>().submit(trimmed);
  }

  void _clearQuery() {
    _controller.clear();
    context.read<SearchCubit>().onQueryChanged('');
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
    return Scaffold(
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          return AppContentPage(
            header: _SearchHeader(
              controller: _controller,
              focusNode: _focusNode,
              focused: _focused,
              resultCount: state.query.trim().isEmpty || state.results.isEmpty
                  ? null
                  : state.results.totalCount,
              onClear: _clearQuery,
              onSubmitted: _submitQuery,
            ),
            body: _SearchResultsView(
              state: state,
              onRecentSelected: _submitQuery,
            ),
          );
        },
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.resultCount,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final int? resultCount;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (canPop) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: '返回',
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: AppPageTitleRow(
                title: '搜索',
                description: '查找曲目、专辑、艺术家和歌单',
                badge: resultCount == null
                    ? null
                    : MetaPill(
                        label: '$resultCount 项',
                        size: MetaPillSize.compact,
                      ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacingTokens.headerBottomGap),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: AnimatedScale(
            scale: focused ? 1.01 : 1.0,
            duration: AppMotion.micro,
            curve: AppMotion.enter,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜索曲目 / 专辑 / 艺术家 / 歌单',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: '清空搜索',
                      onPressed: onClear,
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadiusTokens.input),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
              ),
              onChanged: context.read<SearchCubit>().onQueryChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.state,
    required this.onRecentSelected,
  });

  final SearchState state;
  final ValueChanged<String> onRecentSelected;

  @override
  Widget build(BuildContext context) {
    if (state.query.trim().isEmpty) {
      return _RecentSearches(
        queries: state.recentQueries,
        onSelected: onRecentSelected,
      );
    }

    if (state.status == SearchStatus.loading) {
      return const AppBodyStateView.loading();
    }

    if (state.status == SearchStatus.failure) {
      return AppBodyStateView.message(
        message: state.errorMessage ?? '搜索失败',
        action: FilledButton.tonalIcon(
          onPressed: context.read<SearchCubit>().retry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重试'),
        ),
      );
    }

    if (state.results.isEmpty) {
      return const AppBodyStateView.message(message: '没有找到结果，换个关键词试试。');
    }

    return _SearchResultsContent(results: state.results);
  }
}

class _SearchResultsContent extends StatelessWidget {
  const _SearchResultsContent({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.usesWideContentWidth(
          constraints.maxWidth,
        );
        final content = isWide
            ? _WideSearchResults(results: results)
            : _CompactSearchResults(results: results);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            AppPageLayout.contentBottomInset,
          ),
          child: content,
        );
      },
    );
  }
}

class _CompactSearchResults extends StatelessWidget {
  const _CompactSearchResults({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (results.tracks.isNotEmpty)
          _TrackSection(
            tracks: results.tracks,
            style: MusicTrackTileStyle.card,
          ),
        if (results.albums.isNotEmpty)
          _EntitySection(
            title: '专辑',
            countLabel: '${results.albums.length} 张',
            children: [
              for (final album in results.albums) _AlbumResultRow(album: album),
            ],
          ),
        if (results.artists.isNotEmpty)
          _EntitySection(
            title: '艺术家',
            countLabel: '${results.artists.length} 位',
            children: [
              for (final artist in results.artists)
                _ArtistResultRow(artist: artist),
            ],
          ),
        if (results.playlists.isNotEmpty)
          _EntitySection(
            title: '歌单',
            countLabel: '${results.playlists.length} 个',
            children: [
              for (final playlist in results.playlists)
                _PlaylistResultRow(playlist: playlist),
            ],
          ),
      ],
    );
  }
}

class _WideSearchResults extends StatelessWidget {
  const _WideSearchResults({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    final hasTracks = results.tracks.isNotEmpty;
    final hasEntities =
        results.albums.isNotEmpty ||
        results.artists.isNotEmpty ||
        results.playlists.isNotEmpty;

    if (hasTracks && hasEntities) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: _TrackSection(
              tracks: results.tracks,
              style: MusicTrackTileStyle.row,
            ),
          ),
          const SizedBox(width: AppSpacingTokens.sectionGap),
          Expanded(flex: 5, child: _EntityColumn(results: results)),
        ],
      );
    }

    if (hasTracks) {
      return _TrackSection(
        tracks: results.tracks,
        style: MusicTrackTileStyle.row,
      );
    }

    return _EntityColumn(results: results, fullWidth: true);
  }
}

class _EntityColumn extends StatelessWidget {
  const _EntityColumn({required this.results, this.fullWidth = false});

  final SearchResults results;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final albums = results.albums;
    final artists = results.artists;
    final playlists = results.playlists;

    return Column(
      children: [
        if (albums.isNotEmpty)
          _EntitySection(
            title: '专辑',
            countLabel: '${albums.length} 张',
            grid: fullWidth,
            children: [
              for (final album in albums) _AlbumResultRow(album: album),
            ],
          ),
        if (artists.isNotEmpty)
          _EntitySection(
            title: '艺术家',
            countLabel: '${artists.length} 位',
            grid: fullWidth,
            children: [
              for (final artist in artists) _ArtistResultRow(artist: artist),
            ],
          ),
        if (playlists.isNotEmpty)
          _EntitySection(
            title: '歌单',
            countLabel: '${playlists.length} 个',
            grid: fullWidth,
            children: [
              for (final playlist in playlists)
                _PlaylistResultRow(playlist: playlist),
            ],
          ),
      ],
    );
  }
}

class _TrackSection extends StatelessWidget {
  const _TrackSection({required this.tracks, required this.style});

  final List<MusicTrack> tracks;
  final MusicTrackTileStyle style;

  @override
  Widget build(BuildContext context) {
    return _EntitySection(
      title: '曲目',
      countLabel: '${tracks.length} 首',
      children: [
        for (var i = 0; i < tracks.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == tracks.length - 1 ? 0 : 10),
            child: style == MusicTrackTileStyle.card
                ? MusicTrackTile.card(
                    artworkUrl: tracks[i].artworkUrl,
                    title: tracks[i].title,
                    subtitle:
                        '${tracks[i].artistName} · ${tracks[i].albumTitle}',
                    isCurrent: false,
                    onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: tracks,
                      startIndex: i,
                    ),
                  )
                : MusicTrackTile.row(
                    artworkUrl: tracks[i].artworkUrl,
                    title: tracks[i].title,
                    subtitle:
                        '${tracks[i].artistName} · ${tracks[i].albumTitle}',
                    isCurrent: false,
                    onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: tracks,
                      startIndex: i,
                    ),
                  ),
          ),
      ],
    );
  }
}

class _EntitySection extends StatelessWidget {
  const _EntitySection({
    required this.title,
    required this.countLabel,
    required this.children,
    this.grid = false,
  });

  final String title;
  final String countLabel;
  final List<Widget> children;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacingTokens.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitleRow(
            title: title,
            badge: MetaPill(label: countLabel, size: MetaPillSize.compact),
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            titleStyle: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (grid)
            LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = math.max(
                  1,
                  math.min(3, (constraints.maxWidth / 320).floor()),
                );
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final child in children)
                      SizedBox(
                        width:
                            (constraints.maxWidth - 12 * (columnCount - 1)) /
                            columnCount,
                        child: child,
                      ),
                  ],
                );
              },
            )
          else
            Column(
              children: [
                for (var i = 0; i < children.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == children.length - 1 ? 0 : 10,
                    ),
                    child: children[i],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.queries, required this.onSelected});

  final List<String> queries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) {
      return const AppBodyStateView.message(message: '输入关键词开始搜索');
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
        AppSectionTitleRow(
          title: '最近搜索',
          padding: EdgeInsets.zero,
          titleStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          action: TextButton(
            onPressed: () => context.read<SearchCubit>().clearRecent(),
            child: const Text('清空'),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final query in queries)
              ActionChip(
                label: Text(query),
                backgroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                onPressed: () => onSelected(query),
              ),
          ],
        ),
      ],
    );
  }
}

class _AlbumResultRow extends StatelessWidget {
  const _AlbumResultRow({required this.album});

  final MusicAlbum album;

  @override
  Widget build(BuildContext context) {
    final meta = [
      album.artistName,
      if (album.year != null) '${album.year}',
      '${album.trackCount} 首',
    ].join(' · ');

    return _SearchEntityRow(
      title: album.title,
      subtitle: meta,
      artworkUrl: album.artworkUrl,
      artworkRadius: 14,
      semanticLabel: '打开专辑《${album.title}》',
      artworkSemanticLabel: '《${album.title}》专辑封面',
      onTap: () => context.go('/album/${album.id}', extra: album),
    );
  }
}

class _ArtistResultRow extends StatelessWidget {
  const _ArtistResultRow({required this.artist});

  final MusicArtist artist;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (artist.albumCount > 0) '${artist.albumCount} 张专辑',
      if (artist.trackCount > 0) '${artist.trackCount} 首歌曲',
    ];

    return _SearchEntityRow(
      title: artist.name,
      subtitle: meta.isEmpty ? '艺术家' : meta.join(' · '),
      artworkUrl: artist.artworkUrl,
      artworkRadius: 24,
      semanticLabel: '打开艺术家《${artist.name}》',
      artworkSemanticLabel: '${artist.name} 头像',
      onTap: () => context.push('/artist/${artist.id}', extra: artist),
    );
  }
}

class _PlaylistResultRow extends StatelessWidget {
  const _PlaylistResultRow({required this.playlist});

  final MusicPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    return _SearchEntityRow(
      title: playlist.name,
      subtitle: '${playlist.trackCount} 首歌曲',
      artworkUrl: playlist.artworkUrl,
      artworkRadius: 14,
      semanticLabel: '打开歌单《${playlist.name}》',
      artworkSemanticLabel: '${playlist.name} 歌单封面',
      onTap: () => context.push('/playlists/${playlist.id}', extra: playlist),
    );
  }
}

class _SearchEntityRow extends StatefulWidget {
  const _SearchEntityRow({
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.artworkRadius,
    required this.semanticLabel,
    required this.artworkSemanticLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String artworkUrl;
  final double artworkRadius;
  final String semanticLabel;
  final String artworkSemanticLabel;
  final VoidCallback onTap;

  @override
  State<_SearchEntityRow> createState() => _SearchEntityRowState();
}

class _SearchEntityRowState extends State<_SearchEntityRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(
              alpha: _hovered ? 0.82 : 0.62,
            ),
            borderRadius: BorderRadius.circular(AppRadiusTokens.card),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.card),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    CachedArtwork(
                      imageUrl: widget.artworkUrl,
                      size: 48,
                      borderRadius: widget.artworkRadius,
                      semanticLabel: widget.artworkSemanticLabel,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
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

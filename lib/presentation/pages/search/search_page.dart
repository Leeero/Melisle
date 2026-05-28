import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/search/search_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/search/search_state.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_scope_tabs.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_artist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum _SearchScope { all, tracks, albums, artists, playlists }

const _visibleSearchScopes = [
  _SearchScope.tracks,
  _SearchScope.albums,
  _SearchScope.artists,
  _SearchScope.playlists,
];

extension _SearchScopeInfo on _SearchScope {
  String get label {
    return switch (this) {
      _SearchScope.all => '全部',
      _SearchScope.tracks => '歌曲',
      _SearchScope.albums => '专辑',
      _SearchScope.artists => '艺术家',
      _SearchScope.playlists => '歌单',
    };
  }

  IconData get icon {
    return switch (this) {
      _SearchScope.all => Icons.grid_view_rounded,
      _SearchScope.tracks => Icons.music_note_rounded,
      _SearchScope.albums => Icons.album_rounded,
      _SearchScope.artists => Icons.person_rounded,
      _SearchScope.playlists => Icons.queue_music_rounded,
    };
  }

  int count(SearchResults results) {
    return switch (this) {
      _SearchScope.all => results.totalCount,
      _SearchScope.tracks => results.tracks.length,
      _SearchScope.albums => results.albums.length,
      _SearchScope.artists => results.artists.length,
      _SearchScope.playlists => results.playlists.length,
    };
  }

  SearchResults apply(SearchResults results) {
    return switch (this) {
      _SearchScope.all => results,
      _SearchScope.tracks => SearchResults(tracks: results.tracks),
      _SearchScope.albums => SearchResults(albums: results.albums),
      _SearchScope.artists => SearchResults(artists: results.artists),
      _SearchScope.playlists => SearchResults(playlists: results.playlists),
    };
  }
}

List<AppScopeTabItem<_SearchScope>> _searchScopeItems(
  SearchResults results, {
  bool withIcons = true,
}) {
  return [
    for (final scope in _visibleSearchScopes)
      AppScopeTabItem(
        value: scope,
        label: scope.label,
        count: scope.count(results),
        icon: withIcons ? scope.icon : null,
        semanticLabel: '查看${scope.label}结果',
      ),
  ];
}

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
  _SearchScope _selectedScope = _SearchScope.tracks;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onQueryChanged(String query) {
    if (_selectedScope != _SearchScope.tracks) {
      setState(() => _selectedScope = _SearchScope.tracks);
    }
    context.read<SearchCubit>().onQueryChanged(query);
  }

  void _submitQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (_selectedScope != _SearchScope.tracks) {
      setState(() => _selectedScope = _SearchScope.tracks);
    }
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
    setState(() => _selectedScope = _SearchScope.tracks);
    context.read<SearchCubit>().onQueryChanged('');
  }

  @override
  void dispose() {
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
              resultCount: state.query.trim().isEmpty || state.results.isEmpty
                  ? null
                  : state.results.totalCount,
              onClear: _clearQuery,
              onChanged: _onQueryChanged,
              onSubmitted: _submitQuery,
            ),
            body: _SearchResultsView(
              state: state,
              selectedScope: _selectedScope,
              onScopeChanged: (scope) => setState(() {
                _selectedScope = scope;
              }),
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
    required this.resultCount,
    required this.onClear,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int? resultCount;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth >= 1180 ? 620.0 : 520.0;

        return AppPageHeader(
          title: '搜索',
          description: '查找歌曲、专辑、艺术家和歌单',
          centerWidth: searchWidth,
          center: AppSearchField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            dense: true,
            hintText: '搜索音乐库',
            semanticLabel: '搜索音乐库',
            onClear: onClear,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
          trailing: resultCount == null
              ? null
              : MetaPill(label: '$resultCount 项', size: MetaPillSize.compact),
        );
      },
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.state,
    required this.selectedScope,
    required this.onScopeChanged,
    required this.onRecentSelected,
  });

  final SearchState state;
  final _SearchScope selectedScope;
  final ValueChanged<_SearchScope> onScopeChanged;
  final ValueChanged<String> onRecentSelected;

  @override
  Widget build(BuildContext context) {
    if (state.query.trim().isEmpty) {
      return _SearchStartView(
        queries: state.recentQueries,
        onSelected: onRecentSelected,
      );
    }

    if (state.status == SearchStatus.loading) {
      if (state.results.isNotEmpty) {
        return _SearchResultsContent(
          query: state.query.trim(),
          results: state.results,
          selectedScope: selectedScope,
          onScopeChanged: onScopeChanged,
          isLoading: true,
        );
      }
      return const _SearchLoadingState();
    }

    if (state.status == SearchStatus.failure) {
      return _SearchFailureState(onRetry: context.read<SearchCubit>().retry);
    }

    if (state.results.isEmpty) {
      return _SearchNoResultsState(
        query: state.query.trim(),
        recentQueries: state.recentQueries,
        onSelected: onRecentSelected,
      );
    }

    return _SearchResultsContent(
      query: state.query.trim(),
      results: state.results,
      selectedScope: selectedScope,
      onScopeChanged: onScopeChanged,
    );
  }
}

class _SearchResultsContent extends StatelessWidget {
  const _SearchResultsContent({
    required this.query,
    required this.results,
    required this.selectedScope,
    required this.onScopeChanged,
    this.isLoading = false,
  });

  final String query;
  final SearchResults results;
  final _SearchScope selectedScope;
  final ValueChanged<_SearchScope> onScopeChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;
        if (!isWide) {
          return _CompactSearchResults(
            results: results,
            selectedScope: selectedScope,
            onScopeChanged: onScopeChanged,
            isLoading: isLoading,
            horizontalPadding: horizontalPadding,
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            AppPageLayout.contentBottomInset,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesktopSearchOverview(query: query, results: results),
                  const SizedBox(height: 18),
                  AppScopeTabs<_SearchScope>(
                    semanticLabel: '搜索结果分类',
                    variant: AppScopeTabsVariant.underline,
                    items: _searchScopeItems(results, withIcons: false),
                    selectedValue: selectedScope,
                    onChanged: onScopeChanged,
                  ),
                  const SizedBox(height: 18),
                  if (isLoading) const _SearchLoadingBanner(),
                  if (selectedScope.apply(results).isEmpty)
                    _ScopedNoResults(selectedScope: selectedScope)
                  else
                    _WideSearchResults(results: selectedScope.apply(results)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DesktopSearchOverview extends StatelessWidget {
  const _DesktopSearchOverview({required this.query, required this.results});

  final String query;
  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topMatch = _topMatchLabel(results);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    const TextSpan(text: '搜索 '),
                    TextSpan(
                      text: query,
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetaPill(
                    label: '共 ${results.totalCount} 项结果',
                    size: MetaPillSize.compact,
                  ),
                  if (topMatch != null)
                    MetaPill(label: topMatch, size: MetaPillSize.compact),
                ],
              ),
            ],
          ),
        ),
        Text(
          _resultSummary(results),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String? _topMatchLabel(SearchResults results) {
    if (results.artists.isNotEmpty) {
      return '最佳匹配：${results.artists.first.name}';
    }
    if (results.albums.isNotEmpty) {
      return '最佳匹配：${results.albums.first.title}';
    }
    if (results.tracks.isNotEmpty) {
      return '最佳匹配：${results.tracks.first.title}';
    }
    return null;
  }

  String _resultSummary(SearchResults results) {
    return '${results.tracks.length} 首歌曲 · ${results.albums.length} 张专辑 · '
        '${results.artists.length} 位艺术家 · ${results.playlists.length} 个歌单';
  }
}

class _ScopedNoResults extends StatelessWidget {
  const _ScopedNoResults({required this.selectedScope});

  final _SearchScope selectedScope;

  @override
  Widget build(BuildContext context) {
    return _SearchMessagePanel(
      icon: selectedScope.icon,
      title: '这次没有匹配的${selectedScope.label}',
      message: '可以切换其他分类，或换个关键词再试。',
    );
  }
}

class _SearchFailureState extends StatelessWidget {
  const _SearchFailureState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SearchStateScrollView(
      child: _SearchMessagePanel(
        icon: Icons.wifi_off_rounded,
        title: '服务器暂时没有响应',
        message: '请检查连接状态，然后重试搜索。',
        action: AppActionButton(
          onPressed: onRetry,
          icon: Icons.refresh_rounded,
          label: '重试',
          tone: AppActionButtonTone.primary,
        ),
      ),
    );
  }
}

class _SearchNoResultsState extends StatelessWidget {
  const _SearchNoResultsState({
    required this.query,
    required this.recentQueries,
    required this.onSelected,
  });

  final String query;
  final List<String> recentQueries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SearchStateScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchMessagePanel(
            icon: Icons.manage_search_rounded,
            title: '没有找到结果，换个关键词试试。',
            message: query.isEmpty
                ? '检查拼写，或试试艺术家 / 专辑名。'
                : '没有匹配“$query”的内容。检查拼写，或试试艺术家 / 专辑名。',
          ),
          if (recentQueries.isNotEmpty) ...[
            const SizedBox(height: AppSpacingTokens.sectionGap),
            _RecentSearchSection(
              queries: recentQueries,
              onSelected: onSelected,
              showClearAction: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppPageLayout.contentBottomInset,
      ),
      children: const [
        _SearchLoadingBanner(),
        _SearchSkeletonRow(),
        SizedBox(height: 10),
        _SearchSkeletonRow(),
        SizedBox(height: 10),
        _SearchSkeletonRow(),
      ],
    );
  }
}

class _SearchLoadingBanner extends StatelessWidget {
  const _SearchLoadingBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadiusTokens.iconButton),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.64),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '正在搜索…',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchSkeletonRow extends StatelessWidget {
  const _SearchSkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.66,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.42,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactSearchResults extends StatelessWidget {
  const _CompactSearchResults({
    required this.results,
    required this.selectedScope,
    required this.onScopeChanged,
    required this.horizontalPadding,
    this.isLoading = false,
  });

  final SearchResults results;
  final _SearchScope selectedScope;
  final ValueChanged<_SearchScope> onScopeChanged;
  final double horizontalPadding;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scopedResults = selectedScope.apply(results);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            14,
          ),
          sliver: SliverToBoxAdapter(
            child: AppScopeTabs<_SearchScope>(
              semanticLabel: '搜索结果分类',
              variant: AppScopeTabsVariant.pill,
              items: _searchScopeItems(results),
              selectedValue: selectedScope,
              onChanged: onScopeChanged,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (isLoading) const _SearchLoadingBanner(),
              if (scopedResults.isEmpty)
                _ScopedNoResults(selectedScope: selectedScope),
              if (scopedResults.tracks.isNotEmpty)
                _SectionHeader(
                  title: '歌曲',
                  countLabel: '${scopedResults.tracks.length} 首',
                ),
            ]),
          ),
        ),
        if (scopedResults.tracks.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              0,
            ),
            sliver: SliverList.separated(
              itemCount: scopedResults.tracks.length,
              itemBuilder: (context, index) {
                final track = scopedResults.tracks[index];
                return MusicTrackTile.card(
                  artworkUrl: track.artworkUrl,
                  title: track.title,
                  subtitle: '${track.artistName} · ${track.albumTitle}',
                  isCurrent: false,
                  onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                    context,
                    tracks: scopedResults.tracks,
                    startIndex: index,
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
            ),
          ),
        if (scopedResults.tracks.isNotEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacingTokens.sectionGap),
          ),
        _CompactAlbumGrid(
          albums: scopedResults.albums,
          horizontalPadding: horizontalPadding,
        ),
        _CompactArtistGrid(
          artists: scopedResults.artists,
          horizontalPadding: horizontalPadding,
        ),
        _CompactEntitySection(
          title: '歌单',
          countLabel: '${scopedResults.playlists.length} 个',
          itemCount: scopedResults.playlists.length,
          horizontalPadding: horizontalPadding,
          itemBuilder: (context, index) =>
              _PlaylistResultRow(playlist: scopedResults.playlists[index]),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppPageLayout.contentBottomInset),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.countLabel,
    this.dense = false,
  });

  final String title;
  final String countLabel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppSectionTitleRow(
      title: title,
      badge: MetaPill(label: countLabel, size: MetaPillSize.compact),
      padding: EdgeInsets.only(bottom: dense ? 8 : 10, top: dense ? 0 : 4),
      titleStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _CompactEntitySection extends StatelessWidget {
  const _CompactEntitySection({
    required this.title,
    required this.countLabel,
    required this.itemCount,
    required this.horizontalPadding,
    required this.itemBuilder,
  });

  final String title;
  final String countLabel;
  final int itemCount;
  final double horizontalPadding;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(title: title, countLabel: countLabel),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacingTokens.sectionGap),
        ),
      ],
    );
  }
}

class _CompactAlbumGrid extends StatelessWidget {
  const _CompactAlbumGrid({
    required this.albums,
    required this.horizontalPadding,
  });

  final List<MusicAlbum> albums;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 380;

    if (isNarrow) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          AppSpacingTokens.sectionGap,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final album = albums[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CachedArtwork(
                  imageUrl: album.artworkUrl,
                  size: 48,
                  borderRadius: 14,
                  semanticLabel: '《${album.title}》专辑封面',
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
          }, childCount: albums.length),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacingTokens.sectionGap,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final album = albums[index];
          return MusicAlbumGridCard(
            album: album,
            onTap: () => context.push('/album/${album.id}', extra: album),
          );
        }, childCount: albums.length),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: AppBreakpoints.adaptiveAlbumGridCount(screenWidth),
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }
}

class _CompactArtistGrid extends StatelessWidget {
  const _CompactArtistGrid({
    required this.artists,
    required this.horizontalPadding,
  });

  final List<MusicArtist> artists;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final screenWidth = MediaQuery.sizeOf(context).width;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacingTokens.sectionGap,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final artist = artists[index];
          return MusicArtistGridCard(
            artist: artist,
            onTap: () => context.push('/artist/${artist.id}', extra: artist),
          );
        }, childCount: artists.length),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _artistGridCount(screenWidth),
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: 0.7,
        ),
      ),
    );
  }
}

class _WideSearchResults extends StatelessWidget {
  const _WideSearchResults({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    final hasTracks = results.tracks.isNotEmpty;
    final hasOnlyAlbums =
        results.albums.isNotEmpty &&
        !hasTracks &&
        results.artists.isEmpty &&
        results.playlists.isEmpty;
    final hasOnlyArtists =
        results.artists.isNotEmpty &&
        !hasTracks &&
        results.albums.isEmpty &&
        results.playlists.isEmpty;
    final hasEntities =
        results.albums.isNotEmpty ||
        results.artists.isNotEmpty ||
        results.playlists.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (hasOnlyAlbums) {
          return _SearchAlbumGrid(albums: results.albums);
        }

        if (hasOnlyArtists) {
          return _SearchArtistGrid(artists: results.artists);
        }

        if (hasTracks && hasEntities) {
          final sidebarWidth = constraints.maxWidth >= 1180 ? 360.0 : 320.0;
          const gap = 30.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TrackSection(
                  tracks: results.tracks,
                  style: MusicTrackTileStyle.row,
                  dense: true,
                ),
              ),
              const SizedBox(width: gap),
              SizedBox(
                width: sidebarWidth,
                child: _EntityColumn(results: results, dense: true),
              ),
            ],
          );
        }

        if (hasTracks) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: _TrackSection(
              tracks: results.tracks,
              style: MusicTrackTileStyle.row,
              dense: true,
            ),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: _EntityColumn(results: results, fullWidth: true),
        );
      },
    );
  }
}

class _SearchAlbumGrid extends StatelessWidget {
  const _SearchAlbumGrid({required this.albums});

  final List<MusicAlbum> albums;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: albums.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppBreakpoints.adaptiveAlbumGridCount(
          MediaQuery.sizeOf(context).width,
        ),
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final album = albums[index];
        return MusicAlbumGridCard(
          album: album,
          onTap: () => context.push('/album/${album.id}', extra: album),
        );
      },
    );
  }
}

class _SearchArtistGrid extends StatelessWidget {
  const _SearchArtistGrid({required this.artists});

  final List<MusicArtist> artists;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artists.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _artistGridCount(MediaQuery.sizeOf(context).width),
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return MusicArtistGridCard(
          artist: artist,
          onTap: () => context.push('/artist/${artist.id}', extra: artist),
        );
      },
    );
  }
}

class _EntityColumn extends StatelessWidget {
  const _EntityColumn({
    required this.results,
    this.fullWidth = false,
    this.dense = false,
  });

  final SearchResults results;
  final bool fullWidth;
  final bool dense;

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
            dense: dense,
            children: [
              for (final album in albums)
                _AlbumResultRow(album: album, dense: dense),
            ],
          ),
        if (artists.isNotEmpty)
          _EntitySection(
            title: '艺术家',
            countLabel: '${artists.length} 位',
            grid: fullWidth,
            dense: dense,
            children: [
              for (final artist in artists)
                _ArtistResultRow(artist: artist, dense: dense),
            ],
          ),
        if (playlists.isNotEmpty)
          _EntitySection(
            title: '歌单',
            countLabel: '${playlists.length} 个',
            grid: fullWidth,
            dense: dense,
            children: [
              for (final playlist in playlists)
                _PlaylistResultRow(playlist: playlist, dense: dense),
            ],
          ),
      ],
    );
  }
}

class _TrackSection extends StatelessWidget {
  const _TrackSection({
    required this.tracks,
    required this.style,
    this.dense = false,
  });

  final List<MusicTrack> tracks;
  final MusicTrackTileStyle style;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return MusicTrackTable(
        tracks: tracks,
        onTrackTap: (index, _) => unawaited(
          PlayerNavigation.playTracksAndOpenPlayer(
            context,
            tracks: tracks,
            startIndex: index,
          ),
        ),
        onPlayAll: tracks.isEmpty
            ? null
            : () => unawaited(
                PlayerNavigation.playTracksAndOpenPlayer(
                  context,
                  tracks: tracks,
                  startIndex: 0,
                ),
              ),
        onAddAllToQueue: tracks.isEmpty
            ? null
            : () => unawaited(_addTracksToQueue(context, tracks)),
        onAddTrackToQueue: (track) =>
            unawaited(_addTracksToQueue(context, [track])),
      );
    }

    return _EntitySection(
      title: '歌曲',
      countLabel: '${tracks.length} 首',
      children: [
        for (var i = 0; i < tracks.length; i++)
          style == MusicTrackTileStyle.card
              ? MusicTrackTile.card(
                  artworkUrl: tracks[i].artworkUrl,
                  title: tracks[i].title,
                  subtitle: '${tracks[i].artistName} · ${tracks[i].albumTitle}',
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
                  subtitle: '${tracks[i].artistName} · ${tracks[i].albumTitle}',
                  isCurrent: false,
                  onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                    context,
                    tracks: tracks,
                    startIndex: i,
                  ),
                ),
      ],
    );
  }
}

Future<void> _addTracksToQueue(
  BuildContext context,
  List<MusicTrack> tracks,
) async {
  if (tracks.isEmpty) return;
  final player = context.read<PlayerCubit>();
  for (final track in tracks) {
    await player.addToQueue(track);
  }
  if (!context.mounted) return;
  final message = tracks.length == 1
      ? '已加入队列：${tracks.first.title}'
      : '已加入队列：${tracks.length} 首歌曲';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

int _artistGridCount(double width) {
  if (width >= 1200) return 8;
  if (width >= 900) return 6;
  if (width >= 600) return 4;
  return 3;
}

class _EntitySection extends StatelessWidget {
  const _EntitySection({
    required this.title,
    required this.countLabel,
    required this.children,
    this.grid = false,
    this.dense = false,
  });

  final String title;
  final String countLabel;
  final List<Widget> children;
  final bool grid;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        bottom: dense ? 18 : AppSpacingTokens.sectionGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, countLabel: countLabel, dense: dense),
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
                      bottom: i == children.length - 1
                          ? 0
                          : dense
                          ? 8
                          : 10,
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

class _SearchStartView extends StatelessWidget {
  const _SearchStartView({required this.queries, required this.onSelected});

  final List<String> queries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SearchStateScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchMessagePanel(
            icon: Icons.search_rounded,
            title: '输入关键词开始搜索',
            message: '可以搜索歌曲、专辑、艺术家和歌单。',
          ),
          const SizedBox(height: AppSpacingTokens.sectionGap),
          if (queries.isNotEmpty)
            _RecentSearchSection(queries: queries, onSelected: onSelected)
          else
            _SearchExampleSection(onSelected: onSelected),
        ],
      ),
    );
  }
}

class _SearchExampleSection extends StatelessWidget {
  const _SearchExampleSection({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const examples = ['夜曲', '十一月的萧邦', '周杰伦', '私人雷达'];

    return _SearchChipSection(
      title: '可以试试',
      action: null,
      children: [
        for (final query in examples)
          ActionChip(
            avatar: const Icon(Icons.north_east_rounded, size: 16),
            label: Text(query),
            onPressed: () => onSelected(query),
          ),
      ],
    );
  }
}

class _RecentSearchSection extends StatelessWidget {
  const _RecentSearchSection({
    required this.queries,
    required this.onSelected,
    this.showClearAction = true,
  });

  final List<String> queries;
  final ValueChanged<String> onSelected;
  final bool showClearAction;

  @override
  Widget build(BuildContext context) {
    return _SearchChipSection(
      title: '最近搜索',
      action: showClearAction
          ? TextButton.icon(
              onPressed: () {
                final previousQueries = List<String>.of(queries);
                final cubit = context.read<SearchCubit>();
                unawaited(cubit.clearRecent());
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text('已清空最近搜索'),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: '撤销',
                        onPressed: () =>
                            unawaited(cubit.restoreRecent(previousQueries)),
                      ),
                    ),
                  );
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('清空'),
            )
          : null,
      children: [
        for (final query in queries)
          ActionChip(
            avatar: const Icon(Icons.history_rounded, size: 16),
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
    );
  }
}

class _SearchChipSection extends StatelessWidget {
  const _SearchChipSection({
    required this.title,
    required this.children,
    this.action,
  });

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitleRow(
          title: title,
          padding: EdgeInsets.zero,
          titleStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          action: action,
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _SearchStateScrollView extends StatelessWidget {
  const _SearchStateScrollView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppPageLayout.contentBottomInset,
      ),
      children: [child],
    );
  }
}

class _SearchMessagePanel extends StatelessWidget {
  const _SearchMessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadiusTokens.input),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (action != null) ...[const SizedBox(height: 12), action!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumResultRow extends StatelessWidget {
  const _AlbumResultRow({required this.album, this.dense = false});

  final MusicAlbum album;
  final bool dense;

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
      dense: dense,
      onTap: () => context.go('/album/${album.id}', extra: album),
    );
  }
}

class _ArtistResultRow extends StatelessWidget {
  const _ArtistResultRow({required this.artist, this.dense = false});

  final MusicArtist artist;
  final bool dense;

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
      dense: dense,
      onTap: () => context.push('/artist/${artist.id}', extra: artist),
    );
  }
}

class _PlaylistResultRow extends StatelessWidget {
  const _PlaylistResultRow({required this.playlist, this.dense = false});

  final MusicPlaylist playlist;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return _SearchEntityRow(
      title: playlist.name,
      subtitle: '${playlist.trackCount} 首歌曲',
      artworkUrl: playlist.artworkUrl,
      artworkRadius: 14,
      semanticLabel: '打开歌单《${playlist.name}》',
      artworkSemanticLabel: '${playlist.name} 歌单封面',
      dense: dense,
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
    this.dense = false,
  });

  final String title;
  final String subtitle;
  final String artworkUrl;
  final double artworkRadius;
  final String semanticLabel;
  final String artworkSemanticLabel;
  final VoidCallback onTap;
  final bool dense;

  @override
  State<_SearchEntityRow> createState() => _SearchEntityRowState();
}

class _SearchEntityRowState extends State<_SearchEntityRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlighted = _hovered || _focused;
    final radius = widget.dense ? 16.0 : AppRadiusTokens.card;
    final artworkSize = widget.dense ? 44.0 : 48.0;
    final horizontalPadding = widget.dense ? 10.0 : 10.0;
    final verticalPadding = widget.dense ? 9.0 : 10.0;

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
              alpha: highlighted
                  ? widget.dense
                        ? 0.78
                        : 0.82
                  : widget.dense
                  ? 0.54
                  : 0.62,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _focused
                  ? colorScheme.primary.withValues(alpha: 0.56)
                  : colorScheme.outlineVariant.withValues(
                      alpha: widget.dense ? 0.68 : 0.72,
                    ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              focusColor: colorScheme.primary.withValues(alpha: 0.08),
              hoverColor: colorScheme.primary.withValues(alpha: 0.04),
              onFocusChange: (value) => setState(() => _focused = value),
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Row(
                  children: [
                    CachedArtwork(
                      imageUrl: widget.artworkUrl,
                      size: artworkSize,
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
                      size: widget.dense ? 20 : 24,
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

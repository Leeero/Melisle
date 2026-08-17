import 'dart:async';

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
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_artist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_playlist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/search/search_empty_view.dart';
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
    final normalized = query.length <= SearchCubit.maxQueryLength
        ? query
        : query.substring(0, SearchCubit.maxQueryLength);
    if (normalized != query) {
      _controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    context.read<SearchCubit>().onQueryChanged(normalized);
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
              onClear: _clearQuery,
              onChanged: _onQueryChanged,
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
    required this.onClear,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: '搜索',
          description: null,
          hideTitleOnCompactWithCenter: false,
        ),
        SizedBox(height: compact ? 12 : 18),
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: AppSearchField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  dense: true,
                  hintText: compact ? '搜索歌曲、专辑、艺人、歌单' : '搜索歌曲、专辑、艺人',
                  semanticLabel: '搜索音乐库',
                  showCancelAction: compact,
                  onClear: onClear,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  onCancel: () {
                    focusNode.unfocus();
                  },
                ),
              ),
            ),
          ],
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
      return _SearchStartView(
        queries: state.recentQueries,
        onSelected: onRecentSelected,
      );
    }

    if (state.status == SearchStatus.loading) {
      if (state.results.isNotEmpty) {
        return _SearchResultsContent(results: state.results, isLoading: true);
      }
      return const _SearchLoadingState();
    }

    if (state.status == SearchStatus.input) {
      return _SearchStartView(
        queries: state.recentQueries,
        onSelected: onRecentSelected,
      );
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

    return _SearchResultsContent(results: state.results);
  }
}

class _SearchResultsContent extends StatelessWidget {
  const _SearchResultsContent({required this.results, this.isLoading = false});

  final SearchResults results;
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
                  if (isLoading) const _SearchLoadingBanner(),
                  _BestMatchSection(results: results),
                  _WideSearchResults(results: results),
                ],
              ),
            ),
          ),
        );
      },
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
            SearchChipGroup(
              title: '最近搜索',
              chips: [
                for (final query in recentQueries)
                  SearchSuggestionChip(
                    label: query,
                    icon: Icons.history_rounded,
                    onPressed: () => onSelected(query),
                  ),
              ],
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
    required this.horizontalPadding,
    this.isLoading = false,
  });

  final SearchResults results;
  final double horizontalPadding;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
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
              _BestMatchSection(results: results),
              if (results.tracks.isNotEmpty)
                _SectionHeader(
                  title: '歌曲',
                  countLabel: '${results.tracks.length} 首',
                ),
            ]),
          ),
        ),
        if (results.tracks.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              0,
            ),
            sliver: SliverList.separated(
              itemCount: results.tracks.length,
              itemBuilder: (context, index) {
                final track = results.tracks[index];
                return _CompactSearchTrackRow(
                  index: index,
                  track: track,
                  onTap: () => unawaited(
                    PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: results.tracks,
                      startIndex: index,
                    ),
                  ),
                  onAddToQueue: () =>
                      unawaited(_addTracksToQueue(context, [track])),
                );
              },
              separatorBuilder: (context, index) => const SizedBox.shrink(),
            ),
          ),
        if (results.tracks.isNotEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacingTokens.sectionGap),
          ),
        _CompactAlbumGrid(
          albums: results.albums,
          horizontalPadding: horizontalPadding,
          horizontal: true,
        ),
        _CompactArtistGrid(
          artists: results.artists,
          horizontalPadding: horizontalPadding,
        ),
        _CompactPlaylistSection(
          title: '歌单',
          countLabel: '${results.playlists.length} 个',
          playlists: results.playlists,
          horizontalPadding: horizontalPadding,
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppPageLayout.contentBottomInset),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.countLabel});

  final String title;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return AppSectionTitleRow(
      title: title,
      badge: MetaPill(label: countLabel, size: MetaPillSize.compact),
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      titleStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _TrackDurationLabel extends StatelessWidget {
  const _TrackDurationLabel({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Text(
        _formatDuration(duration),
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).muted,
          fontSize: 13,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _CompactSearchTrackRow extends StatefulWidget {
  const _CompactSearchTrackRow({
    required this.index,
    required this.track,
    required this.onTap,
    required this.onAddToQueue,
  });

  final int index;
  final MusicTrack track;
  final VoidCallback onTap;
  final VoidCallback onAddToQueue;

  @override
  State<_CompactSearchTrackRow> createState() => _CompactSearchTrackRowState();
}

class _CompactSearchTrackRowState extends State<_CompactSearchTrackRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final track = widget.track;

    return Semantics(
      label: '播放《${track.title}》',
      button: true,
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
            color: _pressed ? theme.hoverWash : Colors.transparent,
            borderRadius: _pressed
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${widget.index + 1}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.muted,
                          fontSize: 13,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${track.artistName} · ${track.albumTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _TrackDurationLabel(duration: track.duration),
                    const SizedBox(width: 2),
                    SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        onPressed: widget.onAddToQueue,
                        tooltip: '加入队列',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        icon: Icon(Icons.playlist_add_rounded, size: 20),
                        style: AppActionButtonStyle.icon(
                          context,
                          iconSize: 20,
                          radius: AppRadiusTokens.mobileSm,
                        ),
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

class _CompactAlbumGrid extends StatelessWidget {
  const _CompactAlbumGrid({
    required this.albums,
    required this.horizontalPadding,
    this.horizontal = false,
  });

  final List<MusicAlbum> albums;
  final double horizontalPadding;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 380;

    if (horizontal && !isNarrow) {
      return _CompactCardScroller(
        title: '专辑',
        countLabel: '${albums.length} 个结果',
        horizontalPadding: horizontalPadding,
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return SizedBox(
            width: 150,
            child: MusicAlbumGridCard(
              album: album,
              onTap: () => context.push('/album/${album.id}', extra: album),
            ),
          );
        },
      );
    }

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
          childAspectRatio: 0.67,
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
            child: _SectionHeader(
              title: '艺术家',
              countLabel: '${artists.length} 个结果',
            ),
          ),
        ),
        SliverPadding(
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
                onTap: () =>
                    context.push('/artist/${artist.id}', extra: artist),
              );
            }, childCount: artists.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _artistGridCount(screenWidth),
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.7,
            ),
          ),
        ),
      ],
    );
  }
}

class _BestMatchSection extends StatelessWidget {
  const _BestMatchSection({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    final artist = results.artists.firstOrNull;
    final album = results.albums.firstOrNull;
    final track = results.tracks.firstOrNull;
    final playlist = results.playlists.firstOrNull;
    if (artist == null && album == null && track == null && playlist == null) {
      return const SizedBox.shrink();
    }

    final String title;
    final String type;
    final String artworkUrl;
    final VoidCallback onTap;
    final bool playsTrack;
    if (artist != null) {
      title = artist.name;
      type = '艺术家';
      artworkUrl = artist.artworkUrl;
      onTap = () => context.push('/artist/${artist.id}', extra: artist);
      playsTrack = false;
    } else if (album != null) {
      title = album.title;
      type = '专辑';
      artworkUrl = album.artworkUrl;
      onTap = () => context.push('/album/${album.id}', extra: album);
      playsTrack = false;
    } else if (track != null) {
      title = track.title;
      type = '单曲';
      artworkUrl = track.artworkUrl;
      onTap = () => unawaited(
        PlayerNavigation.playTracksAndOpenPlayer(
          context,
          tracks: results.tracks,
          startIndex: 0,
        ),
      );
      playsTrack = true;
    } else {
      title = playlist!.name;
      type = '歌单';
      artworkUrl = playlist.artworkUrl;
      onTap = () => context.push('/playlists/${playlist.id}', extra: playlist);
      playsTrack = false;
    }

    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最佳匹配',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.42),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CachedArtwork(
                      imageUrl: artworkUrl,
                      size: 64,
                      borderRadius: artist != null ? 32 : 10,
                      semanticLabel: '$title封面',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      child: Icon(
                        playsTrack
                            ? Icons.play_arrow_rounded
                            : Icons.chevron_right_rounded,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideSearchResults extends StatelessWidget {
  const _WideSearchResults({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (results.tracks.isNotEmpty) ...[
          _TrackSection(tracks: results.tracks),
          const SizedBox(height: 26),
        ],
        if (results.albums.isNotEmpty)
          _SearchGridSection(
            title: '专辑',
            countLabel: '${results.albums.length} 个结果',
            child: _SearchAlbumGrid(albums: results.albums),
          ),
        if (results.artists.isNotEmpty)
          _SearchGridSection(
            title: '艺术家',
            countLabel: '${results.artists.length} 个结果',
            child: _SearchArtistGrid(artists: results.artists),
          ),
        if (results.playlists.isNotEmpty)
          _SearchGridSection(
            title: '歌单',
            countLabel: '${results.playlists.length} 个结果',
            child: _SearchPlaylistGrid(playlists: results.playlists),
          ),
      ],
    );
  }
}

class _SearchGridSection extends StatelessWidget {
  const _SearchGridSection({
    required this.title,
    required this.countLabel,
    required this.child,
  });

  final String title;
  final String countLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, countLabel: countLabel),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: child,
          ),
        ],
      ),
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
        crossAxisCount: _searchResultGridCount(
          MediaQuery.sizeOf(context).width,
        ),
        mainAxisSpacing: 22,
        crossAxisSpacing: 18,
        childAspectRatio: 0.67,
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
        crossAxisCount: _searchResultGridCount(
          MediaQuery.sizeOf(context).width,
        ),
        mainAxisSpacing: 22,
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

class _SearchPlaylistGrid extends StatelessWidget {
  const _SearchPlaylistGrid({required this.playlists});

  final List<MusicPlaylist> playlists;

  @override
  Widget build(BuildContext context) {
    final isCompact = AppBreakpoints.isCompact(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _searchResultGridCount(
          MediaQuery.sizeOf(context).width,
        ),
        mainAxisSpacing: 22,
        crossAxisSpacing: 18,
        childAspectRatio: 0.67,
      ),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return MusicPlaylistGridCard(
          playlist: playlist,
          onTap: () =>
              context.push('/playlists/${playlist.id}', extra: playlist),
          artworkRadius: isCompact
              ? AppRadiusTokens.mobileMd
              : AppRadiusTokens.coverGrid,
          compact: isCompact,
        );
      },
    );
  }
}

class _CompactPlaylistSection extends StatelessWidget {
  const _CompactPlaylistSection({
    required this.title,
    required this.countLabel,
    required this.playlists,
    required this.horizontalPadding,
  });

  final String title;
  final String countLabel;
  final List<MusicPlaylist> playlists;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return _CompactCardScroller(
      title: title,
      countLabel: countLabel,
      horizontalPadding: horizontalPadding,
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return SizedBox(
          width: 150,
          child: MusicPlaylistGridCard(
            playlist: playlist,
            onTap: () =>
                context.push('/playlists/${playlist.id}', extra: playlist),
            artworkRadius: AppRadiusTokens.mobileMd,
            compact: true,
          ),
        );
      },
    );
  }
}

class _CompactCardScroller extends StatelessWidget {
  const _CompactCardScroller({
    required this.title,
    required this.countLabel,
    required this.horizontalPadding,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final String countLabel;
  final double horizontalPadding;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

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
        SliverToBoxAdapter(
          child: SizedBox(
            height: 224,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: itemBuilder,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacingTokens.sectionGap),
        ),
      ],
    );
  }
}

class _TrackSection extends StatelessWidget {
  const _TrackSection({required this.tracks});

  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '歌曲', countLabel: '${tracks.length} 首'),
        MusicTrackTable(
          tracks: tracks,
          showActionBar: false,
          onTrackTap: (index, _) => unawaited(
            PlayerNavigation.playTracksAndOpenPlayer(
              context,
              tracks: tracks,
              startIndex: index,
            ),
          ),
          onAddTrackToQueue: (track) =>
              unawaited(_addTracksToQueue(context, [track])),
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
  AppSnackBar.show(context, message);
}

int _artistGridCount(double width) {
  if (width >= 1200) return 8;
  if (width >= 900) return 6;
  if (width >= 600) return 4;
  return 3;
}

int _searchResultGridCount(double width) {
  final contentWidth = width > 980 ? 980 : width;
  final count = ((contentWidth + 18) / (132 + 18)).floor();
  return count.clamp(2, 6).toInt();
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _SearchStartView extends StatelessWidget {
  const _SearchStartView({required this.queries, required this.onSelected});

  final List<String> queries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SearchStateScrollView(
      child: SearchEmptyView(
        recentQueries: queries,
        onQuerySelected: onSelected,
        onQueryRemoved: context.read<SearchCubit>().removeRecent,
        onClearRecent: queries.isEmpty
            ? null
            : () => _clearRecentSearches(context, queries),
      ),
    );
  }
}

void _clearRecentSearches(BuildContext context, List<String> queries) {
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
          onPressed: () => unawaited(cubit.restoreRecent(previousQueries)),
        ),
      ),
    );
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

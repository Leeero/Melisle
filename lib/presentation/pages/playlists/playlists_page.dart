import 'dart:math' as math;

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_playlist_card.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PlaylistsCubit(FetchPlaylists(context.read<MusicRepository>()))
            ..load(),
      child: const _PlaylistsView(),
    );
  }
}

class _PlaylistsView extends StatefulWidget {
  const _PlaylistsView();

  @override
  State<_PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends State<_PlaylistsView> {
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
      context.read<PlaylistsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return BlocConsumer<PlaylistsCubit, PlaylistsState>(
      listener: (context, state) {
        if (_searchController.text == state.searchQuery) return;
        _searchController.value = TextEditingValue(
          text: state.searchQuery,
          selection: TextSelection.collapsed(offset: state.searchQuery.length),
        );
      },
      builder: (context, state) {
        return AppContentPage(
          header: _PlaylistsHeader(state: state, controller: _searchController),
          body: _buildBody(context, state, horizontalPadding),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    PlaylistsState state,
    double horizontalPadding,
  ) {
    if (state.status == PlaylistsStatus.loading && state.allPlaylists.isEmpty) {
      return const AppBodyStateView.loading();
    }

    if (state.status == PlaylistsStatus.failure && state.allPlaylists.isEmpty) {
      return AppBodyStateView.message(message: state.errorMessage ?? '加载歌单失败');
    }

    if (state.allPlaylists.isEmpty) {
      if (state.isFiltering) {
        return AppBodyStateView.message(
          message: '没有找到匹配的歌单。',
          action: TextButton.icon(
            onPressed: () => context.read<PlaylistsCubit>().search(''),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('清除搜索'),
          ),
        );
      }
      return const AppBodyStateView.message(message: '当前还没有歌单。');
    }

    if (state.playlists.isEmpty) {
      return AppBodyStateView.message(
        message: '没有找到匹配的歌单。',
        action: TextButton.icon(
          onPressed: () => context.read<PlaylistsCubit>().search(''),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('清除搜索'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.usesWideContentWidth(
          constraints.maxWidth,
        );

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final sidePadding = _playlistGridSidePadding(
                  constraints.crossAxisExtent,
                  horizontalPadding,
                  isWide,
                );

                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final playlist = state.playlists[index];
                      return MusicPlaylistGridCard(
                        playlist: playlist,
                        onTap: () => context.push(
                          '/playlists/${playlist.id}',
                          extra: playlist,
                        ),
                        artworkRadius: isWide
                            ? AppRadiusTokens.coverGrid
                            : AppRadiusTokens.mobileMd,
                        compact: !isWide,
                        scaleOnHover: isWide ? 1.006 : 1.012,
                      );
                    }, childCount: state.playlists.length),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isWide ? 176 : 174,
                      crossAxisSpacing: isWide ? 18 : 14,
                      mainAxisSpacing: isWide ? 24 : 24,
                      childAspectRatio: isWide ? 0.76 : 0.78,
                      mainAxisExtent: isWide ? 226 : null,
                    ),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(child: _buildFooter(state)),
          ],
        );
      },
    );
  }

  Widget _buildFooter(PlaylistsState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.status == PlaylistsStatus.failure &&
        state.allPlaylists.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            state.errorMessage ?? '加载更多歌单失败',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 32);
  }
}

class _PlaylistsHeader extends StatelessWidget {
  const _PlaylistsHeader({required this.state, required this.controller});

  final PlaylistsState state;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.usesWideContent(context);
    final searchField = AppSearchField(
      controller: controller,
      dense: true,
      hintText: '搜索歌单名称',
      semanticLabel: '搜索歌单',
      showCancelAction: false,
      onClear: () {
        controller.clear();
        context.read<PlaylistsCubit>().search('');
      },
      onChanged: context.read<PlaylistsCubit>().search,
    );
    final summary = state.isFiltering
        ? '找到 ${state.playlists.length} 个匹配歌单'
        : '${state.allPlaylists.length} 个歌单';

    if (!isWide) {
      return AppPageHeader(
        title: '歌单',
        description: summary,
        automaticImplyLeading: false,
        hideTitleOnCompactWithCenter: false,
        center: searchField,
        trailing: MetaPill(
          label: '${state.playlists.length} 项',
          size: MetaPillSize.compact,
        ),
      );
    }

    return AppPageHeader(
      title: '歌单',
      description: summary,
      automaticImplyLeading: false,
      hideTitleOnCompactWithCenter: false,
      titleMaxWidth: 260,
      maxWidth: _playlistDesktopMaxWidth,
      trailing: SizedBox(width: 420, child: searchField),
    );
  }
}

const _playlistDesktopMaxWidth = 1040.0;

double _playlistGridSidePadding(
  double crossAxisExtent,
  double horizontalPadding,
  bool isWide,
) {
  if (!isWide) return horizontalPadding;

  final availableWidth = math.max(0, crossAxisExtent - horizontalPadding * 2);
  final extraWidth = math.max(0, availableWidth - _playlistDesktopMaxWidth);
  return horizontalPadding + extraWidth / 2;
}

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
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
    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
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
          header: _PlaylistsHeader(
            state: state,
            searchController: _searchController,
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PlaylistsState state) {
    if (state.status == PlaylistsStatus.loading && state.allPlaylists.isEmpty) {
      return const AppBodyStateView.loading();
    }

    if (state.status == PlaylistsStatus.failure && state.allPlaylists.isEmpty) {
      return AppBodyStateView.message(
        message: state.errorMessage ?? '加载歌单失败',
      );
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

    final isWide = AppBreakpoints.usesWideContent(context);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: AppPageLayout.pagePadding(context),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final gap = isWide ? 20.0 : 14.0;
                  final count = ((constraints.crossAxisExtent + gap) /
                          (isWide ? 190 + gap : 148 + gap))
                      .floor()
                      .clamp(isWide ? 3 : 2, isWide ? 6 : 3)
                      .toInt();
                  final artworkWidth =
                      (constraints.crossAxisExtent - gap * (count - 1)) / count;
                  return SliverGrid(
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: isWide ? 28 : 20,
                      mainAxisExtent: artworkWidth + (isWide ? 72 : 62),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(child: _buildFooter(state)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(PlaylistsState state) {
    final hasLoadMoreError =
        state.status == PlaylistsStatus.failure &&
        state.allPlaylists.isNotEmpty;

    return AppPaginationFooter(
      status: hasLoadMoreError
          ? AppPaginationStatus.failed
          : state.isLoadingMore
          ? AppPaginationStatus.loading
          : state.hasMore
          ? AppPaginationStatus.idle
          : AppPaginationStatus.complete,
      errorMessage: state.errorMessage,
      onRetry: hasLoadMoreError
          ? () => context.read<PlaylistsCubit>().loadMore()
          : null,
    );
  }
}

class _PlaylistsHeader extends StatelessWidget {
  const _PlaylistsHeader({required this.state, required this.searchController});

  final PlaylistsState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlaylistsCubit>();
    final search = AppSearchField(
      controller: searchController,
      dense: true,
      showCancelAction: false,
      hintText: '在歌单中搜索',
      semanticLabel: '搜索歌单',
      onChanged: cubit.search,
      onClear: () {
        searchController.clear();
        cubit.search('');
      },
    );
    if (!AppBreakpoints.usesWideContent(context)) return search;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: '歌单',
          description: '${state.allPlaylists.length} 个歌单',
          automaticImplyLeading: false,
          trailing: _PlaylistRefreshButton(
            isRefreshing:
                state.status == PlaylistsStatus.loading &&
                state.allPlaylists.isNotEmpty,
            onPressed: () => _refreshPlaylists(context, cubit),
          ),
        ),
        const SizedBox(height: 24),
        search,
      ],
    );
  }
}

Future<void> _refreshPlaylists(
  BuildContext context,
  PlaylistsCubit cubit,
) async {
  await cubit.load();
  if (!context.mounted) return;

  final state = cubit.state;
  if (state.status == PlaylistsStatus.failure) {
    AppSnackBar.show(context, state.errorMessage ?? '刷新歌单失败');
    return;
  }
  AppSnackBar.show(context, '已刷新 ${state.allPlaylists.length} 个歌单');
}

class _PlaylistRefreshButton extends StatelessWidget {
  const _PlaylistRefreshButton({
    required this.isRefreshing,
    required this.onPressed,
  });

  final bool isRefreshing;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return AppActionButton(
      icon: isRefreshing ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
      label: isRefreshing ? '刷新中' : '刷新',
      onPressed: isRefreshing ? null : () => onPressed(),
    );
  }
}

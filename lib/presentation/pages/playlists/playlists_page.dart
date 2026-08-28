import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
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
      builder: (context, state) => AppContentPage(
        body: _buildBody(context, state),
      ),
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
              SliverGrid(
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
                  mainAxisSpacing: 24,
                  childAspectRatio: isWide ? 0.72 : 0.78,
                ),
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

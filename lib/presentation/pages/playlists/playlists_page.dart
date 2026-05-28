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
    if (state.status == PlaylistsStatus.loading && state.playlists.isEmpty) {
      return const AppBodyStateView.loading();
    }

    if (state.status == PlaylistsStatus.failure && state.playlists.isEmpty) {
      return AppBodyStateView.message(message: state.errorMessage ?? '加载歌单失败');
    }

    if (state.playlists.isEmpty) {
      return const AppBodyStateView.message(message: '当前没有匹配的歌单。');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.usesWideContentWidth(
          constraints.maxWidth,
        );

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (!isWide)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  24,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final playlist = state.playlists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MusicPlaylistListTile(
                        playlist: playlist,
                        onTap: () => context.push(
                          '/playlists/${playlist.id}',
                          extra: playlist,
                        ),
                      ),
                    );
                  }, childCount: state.playlists.length),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  24,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final playlist = state.playlists[index];
                    return MusicPlaylistGridCard(
                      playlist: playlist,
                      onTap: () => context.push(
                        '/playlists/${playlist.id}',
                        extra: playlist,
                      ),
                    );
                  }, childCount: state.playlists.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: AppBreakpoints.adaptiveAlbumGridCount(
                      constraints.maxWidth,
                    ),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 32,
                    childAspectRatio: 0.8,
                  ),
                ),
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
    if (!state.hasMore && state.playlists.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('已经到底了')),
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
    final searchField = AppSearchField(
      controller: controller,
      dense: true,
      hintText: '搜索歌单',
      semanticLabel: '搜索歌单',
      onClear: () {
        controller.clear();
        context.read<PlaylistsCubit>().search('');
      },
      onChanged: context.read<PlaylistsCubit>().search,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: '歌单',
          automaticImplyLeading: false,
          hideTitleOnCompactWithCenter: false,
          center: searchField,
          trailing: MetaPill(
            label: '${state.playlists.length} 项',
            size: MetaPillSize.compact,
          ),
        ),
      ],
    );
  }
}

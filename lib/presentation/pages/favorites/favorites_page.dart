import 'package:cross_platform_music_player/application/usecases/fetch_favorite_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavoritesListCubit(
        FetchFavoriteTracks(context.read<MusicRepository>()),
        context.read<FavoritesCubit>(),
      )..load(),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatefulWidget {
  const _FavoritesView();

  @override
  State<_FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<_FavoritesView> {
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
      context.read<FavoritesListCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<FavoritesListCubit, FavoritesListState>(
      builder: (context, state) {
        return AppContentPage(
          header: AppBreakpoints.usesDesktopToolbar(context)
              ? _FavoritesDesktopActions(state: state)
              : _FavoritesHeader(state: state),
          body: _buildBody(context, state, horizontalPadding, currentTrackId),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    FavoritesListState state,
    double horizontalPadding,
    String? currentTrackId,
  ) {
    if (state.status == FavoritesListStatus.loading && state.tracks.isEmpty) {
      return const AppBodyStateView.loading();
    }

    if (state.status == FavoritesListStatus.failure && state.tracks.isEmpty) {
      return AppBodyStateView.message(
        message: '收藏加载失败',
        description: state.errorMessage,
        icon: Icons.error_outline_rounded,
      );
    }

    if (state.tracks.isEmpty) {
      return AppBodyStateView.message(
        message: '还没有收藏歌曲',
        description: '在媒体库或播放页点亮爱心后，歌曲会集中显示在这里。',
        icon: Icons.favorite_border_rounded,
        action: FilledButton.icon(
          onPressed: () => context.go('/library'),
          icon: const Icon(Icons.library_music_rounded),
          label: const Text('去媒体库看看'),
        ),
      );
    }

    if (AppBreakpoints.usesWideContent(context)) {
      return ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppBreakpoints.usesDesktopToolbar(context) ? 8 : 0,
          horizontalPadding,
          24,
        ),
        children: [
          MusicTrackTable(
            tracks: state.tracks,
            currentTrackId: currentTrackId,
            showActionBar: false,
            onTrackTap: (index, _) => PlayerNavigation.playTracksAndOpenPlayer(
              context,
              tracks: state.tracks,
              startIndex: index,
            ),
            trailingBuilder: (context, track, _) =>
                _FavoriteTrackActionButton(track: track, compact: true),
          ),
          _FavoritesPaginationFooter(state: state),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
      itemCount: state.tracks.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _FavoritesPlayAllToolbar(state: state, expand: true);
        }
        if (index == 1) {
          return AppSectionTitleRow(
            title: '收藏歌曲',
            badge: MetaPill(
              label: '${state.tracks.length} 首',
              size: MetaPillSize.compact,
            ),
          );
        }
        final trackIndex = index - 2;
        if (trackIndex == state.tracks.length) {
          return _FavoritesPaginationFooter(state: state);
        }

        final track = state.tracks[trackIndex];
        return _FavoriteTrackRow(
          track: track,
          currentTrackId: currentTrackId,
          onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
            context,
            tracks: state.tracks,
            startIndex: trackIndex,
          ),
        );
      },
    );
  }
}

class _FavoritesDesktopActions extends StatelessWidget {
  const _FavoritesDesktopActions({required this.state});

  final FavoritesListState state;

  @override
  Widget build(BuildContext context) {
    final count = state.tracks.length;
    return Row(
      children: [
        MetaPill(label: '$count 首', size: MetaPillSize.compact),
        const Spacer(),
        if (count > 0)
          PlayAllButton(
            variant: PlayAllButtonVariant.compact,
            onPressed: () => _playAllFavorites(context, state),
            onShufflePressed: () =>
                _playAllFavorites(context, state, shuffled: true),
          ),
      ],
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.state});

  final FavoritesListState state;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final count = state.tracks.length;
    final playAllButton = count == 0
        ? null
        : PlayAllButton(
            variant: PlayAllButtonVariant.compact,
            onPressed: () => _playAllFavorites(context, state),
            onShufflePressed: () =>
                _playAllFavorites(context, state, shuffled: true),
          );

    return AppPageHeader(
      title: '收藏',
      description: count == 0 ? '你标记喜欢的歌曲' : '$count 首收藏歌曲',
      automaticImplyLeading: false,
      trailing: compact ? null : playAllButton,
    );
  }
}

class _FavoritesPlayAllToolbar extends StatelessWidget {
  const _FavoritesPlayAllToolbar({required this.state, this.expand = false});

  final FavoritesListState state;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = PlayAllButton(
      variant: PlayAllButtonVariant.primary,
      onPressed: state.tracks.isEmpty
          ? null
          : () => _playAllFavorites(context, state),
      onShufflePressed: state.tracks.isEmpty
          ? null
          : () => _playAllFavorites(context, state, shuffled: true),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

class _FavoriteTrackRow extends StatelessWidget {
  const _FavoriteTrackRow({
    required this.track,
    required this.currentTrackId,
    required this.onTap,
  });

  final MusicTrack track;
  final String? currentTrackId;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return MusicTrackTile.row(
      isCurrent: track.id == currentTrackId,
      artworkUrl: track.artworkUrl,
      title: track.title,
      subtitle: [
        track.artistName,
        track.albumTitle,
      ].where((item) => item.isNotEmpty).join(' · '),
      onTap: onTap,
      extraTrailing: _FavoriteTrackActionButton(track: track),
    );
  }
}

Future<void> _playAllFavorites(
  BuildContext context,
  FavoritesListState state, {
  bool shuffled = false,
}) {
  if (shuffled) {
    return PlayerNavigation.shuffleAllAndOpenPlayer(
      context,
      loadedTracks: state.tracks,
      allLoaded: !state.hasMore,
      fetchAll: () => context.read<MusicRepository>().fetchFavoriteTracks(
        limit: 500,
        startIndex: 0,
      ),
    );
  }

  return PlayerNavigation.playAllAndOpenPlayer(
    context,
    loadedTracks: state.tracks,
    allLoaded: !state.hasMore,
    fetchAll: () => context.read<MusicRepository>().fetchFavoriteTracks(
      limit: 500,
      startIndex: 0,
    ),
  );
}

class _FavoriteTrackActionButton extends StatelessWidget {
  const _FavoriteTrackActionButton({required this.track, this.compact = false});

  final MusicTrack track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.isFavorite(track.id, fallback: track.isFavorite),
    );
    final isPending = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.pending.contains(track.id),
    );

    return _PulsingFavoriteButton(
      isPending: isPending,
      isFavorite: isFavorite,
      colorScheme: colorScheme,
      compact: compact,
      onPressed: isPending
          ? null
          : () async {
              final favoritesCubit = context.read<FavoritesCubit>();
              final listCubit = context.read<FavoritesListCubit>();
              await favoritesCubit.toggle(track.id, currentValue: isFavorite);
              final stillFavorite = favoritesCubit.isFavorite(
                track.id,
                fallback: track.isFavorite,
              );
              if (!stillFavorite) {
                listCubit.removeTrack(track.id);
              }
              if (!context.mounted) return;
              AppSnackBar.show(context, stillFavorite ? '已收藏' : '取消收藏');
            },
    );
  }
}

class _FavoritesPaginationFooter extends StatelessWidget {
  const _FavoritesPaginationFooter({required this.state});

  final FavoritesListState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('已经到底了', style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }
    return const SizedBox(height: 12);
  }
}

class _PulsingFavoriteButton extends StatefulWidget {
  const _PulsingFavoriteButton({
    required this.isPending,
    required this.isFavorite,
    required this.colorScheme,
    required this.onPressed,
    this.compact = false,
  });

  final bool isPending;
  final bool isFavorite;
  final ColorScheme colorScheme;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  State<_PulsingFavoriteButton> createState() => _PulsingFavoriteButtonState();
}

class _PulsingFavoriteButtonState extends State<_PulsingFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    if (widget.isPending) _controller.repeat();
  }

  @override
  void didUpdateWidget(_PulsingFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPending && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPending && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dimension = 44.0;
    final iconSize = widget.compact ? 18.0 : 22.0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox.square(
        dimension: dimension,
        child: IconButton(
          tooltip: '取消收藏',
          onPressed: widget.onPressed,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: AppActionButtonStyle.icon(
            context,
            selected: widget.isFavorite,
            iconSize: iconSize,
          ),
          icon: widget.isPending
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.colorScheme.primary,
                  ),
                )
              : Icon(
                  widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: iconSize,
                  color: widget.isFavorite
                      ? widget.colorScheme.error
                      : widget.colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}

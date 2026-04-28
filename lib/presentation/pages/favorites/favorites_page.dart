import 'package:cross_platform_music_player/application/usecases/fetch_favorite_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: BlocBuilder<FavoritesListCubit, FavoritesListState>(
        builder: (context, state) {
          return AppContentPage(
            topSafeArea: false,
            header: _FavoritesHeader(
              count: state.tracks.length,
              tracks: state.tracks,
              hasMore: state.hasMore,
            ),
            body: _buildBody(context, state, horizontalPadding, currentTrackId),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FavoritesListState state,
    double horizontalPadding,
    String? currentTrackId,
  ) {
    if (state.status == FavoritesListStatus.loading && state.tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == FavoritesListStatus.failure && state.tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(state.errorMessage ?? '加载收藏失败'),
        ),
      );
    }

    if (state.tracks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('还没有收藏歌曲，去媒体库挑几首喜欢的吧。'),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
      itemCount: state.tracks.length + 1,
      itemBuilder: (context, index) {
        if (index == state.tracks.length) {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!state.hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('已经到底了')),
            );
          }
          return const SizedBox(height: 12);
        }

        final track = state.tracks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FavoriteTrackCard(
            track: track,
            currentTrackId: currentTrackId,
            onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
              context,
              tracks: state.tracks,
              startIndex: index,
            ),
          ),
        );
      },
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({
    required this.count,
    required this.tracks,
    required this.hasMore,
  });

  final int count;
  final List<MusicTrack> tracks;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('我的收藏', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '把喜欢的歌曲留在一个随时可回到的入口',
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
          MetaPill(label: '$count 首'),
          if (count > 0) ...[
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: () => PlayerNavigation.playAllAndOpenPlayer(
                context,
                loadedTracks: tracks,
                allLoaded: !hasMore,
                fetchAll: () => context
                    .read<MusicRepository>()
                    .fetchFavoriteTracks(limit: 500, startIndex: 0),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('播放全部'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavoriteTrackCard extends StatelessWidget {
  const _FavoriteTrackCard({
    required this.track,
    required this.currentTrackId,
    required this.onTap,
  });

  final MusicTrack track;
  final String? currentTrackId;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.isFavorite(track.id, fallback: track.isFavorite),
    );
    final isPending = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.pending.contains(track.id),
    );

    return MusicTrackTile.card(
      isCurrent: track.id == currentTrackId,
      artworkUrl: track.artworkUrl,
      title: track.title,
      subtitle: [
        track.artistName,
        track.albumTitle,
      ].where((item) => item.isNotEmpty).join(' · '),
      onTap: onTap,
      extraTrailing: _PulsingFavoriteButton(
        isPending: isPending,
        isFavorite: isFavorite,
        colorScheme: colorScheme,
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
              },
      ),
    );
  }
}

// Phase 4: Pulsing favorite button with scale animation when pending
class _PulsingFavoriteButton extends StatefulWidget {
  const _PulsingFavoriteButton({
    required this.isPending,
    required this.isFavorite,
    required this.colorScheme,
    required this.onPressed,
  });

  final bool isPending;
  final bool isFavorite;
  final ColorScheme colorScheme;
  final VoidCallback? onPressed;

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
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        tooltip: '取消收藏',
        onPressed: widget.onPressed,
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
                color: widget.isFavorite
                    ? widget.colorScheme.error
                    : widget.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

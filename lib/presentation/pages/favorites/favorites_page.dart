import 'package:cross_platform_music_player/application/usecases/fetch_favorite_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
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
          _MetaPill(label: '$count 首'),
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

class _FavoriteTrackCard extends StatefulWidget {
  const _FavoriteTrackCard({
    required this.track,
    required this.currentTrackId,
    required this.onTap,
  });

  final MusicTrack track;
  final String? currentTrackId;
  final Future<void> Function() onTap;

  @override
  State<_FavoriteTrackCard> createState() => _FavoriteTrackCardState();
}

class _FavoriteTrackCardState extends State<_FavoriteTrackCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrent = widget.track.id == widget.currentTrackId;
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) =>
          cubit.isFavorite(widget.track.id, fallback: widget.track.isFavorite),
    );
    final isPending = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.pending.contains(widget.track.id),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isCurrent
              ? colorScheme.primaryContainer.withValues(alpha: 0.82)
              : colorScheme.surface.withValues(alpha: _hovered ? 0.92 : 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.68),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: widget.track.artworkUrl,
                    size: 58,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              const _MetaPill(label: '当前播放'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            widget.track.artistName,
                            widget.track.albumTitle,
                          ].where((item) => item.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Phase 4: Favorite button pulse animation when pending
                  _PulsingFavoriteButton(
                    isPending: isPending,
                    isFavorite: isFavorite,
                    colorScheme: colorScheme,
                    onPressed: isPending
                        ? null
                        : () async {
                            final favoritesCubit = context
                                .read<FavoritesCubit>();
                            final listCubit = context
                                .read<FavoritesListCubit>();
                            await favoritesCubit.toggle(
                              widget.track.id,
                              currentValue: isFavorite,
                            );
                            final stillFavorite = favoritesCubit.isFavorite(
                              widget.track.id,
                              fallback: widget.track.isFavorite,
                            );
                            if (!stillFavorite) {
                              listCubit.removeTrack(widget.track.id);
                            }
                          },
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isCurrent
                          ? Icons.graphic_eq_rounded
                          : Icons.play_arrow_rounded,
                      color: isCurrent
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

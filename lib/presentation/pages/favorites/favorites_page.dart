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
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/tracks/app_track_collection_view.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
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
          header: _FavoritesHeader(state: state),
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
        action: FilledButton.icon(
          onPressed: () => context.read<FavoritesListCubit>().load(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重试'),
        ),
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

    if (AppBreakpoints.usesTrackTable(context)) {
      return _FavoritesDesktopTrackList(
        tracks: state.tracks,
        currentTrackId: currentTrackId,
        horizontalPadding: horizontalPadding,
        scrollController: _scrollController,
        footer: _FavoritesPaginationFooter(state: state),
        onTrackTap: (index) => PlayerNavigation.playTracksAndOpenPlayer(
          context,
          tracks: state.tracks,
          startIndex: index,
        ),
      );
    }

    return AppTrackCollectionView(
      tracks: state.tracks,
      currentTrackId: currentTrackId,
      horizontalPadding: horizontalPadding,
      scrollController: _scrollController,
      mobileHeader: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FavoritesPlayAllToolbar(state: state, expand: true),
          AppSectionTitleRow(
            title: '收藏歌曲',
            badge: MetaPill(
              label: '${state.tracks.length} 首',
              size: MetaPillSize.compact,
            ),
          ),
        ],
      ),
      mobileItemBuilder: (context, track, trackIndex, currentTrackId) {
        return _FavoriteTrackRow(
          track: track,
          currentTrackId: currentTrackId,
          onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
            context,
            tracks: state.tracks,
            startIndex: trackIndex,
          ),
          onUnfavorite: () => _toggleFavorite(context, track),
          onDismissed: () =>
              context.read<FavoritesListCubit>().removeTrack(track.id),
        );
      },
      onTrackTap: (index) => PlayerNavigation.playTracksAndOpenPlayer(
        context,
        tracks: state.tracks,
        startIndex: index,
      ),
      footer: _FavoritesPaginationFooter(state: state),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.state});

  final FavoritesListState state;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.usesDesktopToolbar(context)) {
      return AppPageHeader(
        title: '收藏',
        automaticImplyLeading: false,
        trailing: _FavoritesDesktopActions(state: state),
      );
    }

    return AppPageHeader(
      title: '收藏',
      description: state.tracks.isEmpty
          ? '你标记喜欢的歌曲'
          : '${state.tracks.length} 首收藏歌曲',
      automaticImplyLeading: false,
    );
  }
}

class _FavoritesDesktopActions extends StatelessWidget {
  const _FavoritesDesktopActions({required this.state});

  final FavoritesListState state;

  @override
  Widget build(BuildContext context) {
    final enabled = state.tracks.isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: enabled ? () => _playAllFavorites(context, state) : null,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('全部播放'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.cardPadding),
            shape: shape,
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: enabled
              ? () => _playAllFavorites(context, state, shuffled: true)
              : null,
          icon: const Icon(Icons.shuffle_rounded, size: 18),
          label: const Text('随机播放'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.cardPadding),
            side: BorderSide(color: colors.primary),
            shape: shape,
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

class _FavoritesDesktopTrackList extends StatelessWidget {
  const _FavoritesDesktopTrackList({
    required this.tracks,
    required this.currentTrackId,
    required this.horizontalPadding,
    required this.scrollController,
    required this.onTrackTap,
    required this.footer,
  });

  final List<MusicTrack> tracks;
  final String? currentTrackId;
  final double horizontalPadding;
  final ScrollController scrollController;
  final ValueChanged<int> onTrackTap;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
      children: [
        const _FavoritesDesktopTableHeader(),
        for (var index = 0; index < tracks.length; index++)
          _FavoritesDesktopTrackRow(
            track: tracks[index],
            isCurrent: tracks[index].id == currentTrackId,
            onTap: () => onTrackTap(index),
          ),
        footer,
      ],
    );
  }
}

class _FavoritesDesktopTableHeader extends StatelessWidget {
  const _FavoritesDesktopTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.muted,
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(flex: 4, child: Text('标题', style: labelStyle)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: Text('艺术家', style: labelStyle)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: Text('专辑', style: labelStyle)),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text('时长', style: labelStyle, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _FavoritesDesktopTrackRow extends StatefulWidget {
  const _FavoritesDesktopTrackRow({
    required this.track,
    required this.isCurrent,
    required this.onTap,
  });

  final MusicTrack track;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  State<_FavoritesDesktopTrackRow> createState() =>
      _FavoritesDesktopTrackRowState();
}

class _FavoritesDesktopTrackRowState extends State<_FavoritesDesktopTrackRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final highlighted = _hovered || _focused;
    final title = MediaDisplayText.trackTitle(widget.track.title);
    final primaryTextColor = widget.isCurrent
        ? colors.primary
        : colors.onSurface;
    final secondaryTextColor = widget.isCurrent ? colors.primary : theme.muted;

    return Semantics(
      label: '播放《$title》',
      button: true,
      selected: widget.isCurrent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: widget.isCurrent
              ? theme.selectedWash
              : highlighted
              ? theme.hoverWash
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('favorite-track-row-play-${widget.track.id}'),
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            hoverColor: Colors.transparent,
            splashColor: colors.primary.withValues(alpha: 0.06),
            highlightColor: Colors.transparent,
            mouseCursor: SystemMouseCursors.click,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.cardPadding),
                child: Row(
                  children: [
                    CachedArtwork(
                      imageUrl: widget.track.artworkUrl,
                      size: 40,
                      borderRadius: AppRadiusTokens.desktopSm,
                      semanticLabel: '$title 封面',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _FavoritesDesktopCellText(
                        MediaDisplayText.artistName(widget.track.artistName),
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _FavoritesDesktopCellText(
                        MediaDisplayText.albumTitle(widget.track.albumTitle),
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          AnimatedOpacity(
                            opacity: highlighted ? 0 : 1,
                            duration: AppMotion.micro,
                            child: Text(
                              _formatFavoriteDuration(widget.track.duration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryTextColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: highlighted || widget.isCurrent ? 1 : 0,
                            duration: AppMotion.micro,
                            child: IgnorePointer(
                              ignoring: !highlighted && !widget.isCurrent,
                              child: _FavoriteTrackActionButton(
                                track: widget.track,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
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

class _FavoritesDesktopCellText extends StatelessWidget {
  const _FavoritesDesktopCellText(this.value, {required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }
}

String _formatFavoriteDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _FavoriteTrackRow extends StatelessWidget {
  const _FavoriteTrackRow({
    required this.track,
    required this.currentTrackId,
    required this.onTap,
    required this.onUnfavorite,
    required this.onDismissed,
  });

  final MusicTrack track;
  final String? currentTrackId;
  final Future<void> Function() onTap;
  final Future<bool> Function() onUnfavorite;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('favorite-${track.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onUnfavorite(),
      onDismissed: (_) => onDismissed(),
      secondaryBackground: const _UnfavoriteBackground(),
      child: MusicTrackTile.favorite(
        isCurrent: track.id == currentTrackId,
        artworkUrl: track.artworkUrl,
        title: track.title,
        subtitle: track.artistName,
        onTap: onTap,
        extraTrailing: _FavoriteTrackActionButton(track: track),
      ),
    );
  }
}

class _UnfavoriteBackground extends StatelessWidget {
  const _UnfavoriteBackground();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '取消收藏',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacingTokens.sectionGap),
            child: Icon(Icons.delete_outline_rounded, color: colors.onError),
          ),
        ),
      ),
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
              if (await _toggleFavorite(context, track) && context.mounted) {
                context.read<FavoritesListCubit>().removeTrack(track.id);
              }
            },
    );
  }
}

Future<bool> _toggleFavorite(BuildContext context, MusicTrack track) async {
  final favoritesCubit = context.read<FavoritesCubit>();
  final wasUpdated = await favoritesCubit.toggle(
    track.id,
    currentValue: favoritesCubit.isFavorite(
      track.id,
      fallback: track.isFavorite,
    ),
  );
  if (!context.mounted) return false;
  if (!wasUpdated) {
    AppSnackBar.show(context, '取消收藏失败，请重试');
    return false;
  }
  AppSnackBar.show(context, '已取消收藏');
  return true;
}

class _FavoritesPaginationFooter extends StatelessWidget {
  const _FavoritesPaginationFooter({required this.state});

  final FavoritesListState state;

  @override
  Widget build(BuildContext context) {
    final hasLoadMoreError =
        state.errorMessage != null &&
        !state.isLoadingMore &&
        state.status == FavoritesListStatus.failure &&
        state.tracks.isNotEmpty;

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
          ? () => context.read<FavoritesListCubit>().loadMore()
          : null,
    );
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

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ScaleTransition(
      scale: reduceMotion ? const AlwaysStoppedAnimation(1) : _scaleAnimation,
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
                      ? widget.colorScheme.primary
                      : widget.colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}

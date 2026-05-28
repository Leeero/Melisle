import 'package:cross_platform_music_player/application/usecases/fetch_latest_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_random_albums.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        FetchLatestAlbums(context.read<MusicRepository>()),
        FetchRandomAlbums(context.read<MusicRepository>()),
        context.read<MusicRepository>(),
        database: _tryReadDatabase(context),
      )..load(),
      child: const _HomeView(),
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

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return _buildBody(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.status == HomeStatus.loading && state.albums.isEmpty) {
      return const AppBodyStateView.loading();
    }

    if (state.status == HomeStatus.failure && state.albums.isEmpty) {
      return AppBodyStateView.message(
        message: state.errorMessage ?? '加载失败',
        action: FilledButton.icon(
          onPressed: () => context.read<HomeCubit>().load(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重新加载'),
        ),
      );
    }

    if (state.albums.isEmpty && state.recentlyPlayed.isEmpty) {
      return AppBodyStateView.message(
        message: '连接服务器，开始你的音乐之旅。',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/library'),
              icon: const Icon(Icons.library_music_rounded),
              label: const Text('进入媒体库'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.read<HomeCubit>().load(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            6,
          ),
          sliver: SliverToBoxAdapter(child: _SearchEntry()),
        ),

        if (state.randomPicks.isNotEmpty)
          _randomPicksCarousel(
            context,
            albums: state.randomPicks,
            horizontalPadding: horizontalPadding,
          ),

        if (state.recentlyPlayed.isNotEmpty)
          _recentTracksSection(
            context,
            tracks: state.recentlyPlayed,
            currentTrackId: currentTrackId,
            horizontalPadding: horizontalPadding,
          ),

        if (state.mostPlayed.isNotEmpty)
          _rankedTrackListSection(
            context,
            title: '常听的歌',
            tracks: state.mostPlayed,
            currentTrackId: currentTrackId,
            horizontalPadding: horizontalPadding,
          ),

        if (state.albums.isNotEmpty)
          _albumListSection(
            context,
            albums: state.albums,
            horizontalPadding: horizontalPadding,
          ),

        SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacingTokens.contentBottom),
        ),
      ],
    );
  }

  SliverPadding _randomPicksCarousel(
    BuildContext context, {
    required List<MusicAlbum> albums,
    required double horizontalPadding,
  }) {
    final isWide = AppBreakpoints.usesWideContent(context);
    final cardWidth = isWide ? 184.0 : 152.0;
    final cardHeight = cardWidth + 56.0;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacingTokens.sectionGap,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: AppSectionTitleRow(
              title: '今日推荐',
              padding: const EdgeInsets.only(bottom: 12),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: albums.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return SizedBox(
                    width: cardWidth,
                    child: MusicAlbumGridCard(
                      album: album,
                      onTap: () =>
                          context.push('/album/${album.id}', extra: album),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverPadding _recentTracksSection(
    BuildContext context, {
    required List<MusicTrack> tracks,
    required String? currentTrackId,
    required double horizontalPadding,
  }) {
    const maxDisplay = 8;
    final displayTracks = tracks.take(maxDisplay).toList();
    final isWide = AppBreakpoints.usesWideContent(context);
    final cardWidth = isWide ? 150.0 : 130.0;
    final coverSize = cardWidth;
    final cardHeight = coverSize + 52.0;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacingTokens.sectionGap,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: AppSectionTitleRow(
              title: '最近播放',
              padding: const EdgeInsets.only(bottom: 14),
              action: _HomeViewAllButton(
                onPressed: () => context.push('/history'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: displayTracks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final track = displayTracks[index];
                  return _RecentPlayCard(
                    track: track,
                    cardWidth: cardWidth,
                    coverSize: coverSize,
                    isCurrent: track.id == currentTrackId,
                    onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: tracks,
                      startIndex: index,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverPadding _rankedTrackListSection(
    BuildContext context, {
    required String title,
    required List<MusicTrack> tracks,
    required String? currentTrackId,
    required double horizontalPadding,
  }) {
    const maxDisplay = 12;
    final displayTracks = tracks.take(maxDisplay).toList();

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacingTokens.sectionGap,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: AppSectionTitleRow(
              title: title,
              padding: const EdgeInsets.only(bottom: 10),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final track = displayTracks[index];
              return _RankedTrackRow(
                rank: index + 1,
                track: track,
                onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                  context,
                  tracks: tracks,
                  startIndex: index,
                ),
              );
            }, childCount: displayTracks.length),
          ),
        ],
      ),
    );
  }

  SliverPadding _albumListSection(
    BuildContext context, {
    required List<MusicAlbum> albums,
    required double horizontalPadding,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacingTokens.sectionGap,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columnCount = AppBreakpoints.adaptiveAlbumGridCount(
            constraints.crossAxisExtent,
          );

          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: AppSectionTitleRow(
                  title: '最近加入',
                  padding: const EdgeInsets.only(bottom: 12),
                  action: _HomeViewAllButton(
                    onPressed: () => context.go('/library'),
                  ),
                ),
              ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final album = albums[index];
                  return MusicAlbumGridCard(
                    album: album,
                    artworkRadius: AppRadiusTokens.coverGrid,
                    onTap: () =>
                        context.push('/album/${album.id}', extra: album),
                  );
                }, childCount: albums.length),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 22,
                  childAspectRatio: 0.78,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeViewAllButton extends StatelessWidget {
  const _HomeViewAllButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '查看全部',
      button: true,
      child: TextButton.icon(
        onPressed: onPressed,
        iconAlignment: IconAlignment.end,
        label: const Text('查看全部'),
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '搜索音乐',
      button: true,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
          backgroundColor: colorScheme.surfaceContainerHigh.withValues(
            alpha: 0.54,
          ),
          foregroundColor: colorScheme.onSurface,
        ),
        onPressed: () => context.push('/search'),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '搜索曲目、专辑、艺术家、歌单',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPlayCard extends StatefulWidget {
  const _RecentPlayCard({
    required this.track,
    required this.cardWidth,
    required this.coverSize,
    required this.isCurrent,
    required this.onTap,
  });

  final MusicTrack track;
  final double cardWidth;
  final double coverSize;
  final bool isCurrent;
  final Future<void> Function() onTap;

  @override
  State<_RecentPlayCard> createState() => _RecentPlayCardState();
}

class _RecentPlayCardState extends State<_RecentPlayCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final track = widget.track;
    final subtitle = track.albumTitle.isNotEmpty
        ? '${track.artistName} · ${track.albumTitle}'
        : track.artistName;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1.0,
        duration: AppMotion.short,
        curve: AppMotion.enter,
        child: SizedBox(
          width: widget.cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onTap(),
                    borderRadius: BorderRadius.circular(AppRadiusTokens.card),
                    child: AnimatedContainer(
                      duration: AppMotion.short,
                      width: widget.cardWidth,
                      height: widget.coverSize,
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(
                          AppRadiusTokens.card,
                        ),
                        border: Border.all(
                          color: widget.isCurrent
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.64,
                                ),
                        ),
                        boxShadow: _hovered
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppRadiusTokens.card - 2,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedArtwork(
                              imageUrl: track.artworkUrl,
                              size: widget.coverSize,
                              borderRadius: AppRadiusTokens.card - 2,
                              semanticLabel: '《${track.title}》封面',
                            ),
                            if (widget.isCurrent)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 16,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            if (_hovered)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColorTokens.darkScaffold
                                        .withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(
                                      AppRadiusTokens.card - 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: 40,
                                      color: AppColorTokens.lightScaffold
                                          .withValues(alpha: 0.9),
                                    ),
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
              const SizedBox(height: 10),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _RankedTrackRow extends StatelessWidget {
  const _RankedTrackRow({
    required this.rank,
    required this.track,
    required this.onTap,
  });

  final int rank;
  final MusicTrack track;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isTop3 = rank <= 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        onTap: () => onTap(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  rank.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isTop3
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CachedArtwork(
                imageUrl: track.artworkUrl,
                size: 44,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (track.playCount > 0) ...[
                const SizedBox(width: 8),
                MetaPill(
                  label: '${track.playCount} 次',
                  size: MetaPillSize.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cross_platform_music_player/application/usecases/fetch_latest_albums.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_state.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
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
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return SafeArea(
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final featuredAlbum = state.albums.isEmpty
              ? null
              : state.albums.first;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              12,
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 10),
                  sliver: SliverToBoxAdapter(child: _SearchEntry()),
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 14),
                  sliver: SliverToBoxAdapter(child: _QuickAccessRow()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
                  sliver: SliverToBoxAdapter(
                    child: _HeroStage(
                      featuredAlbum: featuredAlbum,
                      albumCount: state.albums.length,
                    ),
                  ),
                ),
                if (state.status == HomeStatus.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == HomeStatus.failure)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.errorMessage ?? '加载失败',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => context.read<HomeCubit>().load(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('重新加载'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (state.recentlyPlayed.isNotEmpty)
                    ..._trackStripSlivers(
                      context,
                      title: '最近在听',
                      tracks: state.recentlyPlayed,
                      onMoreTap: () => context.push('/history'),
                    ),
                  if (state.mostPlayed.isNotEmpty)
                    ..._trackStripSlivers(
                      context,
                      title: '常听的歌',
                      tracks: state.mostPlayed,
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Text(
                            '最近加入',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          _CounterPill(label: '${state.albums.length} 张专辑'),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 26),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _AlbumCard(album: state.albums[index]),
                        childCount: state.albums.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _crossAxisCount(
                          MediaQuery.sizeOf(context).width,
                        ),
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.78,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  int _crossAxisCount(double width) {
    return AppBreakpoints.adaptiveAlbumGridCount(width);
  }

  List<Widget> _trackStripSlivers(
    BuildContext context, {
    required String title,
    required List<MusicTrack> tracks,
    VoidCallback? onMoreTap,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (onMoreTap != null)
                TextButton(onPressed: onMoreTap, child: const Text('查看更多')),
              _CounterPill(label: '${tracks.length} 首'),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: tracks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _RecentTrackCard(
              track: tracks[index],
              onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                context,
                tracks: tracks,
                startIndex: index,
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
    ];
  }
}

class _HeroStage extends StatelessWidget {
  const _HeroStage({required this.featuredAlbum, required this.albumCount});

  final MusicAlbum? featuredAlbum;
  final int albumCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        gradient: LinearGradient(
          colors: [
            colorScheme.surface.withValues(alpha: 0.88),
            colorScheme.primaryContainer.withValues(alpha: 0.58),
            colorScheme.secondaryContainer.withValues(alpha: 0.42),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = AppBreakpoints.usesWideContentWidth(
            constraints.maxWidth,
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  const _CounterPill(label: AppConstants.appEnglishName),
                  _CounterPill(label: '$albumCount 张专辑已同步'),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                AppConstants.appSlogan,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                featuredAlbum == null
                    ? '继续连接并同步你的音乐库，在乐岛开启今天的聆听。'
                    : '先从《${featuredAlbum!.title}》开始，在乐岛继续你的音乐热爱。',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/library'),
                    icon: const Icon(Icons.play_circle_rounded),
                    label: const Text('进入媒体库'),
                  ),
                  if (featuredAlbum != null)
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/album/${featuredAlbum!.id}',
                        extra: featuredAlbum,
                      ),
                      icon: const Icon(Icons.album_rounded),
                      label: const Text('打开推荐专辑'),
                    ),
                ],
              ),
            ],
          );

          if (!isWide || featuredAlbum == null) {
            return content;
          }

          final album = featuredAlbum!;
          return Row(
            children: [
              Expanded(flex: 6, child: content),
              const SizedBox(width: 28),
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 320,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 16,
                        top: 6,
                        child: Transform.rotate(
                          angle: -0.12,
                          child: Opacity(
                            opacity: 0.5,
                            child: CachedArtwork(
                              imageUrl: album.artworkUrl,
                              size: 204,
                              borderRadius: 30,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        bottom: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            boxShadow: [
                              // Phase 4: Enhanced hero cover BoxShadow
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 32,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CachedArtwork(
                              imageUrl: album.artworkUrl,
                              size: 228,
                              borderRadius: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumCard extends StatefulWidget {
  const _AlbumCard({required this.album});

  final MusicAlbum album;

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _hovered ? 1.015 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/album/${album.id}', extra: album),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer.withValues(
                            alpha: 0.58,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: CachedArtwork(
                                imageUrl: album.artworkUrl,
                                size: 170,
                                borderRadius: 24,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: _hovered ? 1 : 0.75,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withValues(
                                      alpha: 0.72,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${album.trackCount} 首',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            album.year == null ? '持续更新中' : '${album.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
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

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.label});

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

class _SearchEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Phase 4: OutlinedButton style search entry for clearer clickability
    return Semantics(
      label: '搜索音乐',
      button: true,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          backgroundColor: colorScheme.surfaceContainerHigh.withValues(
            alpha: 0.85,
          ),
        ),
        onPressed: () => context.push('/search'),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '搜索曲目、专辑、艺术家、歌单…',
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

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.favorite_rounded,
            title: '我的收藏',
            subtitle: '回到你标记过的喜欢',
            route: '/favorites',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.history_rounded,
            title: '播放历史',
            subtitle: '继续最近听过的内容',
            route: '/history',
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.68),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
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
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTrackCard extends StatelessWidget {
  const _RecentTrackCard({required this.track, required this.onTap});

  final MusicTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 138,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CachedArtwork(
                  imageUrl: track.artworkUrl,
                  size: 118,
                  borderRadius: 18,
                ),
                const SizedBox(height: 8),
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  track.artistName,
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
      ),
    );
  }
}

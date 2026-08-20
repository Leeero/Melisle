import 'package:cross_platform_music_player/application/usecases/fetch_latest_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_random_albums.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/app_skeleton.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
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
      child: const HomeView(),
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

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final hasData = _hasData(state);
            if (state.status == HomeStatus.loading && !hasData) {
              return const _HomeLoadingView();
            }
            if (state.status == HomeStatus.failure && !hasData) {
              return AppBodyStateView.message(
                message: state.errorMessage ?? '首页加载失败',
                action: FilledButton.icon(
                  onPressed: context.read<HomeCubit>().load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重新加载'),
                ),
              );
            }
            if (!hasData) {
              return AppBodyStateView.message(
                message: '还没有可展示的音乐',
                action: FilledButton.icon(
                  onPressed: () => context.go('/library'),
                  icon: const Icon(Icons.library_music_rounded),
                  label: const Text('进入媒体库'),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = AppBreakpoints.isCompactWidth(
                  constraints.maxWidth,
                );
                return compact
                    ? _MobileHomeContent(state: state)
                    : _DesktopHomeContent(state: state);
              },
            );
          },
        ),
      ),
    );
  }

  bool _hasData(HomeState state) {
    return state.albums.isNotEmpty ||
        state.randomPicks.isNotEmpty ||
        state.recentlyPlayed.isNotEmpty ||
        state.mostPlayed.isNotEmpty;
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (AppBreakpoints.isCompact(context))
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingTokens.pageHorizontalCompact,
              AppSpacingTokens.pageHorizontalCompact,
              AppSpacingTokens.pageHorizontalCompact,
              AppSpacingTokens.cardPadding,
            ),
            sliver: SliverToBoxAdapter(child: _MobileHomeTitle()),
          ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppBreakpoints.isCompact(context)
                ? AppSpacingTokens.pageHorizontalCompact
                : AppSpacingTokens.pageHorizontalExpanded,
            vertical: AppSpacingTokens.sectionGap,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              key: const ValueKey('home-loading-sections'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.row(height: 120, borderRadius: AppRadiusTokens.md),
                const SizedBox(height: 48),
                AppSkeleton.grid(count: 6),
                const SizedBox(height: 48),
                for (var index = 0; index < 3; index++) AppSkeleton.trackRow(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopHomeContent extends StatelessWidget {
  const _DesktopHomeContent({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<HomeCubit>().load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacingTokens.pageHorizontalExpanded,
          AppSpacingTokens.sectionGap,
          AppSpacingTokens.pageHorizontalExpanded,
          48,
        ),
        children: [
          if (state.errorMessage != null) ...[
            _HomeInlineError(message: state.errorMessage!),
            const SizedBox(height: 24),
          ],
          if (state.recentlyPlayed.isNotEmpty) ...[
            _DesktopContinueSection(
              tracks: state.recentlyPlayed.take(4).toList(),
            ),
            const SizedBox(height: 44),
            _DesktopRecentSection(
              tracks: state.recentlyPlayed.take(6).toList(),
            ),
          ],
          if (state.albums.isNotEmpty || state.randomPicks.isNotEmpty) ...[
            const SizedBox(height: 44),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.albums.isNotEmpty)
                  Expanded(
                    child: _LatestAlbumsSection(
                      albums: state.albums.take(3).toList(),
                    ),
                  ),
                if (state.albums.isNotEmpty && state.randomPicks.isNotEmpty)
                  const SizedBox(width: 32),
                if (state.randomPicks.isNotEmpty)
                  Expanded(
                    child: _RandomExploreCard(albums: state.randomPicks),
                  ),
              ],
            ),
          ],
          if (state.mostPlayed.isNotEmpty) ...[
            const SizedBox(height: 44),
            _DesktopMostPlayedSection(
              tracks: state.mostPlayed.take(6).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileHomeContent extends StatelessWidget {
  const _MobileHomeContent({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final continueTrack = state.recentlyPlayed.firstOrNull;
    return RefreshIndicator(
      onRefresh: context.read<HomeCubit>().load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacingTokens.pageHorizontalCompact,
          AppSpacingTokens.pageHorizontalCompact,
          AppSpacingTokens.pageHorizontalCompact,
          40,
        ),
        children: [
          const _MobileHomeTitle(),
          const SizedBox(height: 24),
          if (state.errorMessage != null) ...[
            _HomeInlineError(message: state.errorMessage!),
            const SizedBox(height: 24),
          ],
          if (continueTrack != null) ...[
            _MobileContinueCard(track: continueTrack),
            const SizedBox(height: 32),
          ],
          if (state.recentlyPlayed.isNotEmpty) ...[
            _MobileRecentSection(tracks: state.recentlyPlayed.take(2).toList()),
            const SizedBox(height: 32),
          ],
          if (state.mostPlayed.isNotEmpty)
            _MobileMostPlayedSection(tracks: state.mostPlayed.take(3).toList()),
          if (state.mostPlayed.isNotEmpty &&
              (state.albums.isNotEmpty || state.randomPicks.isNotEmpty))
            const SizedBox(height: 32),
          if (state.albums.isNotEmpty) ...[
            _LatestAlbumsSection(albums: state.albums.take(3).toList()),
            if (state.randomPicks.isNotEmpty) const SizedBox(height: 32),
          ],
          if (state.randomPicks.isNotEmpty)
            _RandomExploreCard(albums: state.randomPicks),
        ],
      ),
    );
  }
}

class _MobileHomeTitle extends StatelessWidget {
  const _MobileHomeTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      '首页',
      key: const ValueKey('v3-mobile-home-title'),
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontSize: 31,
        height: 41 / 31,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.62,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class _DesktopContinueSection extends StatelessWidget {
  const _DesktopContinueSection({required this.tracks});

  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '继续播放',
          action: TextButton(
            onPressed: () => context.push('/history'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('查看全部'),
                Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tracks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 24),
            itemBuilder: (context, index) => SizedBox(
              width: 360,
              child: _DesktopContinueCard(
                track: tracks[index],
                queue: tracks,
                index: index,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopContinueCard extends StatelessWidget {
  const _DesktopContinueCard({
    required this.track,
    required this.queue,
    required this.index,
  });

  final MusicTrack track;
  final List<MusicTrack> queue;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.md),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
          context,
          tracks: queue,
          startIndex: index,
        ),
        child: Row(
          children: [
            CachedArtwork(
              imageUrl: track.artworkUrl,
              size: 120,
              borderRadius: 0,
              semanticLabel: '${MediaDisplayText.trackTitle(track.title)}封面',
              sourceContext: ArtworkSourceContext.track(track),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MediaDisplayText.trackTitle(track.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MediaDisplayText.artistName(track.artistName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    _CurrentTrackProgress(trackId: track.id),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentTrackProgress extends StatelessWidget {
  const _CurrentTrackProgress({required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      PlayerCubit,
      PlayerViewState,
      ({String? id, Duration position, Duration duration})
    >(
      selector: (state) => (
        id: state.currentTrack?.id,
        position: state.position,
        duration: state.duration,
      ),
      builder: (context, value) {
        final total = value.duration.inMilliseconds;
        final progress = value.id == trackId && total > 0
            ? (value.position.inMilliseconds / total).clamp(0.0, 1.0)
            : 0.0;
        return LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          borderRadius: BorderRadius.circular(AppRadiusTokens.full),
        );
      },
    );
  }
}

class _DesktopRecentSection extends StatelessWidget {
  const _DesktopRecentSection({required this.tracks});

  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '最近播放'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050 ? 6 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 24,
                childAspectRatio: 0.76,
              ),
              itemCount: tracks.take(columns).length,
              itemBuilder: (context, index) => _RecentArtworkCard(
                track: tracks[index],
                queue: tracks,
                index: index,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecentArtworkCard extends StatelessWidget {
  const _RecentArtworkCard({
    required this.track,
    required this.queue,
    required this.index,
  });

  final MusicTrack track;
  final List<MusicTrack> queue;
  final int index;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadiusTokens.md),
      onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
        context,
        tracks: queue,
        startIndex: index,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => CachedArtwork(
                imageUrl: track.artworkUrl,
                size: constraints.maxWidth,
                borderRadius: 12,
                semanticLabel: '${MediaDisplayText.trackTitle(track.title)}封面',
                sourceContext: ArtworkSourceContext.track(track),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            MediaDisplayText.trackTitle(track.title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            MediaDisplayText.artistName(track.artistName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LatestAlbumsSection extends StatelessWidget {
  const _LatestAlbumsSection({required this.albums});

  final List<MusicAlbum> albums;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '最新添加'),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacingTokens.inlineGap),
            child: Column(
              children: [
                for (final album in albums) _LatestAlbumRow(album: album),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestAlbumRow extends StatelessWidget {
  const _LatestAlbumRow({required this.album});

  final MusicAlbum album;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadiusTokens.sm),
      onTap: () => context.push('/album/${album.id}', extra: album),
      child: SizedBox(
        height: AppSpacingTokens.listTileHeight.toDouble(),
        child: Row(
          children: [
            CachedArtwork(
              imageUrl: album.artworkUrl,
              size: 40,
              borderRadius: 4,
              semanticLabel: '${MediaDisplayText.albumTitle(album.title)}封面',
              sourceContext: ArtworkSourceContext.album(album),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MediaDisplayText.albumTitle(album.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    MediaDisplayText.artistName(album.artistName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '${album.trackCount} 首',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _RandomExploreCard extends StatelessWidget {
  const _RandomExploreCard({required this.albums});

  final List<MusicAlbum> albums;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '推荐随机'),
        const SizedBox(height: 16),
        Material(
          color: Color.alphaBlend(
            colors.primaryContainer.withValues(alpha: 0.18),
            colors.surface,
          ),
          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              final album = albums.first;
              context.push('/album/${album.id}', extra: album);
            },
            child: SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacingTokens.sectionPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '随机探索',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '从你的完整媒体库中随机选择专辑',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      child: const Icon(Icons.shuffle_rounded, size: 32),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileContinueCard extends StatelessWidget {
  const _MobileContinueCard({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2,
      child: Material(
        borderRadius: BorderRadius.circular(AppRadiusTokens.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
            context,
            tracks: [track],
            startIndex: 0,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => CachedArtwork(
                  imageUrl: track.artworkUrl,
                  size: constraints.maxWidth,
                  borderRadius: 0,
                  semanticLabel:
                      '${MediaDisplayText.trackTitle(track.title)}封面',
                  sourceContext: ArtworkSourceContext.track(track),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColorTokens.overlayDarkHeavy,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '继续播放',
                            style: TextStyle(
                              color: AppColorTokens.onDarkOverlayMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            MediaDisplayText.trackTitle(track.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColorTokens.onDarkOverlayStrong,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${MediaDisplayText.artistName(track.artistName)} · ${MediaDisplayText.albumTitle(track.albumTitle)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColorTokens.onDarkOverlayMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Icon(Icons.play_arrow_rounded, size: 24),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CurrentTrackProgress(trackId: track.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileRecentSection extends StatelessWidget {
  const _MobileRecentSection({required this.tracks});

  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '最近播放',
          action: TextButton(
            onPressed: () => context.push('/history'),
            child: const Text('查看全部'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < tracks.length; index++) ...[
              if (index > 0) const SizedBox(width: 16),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 0.76,
                  child: _RecentArtworkCard(
                    track: tracks[index],
                    queue: tracks,
                    index: index,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MobileMostPlayedSection extends StatelessWidget {
  const _MobileMostPlayedSection({required this.tracks});

  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '最常播放'),
        const SizedBox(height: 16),
        for (var index = 0; index < tracks.length; index++)
          _MostPlayedRow(index: index, track: tracks[index], queue: tracks),
      ],
    );
  }
}

class _DesktopMostPlayedSection extends StatelessWidget {
  const _DesktopMostPlayedSection({required this.tracks});

  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('home-most-played-desktop'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '最常播放'),
        const SizedBox(height: AppSpacingTokens.sectionTitleBottomGap),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacingTokens.inlineGap),
            child: Column(
              children: [
                for (var index = 0; index < tracks.length; index++)
                  _MostPlayedRow(
                    index: index,
                    track: tracks[index],
                    queue: tracks,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MostPlayedRow extends StatelessWidget {
  const _MostPlayedRow({
    required this.index,
    required this.track,
    required this.queue,
  });

  final int index;
  final MusicTrack track;
  final List<MusicTrack> queue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadiusTokens.sm),
      onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
        context,
        tracks: queue,
        startIndex: index,
      ),
      child: SizedBox(
        height: AppSpacingTokens.listTileHeight.toDouble(),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            CachedArtwork(
              imageUrl: track.artworkUrl,
              size: 40,
              borderRadius: 6,
              semanticLabel: '${MediaDisplayText.trackTitle(track.title)}封面',
              sourceContext: ArtworkSourceContext.track(track),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MediaDisplayText.trackTitle(track.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    MediaDisplayText.artistName(track.artistName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => showTrackActionsSheet(context, track),
              tooltip: '更多操作',
              icon: const Icon(Icons.more_vert_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeInlineError extends StatelessWidget {
  const _HomeInlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(AppRadiusTokens.md),
        border: Border.all(color: colors.error.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacingTokens.buttonPaddingCompactH,
          vertical: AppSpacingTokens.listTileVPadding,
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: colors.error),
            const SizedBox(width: AppSpacingTokens.listTileVPadding),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: context.read<HomeCubit>().load,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

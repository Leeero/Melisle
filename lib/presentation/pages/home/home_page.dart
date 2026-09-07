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
import 'package:cross_platform_music_player/presentation/widgets/blurred_cover_background.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/app_skeleton.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/artwork_hover_overlay.dart';
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
                  style: _clickCursorButtonStyle,
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
                  style: _clickCursorButtonStyle,
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
          SliverPadding(
            padding: AppPageLayout.pagePadding(
              context,
              bottom: AppSpacingTokens.cardPadding,
            ),
            sliver: SliverToBoxAdapter(child: _MobileHomeTitle()),
          ),
        SliverPadding(
          padding: AppPageLayout.pagePadding(context),
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
    final discoveryAlbum = _homeDiscoveryAlbum(state);
    final latestAlbums = state.albums
        .where((album) => album.id != discoveryAlbum?.id)
        .take(6)
        .toList();
    return RefreshIndicator(
      onRefresh: context.read<HomeCubit>().load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (state.errorMessage != null) ...[
            Padding(
              padding: AppPageLayout.pagePadding(context, bottom: 0),
              child: _HomeInlineError(message: state.errorMessage!),
            ),
            const SizedBox(height: 24),
          ],
          if (discoveryAlbum != null)
            Padding(
              padding: AppPageLayout.pagePadding(context, top: 32, bottom: 0),
              child: _DesktopDiscoveryHero(album: discoveryAlbum),
            ),
          if (state.recentlyPlayed.isNotEmpty) ...[
            Padding(
              padding: AppPageLayout.pagePadding(context, top: 32),
              child: _DesktopRecentSection(
                tracks: state.recentlyPlayed.take(6).toList(),
              ),
            ),
          ],
          if (latestAlbums.isNotEmpty) ...[
            Padding(
              padding: AppPageLayout.pagePadding(context, top: 20),
              child: _DesktopLatestAlbumsSection(albums: latestAlbums),
            ),
          ],
          if (state.mostPlayed.isNotEmpty) ...[
            Padding(
              padding: AppPageLayout.pagePadding(context, top: 20),
              child: _DesktopMostPlayedSection(
                tracks: state.mostPlayed.take(6).toList(),
              ),
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
    final discoveryAlbum = _homeDiscoveryAlbum(state);
    final latestAlbums = state.albums
        .where((album) => album.id != discoveryAlbum?.id)
        .take(3)
        .toList();
    return RefreshIndicator(
      onRefresh: context.read<HomeCubit>().load,
      child: ListView(
        padding: AppPageLayout.pagePadding(context),
        children: [
          const _MobileHomeTitle(),
          const SizedBox(height: 24),
          if (state.errorMessage != null) ...[
            _HomeInlineError(message: state.errorMessage!),
            const SizedBox(height: 24),
          ],
          if (discoveryAlbum != null) ...[
            _MobileDiscoveryCard(album: discoveryAlbum),
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
          if (latestAlbums.isNotEmpty)
            _LatestAlbumsSection(albums: latestAlbums),
        ],
      ),
    );
  }
}

MusicAlbum? _homeDiscoveryAlbum(HomeState state) {
  return state.randomPicks.firstOrNull ?? state.albums.firstOrNull;
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

class _DesktopDiscoveryHero extends StatelessWidget {
  const _DesktopDiscoveryHero({required this.album});

  final MusicAlbum album;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      key: const ValueKey('home-discovery-hero'),
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadiusTokens.xl),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 312,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BlurredCoverBackground(
              imageUrl: album.artworkUrl,
              sourceContext: ArtworkSourceContext.album(album),
            ),
            ColoredBox(color: colors.scrim.withValues(alpha: 0.42)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.scrim.withValues(alpha: 0.78),
                    colors.scrim.withValues(alpha: 0.48),
                    colors.scrim.withValues(alpha: 0.24),
                  ],
                  stops: const [0, 0.58, 1],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 760 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.15;
                  final artworkSize = constraints.maxHeight.clamp(176.0, 228.0);
                  return Row(
                    children: [
                      Expanded(
                        child: _DesktopDiscoveryContent(
                          album: album,
                          compact: compact,
                        ),
                      ),
                      SizedBox(width: compact ? 28 : 40),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppRadiusTokens.lg,
                          ),
                          border: Border.all(
                            color: AppColorTokens.onDarkOverlayStrong
                                .withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.30),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: CachedArtwork(
                          imageUrl: album.artworkUrl,
                          size: artworkSize,
                          borderRadius: AppRadiusTokens.lg,
                          semanticLabel:
                              '${MediaDisplayText.albumTitle(album.title)}封面',
                          sourceContext: ArtworkSourceContext.album(album),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopDiscoveryContent extends StatelessWidget {
  const _DesktopDiscoveryContent({required this.album, required this.compact});

  final MusicAlbum album;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: AppColorTokens.onDarkOverlayStrong,
            ),
            const SizedBox(width: 9),
            Text(
              '为你发现',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColorTokens.onDarkOverlayMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          MediaDisplayText.albumTitle(album.title),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: AppColorTokens.onDarkOverlayStrong,
            fontSize: compact ? 30 : 36,
            height: 1.12,
            letterSpacing: -0.72,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          MediaDisplayText.artistName(album.artistName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColorTokens.onDarkOverlayMuted,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 12),
          Text(
            '从你的音乐库中随机挑选一张专辑，换个心情，从这里开始。',
            maxLines: 2,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColorTokens.onDarkOverlayMuted,
            ),
          ),
        ],
        SizedBox(height: compact ? 16 : 22),
        Row(
          children: [
            _DiscoveryActionButton(
              key: const ValueKey('home-open-album-action'),
              onPressed: () => context.push('/album/${album.id}', extra: album),
              icon: Icons.album_rounded,
              label: '打开专辑',
              primary: true,
            ),
            const SizedBox(width: 12),
            _DiscoveryActionButton(
              key: const ValueKey('home-browse-albums-action'),
              onPressed: () => context.push('/library?tab=albums'),
              icon: Icons.arrow_forward_rounded,
              label: compact ? '浏览全部' : '浏览全部专辑',
            ),
          ],
        ),
      ],
    );
  }
}

class _DiscoveryActionButton extends StatelessWidget {
  const _DiscoveryActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.primary = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final foreground = primary
        ? AppColorTokens.overlayDarkHeavy
        : AppColorTokens.onDarkOverlayStrong;
    final style = TextButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: primary
          ? AppColorTokens.onDarkOverlayStrong
          : AppColorTokens.onDarkOverlayStrong.withValues(alpha: 0.08),
      foregroundColor: foreground,
      side: primary
          ? BorderSide.none
          : BorderSide(
              color: AppColorTokens.onDarkOverlayStrong.withValues(alpha: 0.26),
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.sm),
      ),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 15,
        height: 1,
        fontWeight: FontWeight.w600,
      ),
    ).merge(_clickCursorButtonStyle);

    return TextButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 20,
            child: Center(child: Icon(icon, size: 18)),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _DesktopLatestAlbumsSection extends StatelessWidget {
  const _DesktopLatestAlbumsSection({required this.albums});

  final List<MusicAlbum> albums;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '最新添加',
          action: TextButton(
            onPressed: () => context.push('/library?tab=albums'),
            style: _clickCursorButtonStyle,
            child: const Text('查看全部'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: albums.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, index) => SizedBox(
              width: 156,
              child: _DesktopLatestAlbumCard(album: albums[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopRecentSection extends StatelessWidget {
  const _DesktopRecentSection({required this.tracks});

  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('home-recent-desktop'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '最近播放',
          action: TextButton(
            onPressed: () => context.push('/history'),
            style: _clickCursorButtonStyle,
            child: const Text('查看全部'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tracks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, index) => SizedBox(
              width: 156,
              child: _RecentArtworkCard(
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

class _DesktopLatestAlbumCard extends StatefulWidget {
  const _DesktopLatestAlbumCard({required this.album});

  final MusicAlbum album;

  @override
  State<_DesktopLatestAlbumCard> createState() =>
      _DesktopLatestAlbumCardState();
}

class _DesktopLatestAlbumCardState extends State<_DesktopLatestAlbumCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final active = _hovered || _focused;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadiusTokens.md),
      onTap: () => context.push('/album/${album.id}', extra: album),
      onHover: (hovered) => setState(() => _hovered = hovered),
      onFocusChange: (focused) => setState(() => _focused = focused),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadiusTokens.md),
            child: SizedBox.square(
              dimension: 156,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedArtwork(
                    imageUrl: album.artworkUrl,
                    size: 156,
                    borderRadius: 0,
                    semanticLabel:
                        '${MediaDisplayText.albumTitle(album.title)}封面',
                    sourceContext: ArtworkSourceContext.album(album),
                  ),
                  ArtworkHoverOverlay(
                    visible: active,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedDefaultTextStyle(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.fast,
            style: theme.textTheme.bodyLarge!.copyWith(
              color: active ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(
              MediaDisplayText.albumTitle(album.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            MediaDisplayText.artistName(album.artistName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecentArtworkCard extends StatefulWidget {
  const _RecentArtworkCard({
    required this.track,
    required this.queue,
    required this.index,
  });

  final MusicTrack track;
  final List<MusicTrack> queue;
  final int index;

  @override
  State<_RecentArtworkCard> createState() => _RecentArtworkCardState();
}

class _RecentArtworkCardState extends State<_RecentArtworkCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final active = _hovered || _focused;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadiusTokens.md),
      onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
        context,
        tracks: widget.queue,
        startIndex: widget.index,
      ),
      onHover: (hovered) => setState(() => _hovered = hovered),
      onFocusChange: (focused) => setState(() => _focused = focused),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => _RecentArtwork(
                track: track,
                size: constraints.maxWidth,
                showActionOverlay: active,
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedDefaultTextStyle(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.fast,
            style: theme.textTheme.bodyLarge!.copyWith(
              color: active ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(
              MediaDisplayText.trackTitle(track.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

class _RecentArtwork extends StatelessWidget {
  const _RecentArtwork({
    required this.track,
    required this.size,
    required this.showActionOverlay,
  });

  final MusicTrack track;
  final double size;
  final bool showActionOverlay;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      PlayerCubit,
      PlayerViewState,
      ({bool isCurrent, bool isPlaying})
    >(
      selector: (state) => (
        isCurrent: state.currentTrack?.id == track.id,
        isPlaying: state.isPlaying,
      ),
      builder: (context, playback) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedArtwork(
              imageUrl: track.artworkUrl,
              size: size,
              borderRadius: 12,
              semanticLabel: '${MediaDisplayText.trackTitle(track.title)}封面',
              sourceContext: ArtworkSourceContext.track(track),
            ),
            ArtworkHoverOverlay(
              visible: showActionOverlay,
              icon: Icons.play_arrow_rounded,
            ),
            if (playback.isCurrent)
              Positioned(
                left: 8,
                top: 8,
                child: Semantics(
                  label: playback.isPlaying ? '正在播放' : '当前曲目',
                  child: DecoratedBox(
                    key: ValueKey('home-current-track-${track.id}'),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadiusTokens.full),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            playback.isPlaying
                                ? Icons.graphic_eq_rounded
                                : Icons.music_note_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            playback.isPlaying ? '正在播放' : '当前曲目',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
      mouseCursor: SystemMouseCursors.click,
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

class _MobileDiscoveryCard extends StatelessWidget {
  const _MobileDiscoveryCard({required this.album});

  final MusicAlbum album;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.65,
      child: Material(
        key: const ValueKey('home-discovery-card'),
        borderRadius: BorderRadius.circular(AppRadiusTokens.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/album/${album.id}', extra: album),
          mouseCursor: SystemMouseCursors.click,
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => CachedArtwork(
                  imageUrl: album.artworkUrl,
                  size: constraints.maxWidth,
                  borderRadius: 0,
                  semanticLabel:
                      '${MediaDisplayText.albumTitle(album.title)}封面',
                  sourceContext: ArtworkSourceContext.album(album),
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
                bottom: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '为你发现',
                            style: TextStyle(
                              color: AppColorTokens.onDarkOverlayMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            MediaDisplayText.albumTitle(album.title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColorTokens.onDarkOverlayStrong,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            MediaDisplayText.artistName(album.artistName),
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
                      child: const Icon(Icons.arrow_forward_rounded, size: 24),
                    ),
                  ],
                ),
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
            style: _clickCursorButtonStyle,
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
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
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
            _HomeTrackActionsButton(track: track),
          ],
        ),
      ),
    );
  }
}

class _HomeTrackActionsButton extends StatelessWidget {
  const _HomeTrackActionsButton({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final buttonKey = GlobalKey();
    return IconButton(
      key: buttonKey,
      onPressed: () {
        final buttonContext = buttonKey.currentContext;
        if (buttonContext == null) return;
        showTrackActionsSheet(
          buttonContext,
          track,
          popoverStyle: TrackActionsPopoverStyle.recentPlayback,
        );
      },
      tooltip: '更多操作',
      mouseCursor: SystemMouseCursors.click,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.square(44)),
        fixedSize: WidgetStatePropertyAll(Size.square(44)),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide.none),
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      icon: const Icon(Icons.more_horiz_rounded, size: 18),
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
              style: _clickCursorButtonStyle,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

const _clickCursorButtonStyle = ButtonStyle(
  mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
);

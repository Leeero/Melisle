import 'dart:ui';

import 'package:cross_platform_music_player/application/usecases/fetch_latest_albums.dart';
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
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 微渐变背景 — 为毛玻璃搜索栏提供可模糊内容
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.07),
                    Colors.transparent,
                    Colors.transparent,
                    colorScheme.tertiary.withValues(alpha: 0.04),
                  ],
                  stops: const [0.0, 0.25, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return _buildBody(context, state);
              },
            ),
          ),
        ],
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
        // 搜索入口（毛玻璃）
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            6,
          ),
          sliver: SliverToBoxAdapter(child: _SearchEntry()),
        ),

        // 快捷入口：播放历史 + 我的收藏
        _quickEntryRow(context, horizontalPadding),

        // 最近播放（列表形式）
        if (state.recentlyPlayed.isNotEmpty)
          _trackListSection(
            context,
            title: '最近播放',
            tracks: state.recentlyPlayed,
            currentTrackId: currentTrackId,
            horizontalPadding: horizontalPadding,
            onViewAll: () => context.push('/history'),
          ),

        // 常听的歌（排行形式）
        if (state.mostPlayed.isNotEmpty)
          _rankedTrackListSection(
            context,
            title: '常听的歌',
            tracks: state.mostPlayed,
            currentTrackId: currentTrackId,
            horizontalPadding: horizontalPadding,
          ),

        // 最近加入（专辑列表形式）
        if (state.albums.isNotEmpty)
          _albumListSection(
            context,
            albums: state.albums,
            horizontalPadding: horizontalPadding,
          ),

        // 底部留白
        SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacingTokens.contentBottom),
        ),
      ],
    );
  }

  SliverPadding _quickEntryRow(BuildContext context, double horizontalPadding) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacingTokens.sectionGap,
      ),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            _QuickEntryTab(
              icon: Icons.history_rounded,
              label: '播放历史',
              onTap: () => context.push('/history'),
            ),
            const SizedBox(width: 8),
            _QuickEntryTab(
              icon: Icons.favorite_rounded,
              label: '我的收藏',
              onTap: () => context.push('/favorites'),
            ),
          ],
        ),
      ),
    );
  }

  /// 通用曲目列表区块（recentlyPlayed / mostPlayed 复用）
  SliverPadding _trackListSection(
    BuildContext context, {
    required String title,
    required List<MusicTrack> tracks,
    required String? currentTrackId,
    required double horizontalPadding,
    VoidCallback? onViewAll,
  }) {
    const maxDisplay = 8;
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
              action: onViewAll != null
                  ? TextButton(
                      onPressed: onViewAll,
                      child: const Text('查看全部'),
                    )
                  : null,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = displayTracks[index];
                final subtitle = track.albumTitle.isNotEmpty
                    ? '${track.artistName} · ${track.albumTitle}'
                    : track.artistName;
                return MusicTrackTile.list(
                  title: track.title,
                  subtitle: subtitle,
                  artworkUrl: track.artworkUrl,
                  onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                    context,
                    tracks: tracks,
                    startIndex: index,
                  ),
                );
              },
              childCount: displayTracks.length,
            ),
          ),
        ],
      ),
    );
  }

  /// 排行曲目列表区块（常听的歌 — 带排名序号）
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

  /// 最近加入专辑 — 列表形式
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
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: AppSectionTitleRow(
              title: '最近加入',
              padding: const EdgeInsets.only(bottom: 10),
              action: TextButton(
                onPressed: () => context.go('/library'),
                child: const Text('查看全部'),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final album = albums[index];
                return _AlbumListTile(
                  album: album,
                  onTap: () => context.push(
                    '/album/${album.id}',
                    extra: album,
                  ),
                );
              },
              childCount: albums.length,
            ),
          ),
        ],
      ),
    );
  }
}

/// 搜索入口 — 毛玻璃
class _SearchEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '搜索音乐',
      button: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadiusTokens.input),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.cardPadding + 2,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.input),
              ),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              backgroundColor: colorScheme.surface.withValues(alpha: 0.25),
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
                const SizedBox(width: AppSpacingTokens.cardPadding - 4),
                Expanded(
                  child: Text(
                    '搜索曲目、专辑、艺术家、歌单…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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

/// 快捷入口标签
class _QuickEntryTab extends StatelessWidget {
  const _QuickEntryTab({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
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

/// 排行曲目行（常听的歌使用）
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
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              // 排名序号
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
              // 封面
              CachedArtwork(
                imageUrl: track.artworkUrl,
                size: 44,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              // 标题 + 艺术家
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

/// 专辑列表条目
class _AlbumListTile extends StatelessWidget {
  const _AlbumListTile({
    required this.album,
    required this.onTap,
  });

  final MusicAlbum album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CachedArtwork(
        imageUrl: album.artworkUrl,
        size: 48,
        borderRadius: 14,
        semanticLabel: '《${album.title}》专辑封面',
      ),
      title: Text(
        album.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          album.artistName,
          if (album.year != null) '${album.year}',
          '${album.trackCount} 首',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

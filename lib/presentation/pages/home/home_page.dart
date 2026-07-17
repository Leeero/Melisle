import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_latest_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_random_albums.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_artist_card.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
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

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _showDesktopRecommendationTracks = false;

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
    final hasHomeData = _hasHomeData(state);
    if (state.status == HomeStatus.loading && !hasHomeData) {
      return const AppBodyStateView.loading();
    }

    if (state.status == HomeStatus.failure && !hasHomeData) {
      return AppBodyStateView.message(
        message: state.errorMessage ?? '加载失败',
        action: FilledButton.icon(
          onPressed: () => context.read<HomeCubit>().load(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重新加载'),
        ),
      );
    }

    if (!hasHomeData) {
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
    final compact = AppBreakpoints.isCompact(context);
    final recommendationAlbums = _recommendationAlbums(state);
    final recommendationTracks = _recommendationTracks(state);
    final recommendationArtwork = _recommendationArtwork(state);
    final recommendedArtists = _recommendedArtists(state);
    final showingDesktopRecommendationTracks =
        !compact &&
        _showDesktopRecommendationTracks &&
        recommendationTracks.isNotEmpty;

    if (showingDesktopRecommendationTracks) {
      return _RecommendationTracksDesktopView(
        tracks: recommendationTracks,
        artwork: recommendationArtwork,
        description: _trackCaption(recommendationTracks),
        currentTrackId: currentTrackId,
        onBackPressed: () =>
            setState(() => _showDesktopRecommendationTracks = false),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            compact ? 0 : 2,
          ),
          sliver: SliverToBoxAdapter(
            child: compact
                ? const _MobileHomeTitle()
                : const _DesktopHomeHeader(),
          ),
        ),

        if (state.errorMessage != null)
          _inlineErrorSection(
            context,
            message: state.errorMessage!,
            horizontalPadding: horizontalPadding,
          ),

        if (recommendationArtwork.isNotEmpty)
          _recommendationHeroSection(
            context,
            albums: recommendationAlbums,
            tracks: recommendationTracks,
            artwork: recommendationArtwork,
            horizontalPadding: horizontalPadding,
          ),

        if (compact) ...[
          if (state.recentlyPlayed.isNotEmpty)
            _recentTracksSection(
              context,
              tracks: state.recentlyPlayed,
              currentTrackId: currentTrackId,
              horizontalPadding: horizontalPadding,
            ),

          if (recommendedArtists.isNotEmpty)
            _artistListSection(
              context,
              artists: recommendedArtists,
              horizontalPadding: horizontalPadding,
            ),

          if (state.albums.isNotEmpty)
            _albumListSection(
              context,
              albums: state.albums,
              horizontalPadding: horizontalPadding,
            ),
        ] else ...[
          if (state.recentlyPlayed.isNotEmpty)
            _recentTracksSection(
              context,
              tracks: state.recentlyPlayed,
              currentTrackId: currentTrackId,
              horizontalPadding: horizontalPadding,
            ),

          if (state.albums.isNotEmpty)
            _albumListSection(
              context,
              albums: state.albums,
              horizontalPadding: horizontalPadding,
            ),

          if (recommendedArtists.isNotEmpty)
            _artistListSection(
              context,
              artists: recommendedArtists,
              horizontalPadding: horizontalPadding,
            ),
        ],

        SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacingTokens.contentBottom),
        ),
      ],
    );
  }

  bool _hasHomeData(HomeState state) {
    return state.albums.isNotEmpty ||
        state.randomPicks.isNotEmpty ||
        state.recentlyPlayed.isNotEmpty ||
        state.mostPlayed.isNotEmpty;
  }

  List<MusicAlbum> _recommendationAlbums(HomeState state) {
    final source = state.randomPicks.isNotEmpty
        ? state.randomPicks
        : state.albums;
    return source.take(6).toList();
  }

  List<MusicTrack> _recommendationTracks(HomeState state) {
    final source = state.recentlyPlayed.isNotEmpty
        ? state.recentlyPlayed
        : state.mostPlayed;
    return source.take(12).toList();
  }

  List<_ArtworkSeed> _recommendationArtwork(HomeState state) {
    final seeds = <_ArtworkSeed>[];
    final seen = <String>{};

    void addSeed(String id, String title, String artworkUrl) {
      if (!seen.add(id)) return;
      seeds.add(_ArtworkSeed(title: title, artworkUrl: artworkUrl));
    }

    for (final album in _recommendationAlbums(state)) {
      addSeed('album:${album.id}', album.title, album.artworkUrl);
      if (seeds.length >= 3) return seeds;
    }

    for (final track in _recommendationTracks(state)) {
      addSeed('track:${track.id}', track.title, track.artworkUrl);
      if (seeds.length >= 3) return seeds;
    }

    return seeds;
  }

  List<MusicArtist> _recommendedArtists(HomeState state) {
    final artists = <String, _ArtistDraft>{};

    void addArtist({
      required String? id,
      required String name,
      required String artworkUrl,
      int albumCount = 0,
      int trackCount = 0,
    }) {
      final normalizedId = id?.trim();
      final normalizedName = name.trim();
      if (normalizedId == null ||
          normalizedId.isEmpty ||
          normalizedName.isEmpty) {
        return;
      }
      final draft = artists.putIfAbsent(
        normalizedId,
        () => _ArtistDraft(
          id: normalizedId,
          name: normalizedName,
          artworkUrl: artworkUrl,
        ),
      );
      draft.albumCount += albumCount;
      draft.trackCount += trackCount;
      if (draft.artworkUrl.isEmpty && artworkUrl.isNotEmpty) {
        draft.artworkUrl = artworkUrl;
      }
    }

    for (final album in [...state.randomPicks, ...state.albums]) {
      addArtist(
        id: album.artistId,
        name: album.artistName,
        artworkUrl: album.artworkUrl,
        albumCount: 1,
        trackCount: album.trackCount,
      );
    }

    for (final track in [...state.recentlyPlayed, ...state.mostPlayed]) {
      addArtist(
        id: track.artistId,
        name: track.artistName,
        artworkUrl: track.artworkUrl,
        trackCount: 1,
      );
    }

    return artists.values.map((draft) => draft.toArtist()).take(8).toList();
  }

  SliverPadding _inlineErrorSection(
    BuildContext context, {
    required String message,
    required double horizontalPadding,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 14),
      sliver: SliverToBoxAdapter(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(AppRadiusTokens.card),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<HomeCubit>().load(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverPadding _recommendationHeroSection(
    BuildContext context, {
    required List<MusicAlbum> albums,
    required List<MusicTrack> tracks,
    required List<_ArtworkSeed> artwork,
    required double horizontalPadding,
  }) {
    final compact = AppBreakpoints.isCompact(context);
    final primaryAlbum = albums.isNotEmpty ? albums.first : null;
    final primaryTrack = tracks.isNotEmpty ? tracks.first : null;
    final title = primaryTrack != null
        ? '继续从《${primaryTrack.title}》播放'
        : primaryAlbum != null
        ? '从《${primaryAlbum.title}》开始今天'
        : '今日推荐';
    final description = tracks.isNotEmpty
        ? '基于最近播放和服务器记录，为你整理出 ${tracks.length} 首可以继续收听的歌曲。'
        : '从服务器推荐里挑出 ${albums.length} 张专辑，适合慢慢浏览、收藏和整理。';
    final caption = tracks.isNotEmpty
        ? _trackCaption(tracks)
        : '${albums.length} 张专辑 · ${albums.fold<int>(0, (sum, album) => sum + album.trackCount)} 首';

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        compact ? AppSpacingTokens.sectionGap : 32,
      ),
      sliver: SliverToBoxAdapter(
        child: _RecommendationHero(
          title: title,
          description: description,
          caption: caption,
          artwork: artwork,
          primaryLabel: tracks.isNotEmpty ? '播放推荐' : '打开推荐',
          onPrimaryPressed: tracks.isNotEmpty
              ? () => PlayerNavigation.playTracksAndOpenPlayer(
                  context,
                  tracks: tracks,
                  startIndex: 0,
                )
              : primaryAlbum == null
              ? null
              : () => context.push(
                  '/album/${primaryAlbum.id}',
                  extra: primaryAlbum,
                ),
          secondaryLabel: tracks.isNotEmpty ? '查看歌曲' : '查看专辑',
          onSecondaryPressed: () {
            if (tracks.isEmpty) {
              context.go('/library');
              return;
            }
            if (AppBreakpoints.usesWideContent(context)) {
              setState(() => _showDesktopRecommendationTracks = true);
              return;
            }
            _showRecommendationTracks(context, tracks);
          },
        ),
      ),
    );
  }

  Future<void> _showRecommendationTracks(
    BuildContext context,
    List<MusicTrack> tracks,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PlayerCubit>(),
        child: _RecommendationTracksSheet(
          tracks: tracks,
          description: _trackCaption(tracks),
          onTrackSelected: (index) => PlayerNavigation.playTracksAndOpenPlayer(
            context,
            tracks: tracks,
            startIndex: index,
          ),
        ),
      ),
    );
  }

  SliverPadding _recentTracksSection(
    BuildContext context, {
    required List<MusicTrack> tracks,
    required String? currentTrackId,
    required double horizontalPadding,
  }) {
    final compact = AppBreakpoints.isCompact(context);
    final maxDisplay = compact ? 8 : 5;
    final displayTracks = tracks.take(maxDisplay).toList();
    final cardWidth = compact ? 130.0 : 150.0;
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
              title: '继续播放',
              padding: EdgeInsets.only(bottom: compact ? 12 : 14),
              action: _HomeViewAllButton(
                onPressed: () => context.push('/history'),
              ),
            ),
          ),
          if (compact)
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
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final columnCount = _homeDesktopGridCount(
                  constraints.crossAxisExtent,
                  maxColumns: 5,
                );
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final track = displayTracks[index];
                    return _TrackGridCard(
                      track: track,
                      isCurrent: track.id == currentTrackId,
                      onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                        context,
                        tracks: tracks,
                        startIndex: index,
                      ),
                    );
                  }, childCount: displayTracks.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 22,
                    mainAxisExtent: _homeDesktopSquareCardExtent(
                      constraints.crossAxisExtent,
                      columnCount,
                    ),
                  ),
                );
              },
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
    final compact = AppBreakpoints.isCompact(context);
    final cardWidth = compact ? 150.0 : 184.0;
    final cardHeight = cardWidth + 58.0;

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
              title: '最近添加',
              padding: const EdgeInsets.only(bottom: 12),
              action: compact
                  ? null
                  : _HomeViewAllButton(onPressed: () => context.go('/library')),
            ),
          ),
          if (compact)
            SliverToBoxAdapter(
              child: SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: albums.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
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
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final columnCount = _homeDesktopGridCount(
                  constraints.crossAxisExtent,
                );
                return SliverGrid(
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
                    mainAxisExtent: _homeDesktopSquareCardExtent(
                      constraints.crossAxisExtent,
                      columnCount,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  SliverPadding _artistListSection(
    BuildContext context, {
    required List<MusicArtist> artists,
    required double horizontalPadding,
  }) {
    final compact = AppBreakpoints.isCompact(context);

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
              title: '推荐艺术家',
              padding: const EdgeInsets.only(bottom: 12),
              action: compact
                  ? null
                  : _HomeViewAllButton(
                      onPressed: () => context.go('/library?tab=artists'),
                    ),
            ),
          ),
          if (compact)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 174,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: artists.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return SizedBox(
                      width: 126,
                      child: MusicArtistGridCard(
                        artist: artist,
                        onTap: () =>
                            context.push('/artist/${artist.id}', extra: artist),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final columnCount = _homeDesktopGridCount(
                  constraints.crossAxisExtent,
                  minCardWidth: 148,
                );
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final artist = artists[index];
                    return MusicArtistGridCard(
                      artist: artist,
                      onTap: () =>
                          context.push('/artist/${artist.id}', extra: artist),
                    );
                  }, childCount: artists.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 22,
                    mainAxisExtent: _homeDesktopArtistCardExtent(
                      constraints.crossAxisExtent,
                      columnCount,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _trackCaption(List<MusicTrack> tracks) {
    final duration = tracks.fold<Duration>(
      Duration.zero,
      (sum, track) => sum + track.duration,
    );
    final durationLabel = _formatDuration(duration);
    if (durationLabel.isEmpty) {
      return '${tracks.length} 首';
    }
    return '${tracks.length} 首 · $durationLabel';
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '$hours 小时 $minutes 分钟';
    }
    if (hours > 0) return '$hours 小时';
    return '$minutes 分钟';
  }
}

int _homeDesktopGridCount(
  double width, {
  double minCardWidth = 160,
  int maxColumns = 7,
}) {
  final count =
      ((width + _homeDesktopGridGap) / (minCardWidth + _homeDesktopGridGap))
          .floor();
  return count.clamp(2, maxColumns).toInt();
}

const _homeDesktopGridGap = 18.0;

double _homeDesktopTileWidth(double width, int columnCount) {
  final totalGap = _homeDesktopGridGap * (columnCount - 1);
  return (width - totalGap) / columnCount;
}

double _homeDesktopSquareCardExtent(double width, int columnCount) {
  final tileWidth = _homeDesktopTileWidth(width, columnCount);
  return tileWidth + 66;
}

double _homeDesktopArtistCardExtent(double width, int columnCount) {
  final tileWidth = _homeDesktopTileWidth(width, columnCount);
  return tileWidth * 0.78 + 68;
}

class _RecommendationTracksDesktopView extends StatelessWidget {
  const _RecommendationTracksDesktopView({
    required this.tracks,
    required this.artwork,
    required this.description,
    required this.currentTrackId,
    required this.onBackPressed,
  });

  final List<MusicTrack> tracks;
  final List<_ArtworkSeed> artwork;
  final String description;
  final String? currentTrackId;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    final countLabel = '${tracks.length} 首';

    return Column(
      children: [
        Padding(
          padding: AppPageLayout.headerPadding(context),
          child: AppPageHeader(
            title: '今日推荐',
            description: '根据最近播放和服务器记录整理',
            leading: AppBackButton(onPressed: onBackPressed),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MetaPill(label: description, size: MetaPillSize.compact),
                const SizedBox(width: 10),
                AppActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: '播放全部',
                  tone: AppActionButtonTone.primary,
                  onPressed: () => unawaited(
                    PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: tracks,
                      startIndex: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AppActionButton(
                  icon: Icons.shuffle_rounded,
                  label: '随机播放',
                  onPressed: () => unawaited(
                    PlayerNavigation.shuffleTracksAndOpenPlayer(
                      context,
                      tracks: tracks,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              24,
            ),
            children: [
              _RecommendationTracksOverview(
                tracks: tracks,
                artwork: artwork,
                description: description,
              ),
              const SizedBox(height: 24),
              AppSectionTitleRow(
                title: '推荐歌曲',
                badge: MetaPill(label: countLabel, size: MetaPillSize.compact),
              ),
              MusicTrackTable(
                tracks: tracks,
                currentTrackId: currentTrackId,
                showActionBar: false,
                onTrackTap: (index, _) => unawaited(
                  PlayerNavigation.playTracksAndOpenPlayer(
                    context,
                    tracks: tracks,
                    startIndex: index,
                  ),
                ),
                onAddTrackToQueue: (track) => unawaited(
                  _addRecommendationTracksToQueue(context, [track]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationTracksOverview extends StatelessWidget {
  const _RecommendationTracksOverview({
    required this.tracks,
    required this.artwork,
    required this.description,
  });

  final List<MusicTrack> tracks;
  final List<_ArtworkSeed> artwork;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryTrack = tracks.first;
    final title = '继续从《${primaryTrack.title}》开始';
    final subtitle = primaryTrack.albumTitle.isNotEmpty
        ? '${primaryTrack.artistName} · ${primaryTrack.albumTitle}'
        : primaryTrack.artistName;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadiusTokens.desktopXl),
        border: Border.all(
          color: Color.alphaBlend(
            theme.musicTeal.withValues(alpha: 0.18),
            colorScheme.outlineVariant,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              theme.musicWarmSoft.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.30 : 0.46,
              ),
              colorScheme.surface,
            ),
            colorScheme.surfaceContainerHigh,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadiusTokens.desktopXl),
        child: Stack(
          children: [
            Positioned(
              right: -72,
              top: -96,
              child: _HomeRadialWash(
                size: 240,
                color: theme.musicTeal.withValues(alpha: 0.18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '推荐队列',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 26,
                            height: 1.14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        MetaPill(
                          label: description,
                          size: MetaPillSize.compact,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 34),
                  SizedBox(
                    width: 260,
                    height: 154,
                    child: _RecommendationStack(
                      artwork: artwork,
                      caption: description,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _addRecommendationTracksToQueue(
  BuildContext context,
  List<MusicTrack> tracks,
) async {
  if (tracks.isEmpty) return;
  final player = context.read<PlayerCubit>();
  for (final track in tracks) {
    await player.addToQueue(track);
  }
  if (!context.mounted) return;
  final message = tracks.length == 1
      ? '已加入队列：${tracks.first.title}'
      : '已加入队列：${tracks.length} 首歌曲';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

class _RecommendationTracksSheet extends StatelessWidget {
  const _RecommendationTracksSheet({
    required this.tracks,
    required this.description,
    required this.onTrackSelected,
  });

  final List<MusicTrack> tracks;
  final String description;
  final Future<void> Function(int index) onTrackSelected;

  @override
  Widget build(BuildContext context) {
    final currentTrackId = context.watch<PlayerCubit>().state.currentTrack?.id;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.36,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return AppSheetScaffold(
          title: '今日推荐',
          description: description,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          trailing: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
          child: Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              itemCount: tracks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final track = tracks[index];
                final subtitle = track.albumTitle.isNotEmpty
                    ? '${track.artistName} · ${track.albumTitle}'
                    : track.artistName;

                return MusicTrackTile.row(
                  title: track.title,
                  subtitle: subtitle,
                  artworkUrl: track.artworkUrl,
                  isCurrent: track.id == currentTrackId,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await onTrackSelected(index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DesktopHomeHeader extends StatelessWidget {
  const _DesktopHomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '首页',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '欢迎回来，继续聆听你的音乐',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.muted,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHomeTitle extends StatelessWidget {
  const _MobileHomeTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
      child: Text(
        '首页',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontSize: 31,
          height: 1.12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _RecommendationHero extends StatelessWidget {
  const _RecommendationHero({
    required this.title,
    required this.description,
    required this.caption,
    required this.artwork,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.onPrimaryPressed,
  });

  final String title;
  final String description;
  final String caption;
  final List<_ArtworkSeed> artwork;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final radius = compact
        ? AppRadiusTokens.mobileXl
        : AppRadiusTokens.desktopXl;
    final shadowAlpha = compact
        ? (theme.brightness == Brightness.dark ? 0.10 : 0.04)
        : (theme.brightness == Brightness.dark ? 0.18 : 0.06);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: shadowAlpha),
            blurRadius: compact ? 12 : 18,
            offset: compact ? const Offset(0, 4) : const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, colorScheme.surfaceContainerHigh],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned(
              right: -80,
              bottom: -120,
              child: _HomeRadialWash(
                size: 300,
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              right: 18,
              top: -54,
              child: _HomeRadialWash(
                size: 240,
                color: colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: compact ? 0 : 220),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 18 : 28,
                  vertical: compact ? 18 : 26,
                ),
                child: compact
                    ? _CompactRecommendationCard(
                        seed: artwork.first,
                        title: title,
                        description: description,
                        primaryLabel: primaryLabel,
                        secondaryLabel: secondaryLabel,
                        onPrimaryPressed: onPrimaryPressed,
                        onSecondaryPressed: onSecondaryPressed,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _RecommendationCopy(
                              title: title,
                              description: description,
                              primaryLabel: primaryLabel,
                              secondaryLabel: secondaryLabel,
                              onPrimaryPressed: onPrimaryPressed,
                              onSecondaryPressed: onSecondaryPressed,
                            ),
                          ),
                          const SizedBox(width: 28),
                          SizedBox(
                            width: 280,
                            height: 166,
                            child: _RecommendationStack(
                              artwork: artwork,
                              caption: caption,
                            ),
                          ),
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

class _CompactRecommendationCard extends StatelessWidget {
  const _CompactRecommendationCard({
    required this.seed,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.onPrimaryPressed,
  });

  final _ArtworkSeed seed;
  final String title;
  final String description;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CachedArtwork(
          imageUrl: seed.artworkUrl,
          size: 86,
          borderRadius: 18,
          semanticLabel: '《${seed.title}》封面',
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日推荐',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  height: 1.14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onPrimaryPressed,
                    icon: const Icon(Icons.play_arrow_rounded, size: 15),
                    label: Text(primaryLabel),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onSecondaryPressed,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    child: Text(secondaryLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationCopy extends StatelessWidget {
  const _RecommendationCopy({
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.onPrimaryPressed,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = AppBreakpoints.isCompact(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '今日推荐',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            title,
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: compact ? 25 : 32,
              height: compact ? 1.14 : 1.08,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            description,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (compact)
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onPrimaryPressed,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(primaryLabel),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSecondaryPressed,
                child: Text(secondaryLabel),
              ),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: onPrimaryPressed,
                icon: const Icon(Icons.play_arrow_rounded, size: 19),
                label: Text(primaryLabel),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onSecondaryPressed,
                child: Text(secondaryLabel),
              ),
            ],
          ),
      ],
    );
  }
}

class _RecommendationStack extends StatelessWidget {
  const _RecommendationStack({required this.artwork, required this.caption});

  final List<_ArtworkSeed> artwork;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final seeds = artwork.take(3).toList();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (seeds.isNotEmpty)
          Positioned(
            left: 18,
            bottom: 18,
            child: Transform.rotate(
              angle: -0.14,
              child: _StackedCover(seed: seeds[0], size: 124, opacity: 0.72),
            ),
          ),
        if (seeds.length >= 2)
          Positioned(
            left: 64,
            top: 0,
            child: _StackedCover(seed: seeds[1], size: 152),
          ),
        if (seeds.length >= 3)
          Positioned(
            right: 18,
            bottom: 14,
            child: Transform.rotate(
              angle: 0.14,
              child: _StackedCover(seed: seeds[2], size: 124, opacity: 0.72),
            ),
          ),
        Positioned(right: 0, bottom: 0, child: _HeroCaption(label: caption)),
      ],
    );
  }
}

class _StackedCover extends StatelessWidget {
  const _StackedCover({
    required this.seed,
    required this.size,
    this.opacity = 1,
  });

  final _ArtworkSeed seed;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColorTokens.lightSurface.withValues(alpha: 0.36),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: CachedArtwork(
          imageUrl: seed.artworkUrl,
          size: size,
          borderRadius: 22,
          semanticLabel: '《${seed.title}》封面',
        ),
      ),
    );
  }
}

class _HeroCaption extends StatelessWidget {
  const _HeroCaption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadiusTokens.button),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TrackGridCard extends StatefulWidget {
  const _TrackGridCard({
    required this.track,
    required this.isCurrent,
    required this.onTap,
  });

  final MusicTrack track;
  final bool isCurrent;
  final Future<void> Function() onTap;

  @override
  State<_TrackGridCard> createState() => _TrackGridCardState();
}

class _TrackGridCardState extends State<_TrackGridCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final track = widget.track;
    final subtitle = track.albumTitle.isNotEmpty
        ? '${track.artistName} · ${track.albumTitle}'
        : track.artistName;

    return Semantics(
      label: '播放《${track.title}》',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          scale: _pressed
              ? 0.992
              : _hovered
              ? 1.012
              : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadiusTokens.card),
                    onTap: () => widget.onTap(),
                    onHighlightChanged: (pressed) =>
                        setState(() => _pressed = pressed),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedArtwork(
                          imageUrl: track.artworkUrl,
                          size: 240,
                          borderRadius: AppRadiusTokens.card,
                          semanticLabel: '《${track.title}》封面',
                        ),
                        if (widget.isCurrent)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        AnimatedOpacity(
                          duration: AppMotion.micro,
                          curve: AppMotion.enter,
                          opacity: _hovered ? 1 : 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColorTokens.darkScaffold.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadiusTokens.card,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 42,
                                color: AppColorTokens.lightScaffold.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
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

class _HomeViewAllButton extends StatelessWidget {
  const _HomeViewAllButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = AppBreakpoints.isCompact(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: compact ? 14 : 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return Semantics(
      label: '查看全部',
      button: true,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 2),
          ),
          visualDensity: VisualDensity.compact,
          foregroundColor: WidgetStatePropertyAll(theme.colorScheme.primary),
          textStyle: WidgetStateProperty.resolveWith((states) {
            final hovered = !compact && states.contains(WidgetState.hovered);
            return textStyle?.copyWith(
              decoration: hovered
                  ? TextDecoration.underline
                  : TextDecoration.none,
            );
          }),
        ),
        child: const Text('查看全部'),
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

class _HomeRadialWash extends StatelessWidget {
  const _HomeRadialWash({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 0.68],
          ),
        ),
      ),
    );
  }
}

class _ArtworkSeed {
  const _ArtworkSeed({required this.title, required this.artworkUrl});

  final String title;
  final String artworkUrl;
}

class _ArtistDraft {
  _ArtistDraft({
    required this.id,
    required this.name,
    required this.artworkUrl,
  });

  final String id;
  final String name;
  String artworkUrl;
  int albumCount = 0;
  int trackCount = 0;

  MusicArtist toArtist() {
    return MusicArtist(
      id: id,
      name: name,
      artworkUrl: artworkUrl,
      albumCount: albumCount,
      trackCount: trackCount,
    );
  }
}

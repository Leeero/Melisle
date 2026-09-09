import 'package:cross_platform_music_player/application/usecases/fetch_artist_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_artist_top_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/detail_route_navigation.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_text_tabs.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ArtistDetailPage extends StatelessWidget {
  const ArtistDetailPage({super.key, required this.artistId, this.artist});

  final String artistId;
  final MusicArtist? artist;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final repository = context.read<MusicRepository>();
        return ArtistCubit(
          fetchArtistAlbums: FetchArtistAlbums(repository),
          fetchArtistTopTracks: FetchArtistTopTracks(repository),
        )..load(artistId, seed: artist);
      },
      child: _ArtistDetailView(artistId: artistId, seed: artist),
    );
  }
}

class _ArtistDetailView extends StatefulWidget {
  const _ArtistDetailView({required this.artistId, required this.seed});

  final String artistId;
  final MusicArtist? seed;

  @override
  State<_ArtistDetailView> createState() => _ArtistDetailViewState();
}

enum _ArtistDetailTab { tracks, albums }

class _ArtistDetailViewState extends State<_ArtistDetailView> {
  _ArtistDetailTab _selectedTab = _ArtistDetailTab.tracks;

  @override
  Widget build(BuildContext context) {
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<ArtistCubit, ArtistState>(
      builder: (context, state) {
        final isWide = AppBreakpoints.usesWideContent(context);
        final artist = state.artist ?? widget.seed;
        final hasMiniPlayer = currentTrackId != null;

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                if (isWide)
                  SliverPadding(
                    padding: AppPageLayout.pagePadding(context, bottom: 0),
                    sliver: SliverToBoxAdapter(
                      child: AppDetailBackNav(
                        label: '返回上一页',
                        onPressed: () => _goBackToLibrary(context),
                      ),
                    ),
                  ),
                if (!isWide)
                  SliverPadding(
                    padding: AppPageLayout.pagePadding(
                      context,
                      bottom: AppSpacingTokens.compactGap,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: AppDetailBackNav(
                        onPressed: () => _goBackToLibrary(context),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: isWide
                      ? AppPageLayout.pagePadding(
                          context,
                          bottom: AppPageLayout.sectionGap,
                        )
                      : AppPageLayout.sectionPadding(context, bottom: 24),
                  sliver: SliverToBoxAdapter(
                    child: _ArtistHero(
                      artist: artist,
                      albumCount: state.albums.length,
                      topTrackCount: state.topTracks.length,
                    ),
                  ),
                ),
                if (state.status == ArtistStatus.loading && artist == null)
                  const AppSliverStateView.loading(
                    title: '正在加载歌手',
                    description: '正在从你的媒体库获取作品。',
                  ),
                if (state.status == ArtistStatus.failure)
                  AppSliverStateView.message(
                    message: state.errorMessage ?? '加载歌手失败',
                    title: '暂时无法加载歌手',
                    description: '请检查连接后重试。',
                    icon: Icons.error_outline_rounded,
                    action: FilledButton(
                      onPressed: () => context.read<ArtistCubit>().load(
                        widget.artistId,
                        seed: widget.seed,
                      ),
                      child: const Text('重试'),
                    ),
                  ),
                if (state.status != ArtistStatus.loading &&
                    state.status != ArtistStatus.failure) ...[
                  SliverPadding(
                    padding: AppPageLayout.sectionPadding(context, bottom: 16),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextTabs<_ArtistDetailTab>(
                              selectedValue: _selectedTab,
                              onChanged: (tab) =>
                                  setState(() => _selectedTab = tab),
                              items: [
                                AppTextTabItem<_ArtistDetailTab>(
                                  value: _ArtistDetailTab.tracks,
                                  label: '歌曲',
                                  count: state.topTracks.length,
                                ),
                                AppTextTabItem<_ArtistDetailTab>(
                                  value: _ArtistDetailTab.albums,
                                  label: '专辑',
                                  count: state.albums.length,
                                ),
                              ],
                            ),
                          ),
                          if (_selectedTab == _ArtistDetailTab.tracks &&
                              state.topTracks.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            AppActionButton(
                              icon: Icons.play_arrow_rounded,
                              label: '播放全部',
                              tone: AppActionButtonTone.primary,
                              onPressed: () =>
                                  _playArtistTopTracks(context, state),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_selectedTab == _ArtistDetailTab.tracks)
                    ..._trackSlivers(
                      state,
                      currentTrackId,
                      isWide,
                      hasMiniPlayer,
                    )
                  else
                    ..._albumSlivers(state, isWide, hasMiniPlayer),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _trackSlivers(
    ArtistState state,
    String? currentTrackId,
    bool isWide,
    bool hasMiniPlayer,
  ) {
    if (state.topTracks.isEmpty) {
      return const [AppSliverStateView.message(message: '这位歌手暂无歌曲。')];
    }

    return [
      SliverPadding(
        padding: isWide
            ? AppPageLayout.sectionPadding(context, bottom: 16)
            : const EdgeInsets.fromLTRB(
                AppSpacingTokens.pageHorizontalCompact,
                0,
                AppSpacingTokens.pageHorizontalCompact,
                0,
              ),
        sliver: isWide
            ? SliverToBoxAdapter(
                child: MusicTrackTable(
                  tracks: state.topTracks,
                  currentTrackId: currentTrackId,
                  showActionBar: false,
                  trackActionsContext: TrackActionsContext.artist,
                  onTrackTap: (index, _) =>
                      PlayerNavigation.playTracksAndOpenPlayer(
                        context,
                        tracks: state.topTracks,
                        startIndex: index,
                      ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final track = state.topTracks[index];
                  return MusicTrackTile.row(
                    isCurrent: track.id == currentTrackId,
                    artworkUrl: track.artworkUrl,
                    title: MediaDisplayText.trackTitle(track.title),
                    subtitle: _artistTrackSubtitle(track),
                    onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: state.topTracks,
                      startIndex: index,
                    ),
                    onLongPress: () => showTrackActionsSheet(
                      context,
                      track,
                      source: TrackActionsContext.artist,
                    ),
                    onMore: () => showTrackActionsSheet(
                      context,
                      track,
                      source: TrackActionsContext.artist,
                    ),
                  );
                }, childCount: state.topTracks.length),
              ),
      ),
      if (!isWide)
        SliverToBoxAdapter(
          child: SizedBox(height: _contentBottomInset(context, hasMiniPlayer)),
        ),
    ];
  }

  List<Widget> _albumSlivers(
    ArtistState state,
    bool isWide,
    bool hasMiniPlayer,
  ) {
    if (state.albums.isEmpty) {
      return const [AppSliverStateView.message(message: '这位歌手暂无专辑。')];
    }

    return [
      SliverPadding(
        padding: AppPageLayout.sectionPadding(
          context,
          bottom: _contentBottomInset(context, hasMiniPlayer),
        ),
        sliver: isWide
            ? SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 22,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.74,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final album = state.albums[index];
                  return MusicAlbumGridCard(
                    album: album,
                    onTap: () =>
                        context.push('/album/${album.id}', extra: album),
                  );
                }, childCount: state.albums.length),
              )
            : SliverToBoxAdapter(
                child: SizedBox(
                  height: 216,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.albums.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final album = state.albums[index];
                      return SizedBox(
                        width: 126,
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
      ),
    ];
  }
}

class _ArtistHero extends StatelessWidget {
  const _ArtistHero({
    required this.artist,
    required this.albumCount,
    required this.topTrackCount,
  });

  final MusicArtist? artist;
  final int albumCount;
  final int topTrackCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final artworkUrl = artist?.artworkUrl.trim() ?? '';
    final effectiveAlbumCount = albumCount > 0
        ? albumCount
        : (artist?.albumCount ?? 0);
    final effectiveTrackCount = topTrackCount > 0
        ? topTrackCount
        : (artist?.trackCount ?? 0);
    final displayName = MediaDisplayText.artistName(artist?.name);

    return AppDetailHeroFrame(
      padding: EdgeInsets.zero,
      spacing: 28,
      compactGap: 12,
      compactHorizontal: true,
      coverBuilder: (context, isWide) {
        return ClipOval(
          child: SizedBox(
            width: isWide ? 160 : 104,
            height: isWide ? 160 : 104,
            child: artworkUrl.isNotEmpty
                ? CachedArtwork(
                    imageUrl: artworkUrl,
                    size: isWide ? 160 : 104,
                    borderRadius: 999,
                    semanticLabel: '$displayName头像',
                  )
                : _ArtistAvatarPlaceholder(name: displayName),
          ),
        );
      },
      contentBuilder: (context, isWide) {
        final alignment = CrossAxisAlignment.start;
        return Column(
          crossAxisAlignment: alignment,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '$effectiveAlbumCount 张专辑 · $effectiveTrackCount 首歌曲',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ArtistAvatarPlaceholder extends StatelessWidget {
  const _ArtistAvatarPlaceholder({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: '${MediaDisplayText.artistName(name)}头像不可用',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

double _contentBottomInset(BuildContext context, bool hasMiniPlayer) {
  if (AppBreakpoints.usesWideContent(context)) {
    return AppPageLayout.contentBottomInset;
  }
  return hasMiniPlayer ? 168 : 96;
}

String _artistTrackSubtitle(MusicTrack track) {
  final album = MediaDisplayText.albumTitle(track.albumTitle);
  if (album != '未知专辑') return album;
  if (track.duration <= Duration.zero) return '暂无专辑信息';
  final minutes = track.duration.inMinutes;
  final seconds = track.duration.inSeconds
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds';
}

Future<void> _playArtistTopTracks(
  BuildContext context,
  ArtistState state,
) async {
  await PlayerNavigation.playAllAndOpenPlayer(
    context,
    loadedTracks: state.topTracks,
    allLoaded: true,
    fetchAll: () async => state.topTracks,
  );
}

void _goBackToLibrary(BuildContext context) {
  popDetailRouteOrGo(context, '/library?tab=artists');
}

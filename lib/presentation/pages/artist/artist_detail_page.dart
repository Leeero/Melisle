import 'package:cross_platform_music_player/application/usecases/fetch_artist_albums.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_artist_top_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/artist/artist_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
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
                if (!isWide)
                  SliverPadding(
                    padding: AppPageLayout.sectionPadding(
                      context,
                      top: 2,
                      bottom: 0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: AppDetailBackNav(
                        onPressed: () => _goBackToLibrary(context),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: AppPageLayout.sectionPadding(
                    context,
                    top: isWide ? 24 : 8,
                    bottom: 24,
                  ),
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
                              items: const [
                                AppTextTabItem<_ArtistDetailTab>(
                                  value: _ArtistDetailTab.tracks,
                                  label: '歌曲',
                                ),
                                AppTextTabItem<_ArtistDetailTab>(
                                  value: _ArtistDetailTab.albums,
                                  label: '专辑',
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
                                  PlayerNavigation.playAllAndOpenPlayer(
                                    context,
                                    loadedTracks: state.topTracks,
                                    allLoaded: true,
                                    fetchAll: () async => state.topTracks,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_selectedTab == _ArtistDetailTab.tracks)
                    ..._trackSlivers(state, currentTrackId, isWide)
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
  ) {
    if (state.topTracks.isEmpty) {
      return const [AppSliverStateView.message(message: '这位歌手暂无歌曲。')];
    }

    return [
      SliverPadding(
        padding: AppPageLayout.sectionPadding(context, bottom: 16),
        sliver: isWide
            ? SliverToBoxAdapter(
                child: MusicTrackTable(
                  tracks: state.topTracks,
                  currentTrackId: currentTrackId,
                  showActionBar: false,
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
                    title: track.title,
                    subtitle: track.albumTitle,
                    onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
                      context,
                      tracks: state.topTracks,
                      startIndex: index,
                    ),
                    onLongPress: () => showTrackActionsSheet(context, track),
                    onMore: () => showTrackActionsSheet(context, track),
                  );
                }, childCount: state.topTracks.length),
              ),
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
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 22,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.74,
                    ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final album = state.albums[index];
                  return MusicAlbumGridCard(
                    album: album,
                    onTap: () => context.push(
                      '/album/${album.id}',
                      extra: album,
                    ),
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
                          onTap: () => context.push(
                            '/album/${album.id}',
                            extra: album,
                          ),
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

    return AppDetailHeroFrame(
      padding: EdgeInsets.zero,
      spacing: 28,
      compactGap: 12,
      coverBuilder: (context, isWide) {
        return ClipOval(
          child: SizedBox(
            width: isWide ? 160 : 112,
            height: isWide ? 160 : 112,
            child: artworkUrl.isNotEmpty
                ? CachedArtwork(
                    imageUrl: artworkUrl,
                    size: isWide ? 160 : 112,
                    borderRadius: 999,
                    semanticLabel: '${artist?.name ?? '未知歌手'}头像',
                  )
                : _ArtistAvatarPlaceholder(name: artist?.name),
          ),
        );
      },
      contentBuilder: (context, isWide) {
        final alignment = isWide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center;
        return Column(
          crossAxisAlignment: alignment,
          children: [
            Text(
              '$effectiveAlbumCount 张专辑 · $effectiveTrackCount 首歌曲',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist?.name.trim().isNotEmpty ?? false ? artist!.name : '未知歌手',
              maxLines: isWide ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              textAlign: isWide ? TextAlign.start : TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
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
      label: '${name?.trim().isNotEmpty ?? false ? name : '未知歌手'}头像不可用',
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
  if (AppBreakpoints.usesWideContent(context)) return 28;
  return hasMiniPlayer ? 168 : 96;
}

void _goBackToLibrary(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).maybePop();
    return;
  }
  context.go('/library');
}

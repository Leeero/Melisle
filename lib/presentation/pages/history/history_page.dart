import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/tracks/app_track_collection_view.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryCubit(context.read<AppDatabase>())..load(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        return AppContentPage(
          header: _HistoryHeader(
            count: state.tracks.length,
            tracks: state.tracks,
          ),
          body: _buildBody(context, state, horizontalPadding, currentTrackId),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    HistoryState state,
    double horizontalPadding,
    String? currentTrackId,
  ) {
    if (state.status == HistoryStatus.loading && state.tracks.isEmpty) {
      return const AppBodyStateView.loading();
    }

    if (state.status == HistoryStatus.failure && state.tracks.isEmpty) {
      return AppBodyStateView.message(
        message: '播放历史加载失败',
        description: state.errorMessage,
        icon: Icons.error_outline_rounded,
      );
    }

    if (state.tracks.isEmpty) {
      return const AppBodyStateView.message(
        message: '还没有播放历史',
        description: '开始播放后，最近听过的歌曲会自动记录在这里。',
        icon: Icons.history_rounded,
      );
    }

    return AppTrackCollectionView(
      tracks: state.tracks,
      currentTrackId: currentTrackId,
      horizontalPadding: horizontalPadding,
      mobileHeader: AppSectionTitleRow(
        title: '最近播放',
        badge: MetaPill(
          label: '${state.tracks.length} 条',
          size: MetaPillSize.compact,
        ),
      ),
      desktopTrailingBuilder: (context, track, _) =>
          _HistoryPlayedAtButton(label: _formatLastPlayed(track.lastPlayedAt)),
      mobileItemBuilder: (context, track, trackIndex, currentTrackId) {
        return _HistoryTrackRow(
          track: track,
          currentTrackId: currentTrackId,
          onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
            context,
            tracks: state.tracks,
            startIndex: trackIndex,
          ),
        );
      },
      onTrackTap: (index) => PlayerNavigation.playTracksAndOpenPlayer(
        context,
        tracks: state.tracks,
        startIndex: index,
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.count, required this.tracks});

  final int count;
  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final canPop = Navigator.of(context).canPop();
    final playAllButton = count == 0
        ? null
        : PlayAllButton(
            variant: PlayAllButtonVariant.compact,
            onPressed: () => PlayerNavigation.playAllAndOpenPlayer(
              context,
              loadedTracks: tracks,
              allLoaded: true,
              fetchAll: () async => tracks,
            ),
            onShufflePressed: () => PlayerNavigation.shuffleAllAndOpenPlayer(
              context,
              loadedTracks: tracks,
              allLoaded: true,
              fetchAll: () async => tracks,
            ),
          );

    if (compact) {
      return _MobileHistoryHeader(canPop: canPop, playAllButton: playAllButton);
    }

    return AppPageHeader(
      title: '播放历史',
      description: '过去 7 天的播放记录',
      trailing: playAllButton,
    );
  }
}

class _MobileHistoryHeader extends StatelessWidget {
  const _MobileHistoryHeader({required this.canPop, this.playAllButton});

  final bool canPop;
  final Widget? playAllButton;

  @override
  Widget build(BuildContext context) {
    final showActionRow = canPop || playAllButton != null;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showActionRow) ...[
          Row(
            children: [
              if (canPop)
                AppBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              const Spacer(),
              ?playAllButton,
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text(
          '播放历史',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 31,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _HistoryTrackRow extends StatelessWidget {
  const _HistoryTrackRow({
    required this.track,
    required this.currentTrackId,
    required this.onTap,
  });

  final MusicTrack track;
  final String? currentTrackId;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return MusicTrackTile.row(
      isCurrent: track.id == currentTrackId,
      artworkUrl: track.artworkUrl,
      title: track.title,
      subtitle: [
        track.artistName,
        track.albumTitle,
      ].where((item) => item.isNotEmpty).join(' · '),
      statusLabel: _formatLastPlayed(track.lastPlayedAt),
      idleIcon: Icons.history_rounded,
      extraTrailing: _HistoryPlayedAtButton(
        label: _formatLastPlayed(track.lastPlayedAt),
      ),
      onTap: onTap,
    );
  }
}

class _HistoryPlayedAtButton extends StatelessWidget {
  const _HistoryPlayedAtButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: SizedBox.square(
        dimension: 36,
        child: Icon(
          Icons.history_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

String _formatLastPlayed(DateTime? value) {
  if (value == null) return '播放时间未知';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

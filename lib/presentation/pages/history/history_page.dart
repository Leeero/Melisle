import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/play_all_button.dart';
import 'package:cross_platform_music_player/shared/theme/app_tokens.dart';
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
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        return AppContentPage(
          header: _HistoryHeader(state: state),
          body: _buildBody(context, state, currentTrackId),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    HistoryState state,
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
        action: FilledButton.icon(
          onPressed: () => context.read<HistoryCubit>().load(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重试'),
        ),
      );
    }

    if (state.tracks.isEmpty) {
      return const AppBodyStateView.message(
        message: '还没有播放历史',
        description: '开始播放后，最近听过的歌曲会自动记录在这里。',
        icon: Icons.history_rounded,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 240) {
          context.read<HistoryCubit>().loadMore();
        }
        return false;
      },
      child: _HistoryTrackList(
        state: state,
        currentTrackId: currentTrackId,
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: PlayAllButton(
        onPressed: state.tracks.isEmpty
            ? null
            : () => _playAllHistory(context, state),
        onShufflePressed: state.tracks.isEmpty
            ? null
            : () => _playAllHistory(context, state, shuffled: true),
      ),
    );
  }
}

class _HistoryTrackList extends StatelessWidget {
  const _HistoryTrackList({required this.state, required this.currentTrackId});

  final HistoryState state;
  final String? currentTrackId;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppPageLayout.contentBottomInset,
      ),
      children: [
        MusicTrackTable(
          tracks: state.tracks,
          currentTrackId: currentTrackId,
          showActionBar: false,
          libraryStyle: true,
          onTrackTap: (index, _) => PlayerNavigation.playTracksAndOpenPlayer(
            context,
            tracks: state.tracks,
            startIndex: index,
          ),
        ),
        _HistoryLoadFooter(state: state),
      ],
    );
  }
}

class _HistoryLoadFooter extends StatelessWidget {
  const _HistoryLoadFooter({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.all(AppSpacingTokens.sectionPadding),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.status == HistoryStatus.failure) {
      return Center(
        child: TextButton.icon(
          onPressed: () => context.read<HistoryCubit>().loadMore(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('加载失败，重试'),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '已经到底了，多听听音乐吧',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 48);
  }
}

Future<void> _playAllHistory(
  BuildContext context,
  HistoryState state, {
  bool shuffled = false,
}) {
  if (shuffled) {
    return PlayerNavigation.shuffleAllAndOpenPlayer(
      context,
      loadedTracks: state.tracks,
      allLoaded: !state.hasMore,
      fetchAll: () => context.read<HistoryCubit>().fetchAllTracks(),
    );
  }

  return PlayerNavigation.playAllAndOpenPlayer(
    context,
    loadedTracks: state.tracks,
    allLoaded: !state.hasMore,
    fetchAll: () => context.read<HistoryCubit>().fetchAllTracks(),
  );
}

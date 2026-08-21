import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/player_navigation.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
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
    final currentTrackId = context.select<PlayerCubit, String?>(
      (cubit) => cubit.state.currentTrack?.id,
    );

    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        return AppContentPage(
          header: const _HistoryHeader(),
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
      child: _HistoryGroups(
        state: state,
        currentTrackId: currentTrackId,
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final canPop = Navigator.of(context).canPop();
    if (compact) {
      return _MobileHistoryHeader(canPop: canPop);
    }

    return const AppPageHeader(title: '历史');
  }
}

class _MobileHistoryHeader extends StatelessWidget {
  const _MobileHistoryHeader({required this.canPop});

  final bool canPop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canPop) ...[
          Row(
            children: [
              AppBackButton(onPressed: () => Navigator.of(context).maybePop()),
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

class _HistoryGroups extends StatelessWidget {
  const _HistoryGroups({required this.state, required this.currentTrackId});

  final HistoryState state;
  final String? currentTrackId;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    final groups = _groupHistory(state.tracks);
    final children = <Widget>[
      if (compact)
        Padding(
          padding: EdgeInsets.only(bottom: AppPageLayout.sectionTitleBottomGap),
          child: AppSectionTitleRow(
            title: '最近播放',
            badge: MetaPill(
              label: '${state.tracks.length} 条',
              size: MetaPillSize.compact,
            ),
          ),
        ),
      for (final group in groups) ...[
        _HistoryGroupHeader(label: group.label),
        const SizedBox(height: 8),
        for (final item in group.items)
          _HistoryTrackRow(
            track: item.track,
            currentTrackId: currentTrackId,
            compact: compact,
            onTap: () => PlayerNavigation.playTracksAndOpenPlayer(
              context,
              tracks: state.tracks,
              startIndex: item.index,
            ),
          ),
        const SizedBox(height: AppPageLayout.sectionGap),
      ],
      _HistoryLoadFooter(state: state),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
      children: children,
    );
  }
}

class _HistoryGroupHeader extends StatelessWidget {
  const _HistoryGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Text(label, style: theme.textTheme.titleMedium),
    );
  }
}

class _HistoryTrackRow extends StatelessWidget {
  const _HistoryTrackRow({
    required this.track,
    required this.currentTrackId,
    required this.onTap,
    required this.compact,
  });

  final MusicTrack track;
  final String? currentTrackId;
  final Future<void> Function() onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = track.id == currentTrackId;
    final subtitle = [track.artistName, track.albumTitle]
        .where((item) => item.isNotEmpty)
        .join(' · ');
    return Semantics(
      label: '播放《${track.title}》',
      selected: isCurrent,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: isCurrent ? theme.selectedWash : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
          child: InkWell(
            onTap: onTap,
            onLongPress: () => showTrackActionsSheet(context, track),
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
            child: SizedBox(
              height: compact ? 60 : 56,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
                child: Row(
                  children: [
                    _HistoryArtwork(track: track),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title.isEmpty ? '未知曲目' : track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle.isEmpty ? '未知歌手' : subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      compact
                          ? _formatLastPlayed(track.lastPlayedAt)
                          : _formatDuration(track.duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Tooltip(
                      message: '更多操作',
                      child: IconButton(
                        onPressed: () => showTrackActionsSheet(context, track),
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
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

class _HistoryArtwork extends StatelessWidget {
  const _HistoryArtwork({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return CachedArtwork(
      imageUrl: track.artworkUrl,
      size: 40,
      borderRadius: AppRadiusTokens.desktopSm,
      semanticLabel: track.artworkUrl.isEmpty ? '无封面' : '《${track.title}》封面',
    );
  }
}

class _HistoryLoadFooter extends StatelessWidget {
  const _HistoryLoadFooter({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacingTokens.sectionPadding),
        child: Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
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

class _HistoryGroup {
  const _HistoryGroup(this.label, this.items);

  final String label;
  final List<_HistoryItem> items;
}

class _HistoryItem {
  const _HistoryItem(this.track, this.index);

  final MusicTrack track;
  final int index;
}

List<_HistoryGroup> _groupHistory(List<MusicTrack> tracks, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final groups = <String, List<_HistoryItem>>{};
  for (var index = 0; index < tracks.length; index++) {
    final playedAt = tracks[index].lastPlayedAt;
    final day = playedAt == null
        ? null
        : DateTime(playedAt.year, playedAt.month, playedAt.day);
    final label = day == today
        ? '今天'
        : day == yesterday
        ? '昨天'
        : '更早';
    groups.putIfAbsent(label, () => []).add(_HistoryItem(tracks[index], index));
  }
  return [
    for (final label in const ['今天', '昨天', '更早'])
      if (groups[label] case final items?) _HistoryGroup(label, items),
  ];
}

String _formatLastPlayed(DateTime? value) {
  if (value == null) return '播放时间未知';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

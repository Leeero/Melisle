import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 播放队列底部表。支持左滑删除、长按拖拽排序。
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PlayerCubit>(),
        child: const QueueSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return BlocBuilder<PlayerCubit, PlayerViewState>(
          buildWhen: (prev, next) => prev.queue.length != next.queue.length,
          builder: (context, headerState) {
            return AppSheetScaffold(
              title: '播放队列',
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              trailing: _QueueCountLabel(count: headerState.queue.length),
              child: Expanded(
                child: BlocBuilder<PlayerCubit, PlayerViewState>(
                  buildWhen: (prev, next) =>
                      prev.queue != next.queue ||
                      prev.currentIndex != next.currentIndex ||
                      prev.isPlaying != next.isPlaying,
                  builder: (context, state) {
                    if (state.queue.isEmpty) {
                      return const _EmptyQueueView();
                    }

                    return ReorderableListView.builder(
                      scrollController: scrollController,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                      buildDefaultDragHandles: false,
                      proxyDecorator: _proxyDecorator,
                      itemCount: state.queue.length,
                      onReorder: context.read<PlayerCubit>().moveQueueItem,
                      itemBuilder: (context, index) {
                        final track = state.queue[index];
                        final isCurrent = index == state.currentIndex;

                        return _QueueItem(
                          key: ValueKey('queue-${track.id}-$index'),
                          index: index,
                          track: track,
                          isCurrent: isCurrent,
                          isPlaying: state.isPlaying,
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Proxy decorator for the dragged item — adds elevation and scale.
  static Widget _proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final t = AppMotion.enter.transform(animation.value);
        return Material(
          color: colorScheme.surface,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.10 * t),
                  blurRadius: 22 * t,
                  offset: Offset(0, 8 * t),
                ),
              ],
            ),
            child: Transform.scale(scale: 1.0 + 0.012 * t, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({
    super.key,
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
  });

  final int index;
  final MusicTrack track;
  final bool isCurrent;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.zero,
      child: Dismissible(
        key: ValueKey('dismiss-${track.id}-$index'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<PlayerCubit>().removeQueueItem(index),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.errorContainer.withValues(alpha: 0.72),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: colorScheme.onErrorContainer,
          ),
        ),
        child: MusicTrackTile.row(
          title: track.title,
          subtitle: [
            track.artistName,
            track.albumTitle,
          ].where((s) => s.isNotEmpty).join(' · '),
          artworkUrl: track.artworkUrl,
          isCurrent: isCurrent,
          onTap: () async {
            await context.read<PlayerCubit>().playIndex(index);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          extraTrailing: _QueueItemActions(
            index: index,
            onRemove: () => context.read<PlayerCubit>().removeQueueItem(index),
          ),
        ),
      ),
    );
  }
}

class _QueueCountLabel extends StatelessWidget {
  const _QueueCountLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Text(
        '$count 首歌曲',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _QueueItemActions extends StatelessWidget {
  const _QueueItemActions({required this.index, required this.onRemove});

  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QueueActionButton(
          icon: Icons.close_rounded,
          tooltip: '移出队列',
          tone: _QueueActionTone.danger,
          onPressed: onRemove,
        ),
        const SizedBox(width: 2),
        _QueueDragHandle(index: index),
      ],
    );
  }
}

class _QueueDragHandle extends StatelessWidget {
  const _QueueDragHandle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '拖拽排序',
      button: true,
      child: Tooltip(
        message: '拖拽排序',
        child: ReorderableDragStartListener(
          index: index,
          child: const _QueueActionChrome(
            icon: Icons.drag_indicator_rounded,
            tone: _QueueActionTone.neutral,
          ),
        ),
      ),
    );
  }
}

enum _QueueActionTone { neutral, danger }

class _QueueActionButton extends StatelessWidget {
  const _QueueActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = _QueueActionTone.neutral,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final _QueueActionTone tone;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: _QueueActionChrome(icon: icon, tone: tone),
        ),
      ),
    );
  }
}

class _QueueActionChrome extends StatelessWidget {
  const _QueueActionChrome({required this.icon, required this.tone});

  final IconData icon;
  final _QueueActionTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final danger = tone == _QueueActionTone.danger;
    final foreground = danger ? colorScheme.error : theme.muted;
    final background = danger
        ? colorScheme.errorContainer.withValues(alpha: 0.18)
        : theme.hoverWash.withValues(alpha: 0.58);
    final border = danger
        ? colorScheme.error.withValues(alpha: 0.18)
        : colorScheme.outlineVariant.withValues(alpha: 0.54);

    return SizedBox.square(
      dimension: 44,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: SizedBox.square(
            dimension: 36,
            child: Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _EmptyQueueView extends StatelessWidget {
  const _EmptyQueueView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 56,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '当前播放队列为空',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '从音乐库中选择歌曲开始播放',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

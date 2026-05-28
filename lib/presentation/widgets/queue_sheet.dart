import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_tile.dart';
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
              description: '${headerState.queue.length} 首歌曲',
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              trailing: headerState.queue.isEmpty
                  ? null
                  : AppActionButton(
                      icon: Icons.delete_sweep_rounded,
                      label: '清空',
                      tone: AppActionButtonTone.danger,
                      onPressed: () => _confirmClearQueue(context),
                    ),
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

  Future<void> _confirmClearQueue(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: '清空播放队列',
      message: '将移除当前队列中的所有歌曲，正在播放的内容也会停止。',
      confirmLabel: '清空',
      icon: Icons.delete_sweep_rounded,
      tone: AppModalTone.danger,
    );
    if (!confirmed || !context.mounted) return;
    context.read<PlayerCubit>().clearQueue();
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
        final t = Curves.easeInOut.transform(animation.value);
        final elevation = 4.0 * t;
        return Material(
          color: Colors.transparent,
          elevation: elevation,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(20),
          child: Transform.scale(scale: 1.0 + 0.02 * t, child: child),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('dismiss-${track.id}-$index'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<PlayerCubit>().removeQueueItem(index),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.errorContainer.withValues(alpha: 0.72),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: colorScheme.onErrorContainer,
          ),
        ),
        child: MusicTrackTile.card(
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
          extraTrailing: _QueueDragHandle(
            index: index,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

class _QueueDragHandle extends StatelessWidget {
  const _QueueDragHandle({required this.index, required this.colorScheme});

  final int index;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '拖拽排序',
      button: true,
      child: Tooltip(
        message: '拖拽排序',
        child: ReorderableDragStartListener(
          index: index,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: Icon(
                Icons.drag_handle_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
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

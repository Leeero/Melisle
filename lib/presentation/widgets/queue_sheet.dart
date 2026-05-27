import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: BlocBuilder<PlayerCubit, PlayerViewState>(
                  buildWhen: (prev, next) =>
                      prev.queue.length != next.queue.length,
                  builder: (context, state) {
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '播放队列',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${state.queue.length} 首歌曲',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (state.queue.isNotEmpty)
                          TextButton.icon(
                            onPressed: () =>
                                context.read<PlayerCubit>().clearQueue(),
                            icon: const Icon(Icons.delete_sweep_rounded),
                            label: const Text('清空'),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Queue list
              Expanded(
                child: BlocBuilder<PlayerCubit, PlayerViewState>(
                  buildWhen: (prev, next) =>
                      prev.queue != next.queue ||
                      prev.currentIndex != next.currentIndex ||
                      prev.isPlaying != next.isPlaying,
                  builder: (context, state) {
                    if (state.queue.isEmpty) {
                      return _EmptyQueueView(colorScheme: colorScheme);
                    }

                    return ReorderableListView.builder(
                      scrollController: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
            ],
          ),
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
            gradient: LinearGradient(
              colors: [
                colorScheme.error.withValues(alpha: 0.08),
                colorScheme.error.withValues(alpha: 0.24),
              ],
            ),
          ),
          child: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
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
          extraTrailing: Tooltip(
            message: '拖拽排序',
            child: ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyQueueView extends StatelessWidget {
  const _EmptyQueueView({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
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

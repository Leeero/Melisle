import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 52,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BlocBuilder<PlayerCubit, PlayerViewState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '播放队列',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.queue.length} 首歌曲',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (state.queue.isNotEmpty)
                          Tooltip(
                            message: '清空队列',
                            child: TextButton.icon(
                              onPressed: () async {
                                await context.read<PlayerCubit>().clearQueue();
                                // 清空后关闭队列面板
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(Icons.delete_sweep_rounded),
                              label: const Text('清空'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<PlayerCubit, PlayerViewState>(
                  builder: (context, state) {
                    if (state.queue.isEmpty) {
                      return const Center(child: Text('当前播放队列为空。'));
                    }

                    return ReorderableListView.builder(
                      scrollController: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      buildDefaultDragHandles: false,
                      itemCount: state.queue.length,
                      onReorder: context.read<PlayerCubit>().moveQueueItem,
                      itemBuilder: (context, index) {
                        final track = state.queue[index];
                        final isCurrent = index == state.currentIndex;
                        final colorScheme = Theme.of(context).colorScheme;

                        return Padding(
                          key: ValueKey('queue-${track.id}-$index'),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            color: isCurrent
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.8,
                                  )
                                : colorScheme.surfaceContainerHigh.withValues(
                                    alpha: 0.74,
                                  ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isCurrent
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.28,
                                      )
                                    : colorScheme.outlineVariant.withValues(
                                        alpha: 0.45,
                                      ),
                              ),
                            ),
                            child: ListTile(
                              onTap: () async {
                                await context.read<PlayerCubit>().playIndex(
                                  index,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              leading: CachedArtwork(
                                imageUrl: track.artworkUrl,
                                size: 52,
                                borderRadius: 18,
                                sourceContext: ArtworkSourceContext.track(
                                  track,
                                ),
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${track.artistName} · ${track.albumTitle}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: SizedBox(
                                width: 112,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isCurrent)
                                      Icon(
                                        state.isPlaying
                                            ? Icons.graphic_eq_rounded
                                            : Icons
                                                  .pause_circle_outline_rounded,
                                        color: colorScheme.onPrimaryContainer,
                                      )
                                    else
                                      const SizedBox(width: 24),
                                    IconButton(
                                      onPressed: () => context
                                          .read<PlayerCubit>()
                                          .removeQueueItem(index),
                                      tooltip: '移出队列',
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                    Tooltip(
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
                                  ],
                                ),
                              ),
                            ),
                          ),
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
}

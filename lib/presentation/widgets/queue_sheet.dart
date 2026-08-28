import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 播放队列入口。桌面使用右侧浮层，移动端使用可拖拽底部抽屉。
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    final playerCubit = context.read<PlayerCubit>();
    if (AppBreakpoints.usesDesktopShell(context)) {
      return showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '关闭播放队列',
        barrierColor: Colors.black.withValues(alpha: 0.16),
        transitionDuration: AppMotion.normal,
        pageBuilder: (_, _, _) => BlocProvider.value(
          value: playerCubit,
          child: const _DesktopQueueOverlay(),
        ),
        transitionBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppMotion.enter)),
          child: child,
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: playerCubit, child: const QueueSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.46,
      maxChildSize: 0.94,
      builder: (context, scrollController) => Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadiusTokens.mobileXl),
        ),
        child: QueuePanel(
          scrollController: scrollController,
          showDragHandle: true,
          closeOnPlay: true,
        ),
      ),
    );
  }
}

/// mini 播放器与播放页共用的播放队列内容组件。
class QueuePanel extends StatefulWidget {
  const QueuePanel({
    super.key,
    this.scrollController,
    this.showDragHandle = false,
    this.closeOnPlay = false,
  });

  final ScrollController? scrollController;
  final bool showDragHandle;
  final bool closeOnPlay;

  @override
  State<QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends State<QueuePanel> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (previous, current) =>
          previous.queue != current.queue ||
          previous.currentIndex != current.currentIndex ||
          previous.isPlaying != current.isPlaying,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showDragHandle) const _SheetDragHandle(),
          _QueueHeader(
            count: state.queue.length,
            onClear: state.queue.isEmpty ? null : _confirmClear,
            onLocateCurrent: state.currentIndex < 0
                ? null
                : () => _locateCurrent(state.currentIndex),
          ),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          const _QueueSectionLabel(),
          Expanded(
            child: state.queue.isEmpty
                ? const _EmptyQueueView()
                : ReorderableListView.builder(
                    scrollController: _scrollController,
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 20),
                    itemExtent: 64,
                    buildDefaultDragHandles: false,
                    proxyDecorator: _proxyDecorator,
                    itemCount: state.queue.length,
                    onReorder: context.read<PlayerCubit>().moveQueueItem,
                    itemBuilder: (context, index) {
                      final track = state.queue[index];
                      return _QueueItem(
                        key: ValueKey('queue-${track.id}-$index'),
                        index: index,
                        track: track,
                        isCurrent: index == state.currentIndex,
                        isPlaying: state.isPlaying,
                        closeOnPlay: widget.closeOnPlay,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确定清空播放队列？'),
        content: const Text('清空后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<PlayerCubit>().clearQueue();
    }
  }

  void _locateCurrent(int currentIndex) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (currentIndex * 64.0 - position.viewportDimension / 2 + 32)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: AppMotion.normal,
      curve: AppMotion.enter,
    );
  }

  static Widget _proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = AppMotion.enter.transform(animation.value);
        return Transform.scale(
          scale: 1 + value * 0.012,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
            elevation: value * 8,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _DesktopQueueOverlay extends StatelessWidget {
  const _DesktopQueueOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: theme.colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
            elevation: 18,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.28),
            child: SizedBox(
              width: 390,
              height: double.infinity,
              child: const QueuePanel(closeOnPlay: true),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.count,
    required this.onClear,
    required this.onLocateCurrent,
  });

  final int count;
  final VoidCallback? onClear;
  final VoidCallback? onLocateCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
      child: Row(
        children: [
          Text(
            '播放队列',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$count 首歌曲',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.muted),
          ),
          const Spacer(),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: '清空队列',
                  child: TextButton(
                    onPressed: onClear,
                    style: TextButton.styleFrom(
                      fixedSize: const Size(72, 44),
                      minimumSize: const Size(72, 44),
                      maximumSize: const Size(72, 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox.square(
                          dimension: 18,
                          child: Center(
                            child: Icon(Icons.delete_outline_rounded, size: 18),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '清空',
                          style: theme.textTheme.labelLarge?.copyWith(
                            height: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onLocateCurrent,
                  tooltip: '定位到当前播放',
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(44),
                    minimumSize: const Size.square(44),
                    maximumSize: const Size.square(44),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueSectionLabel extends StatelessWidget {
  const _QueueSectionLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        '接下来播放',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QueueItem extends StatefulWidget {
  const _QueueItem({
    super.key,
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.closeOnPlay,
  });

  final int index;
  final MusicTrack track;
  final bool isCurrent;
  final bool isPlaying;
  final bool closeOnPlay;

  @override
  State<_QueueItem> createState() => _QueueItemState();
}

class _QueueItemState extends State<_QueueItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = [
      widget.track.artistName,
      widget.track.albumTitle,
    ].where((value) => value.trim().isNotEmpty).join(' · ');

    return Dismissible(
      key: ValueKey('dismiss-${widget.track.id}-${widget.index}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) =>
          context.read<PlayerCubit>().removeQueueItem(widget.index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        color: colorScheme.errorContainer,
        child: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
      ),
      child: Semantics(
        button: true,
        selected: widget.isCurrent,
        label: widget.isCurrent
            ? '当前播放：${widget.track.title}'
            : '播放：${widget.track.title}',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _play,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: AnimatedContainer(
                duration: AppMotion.micro,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: widget.isCurrent
                      ? colorScheme.primaryContainer.withValues(alpha: 0.42)
                      : _hovered
                      ? theme.hoverWash
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppRadiusTokens.desktopSm,
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CachedArtwork(
                          imageUrl: widget.track.artworkUrl,
                          size: 44,
                          borderRadius: 7,
                          sourceContext: ArtworkSourceContext.track(
                            widget.track,
                          ),
                          semanticLabel: '《${widget.track.title}》封面',
                        ),
                        if (widget.isCurrent)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              widget.isPlaying
                                  ? Icons.graphic_eq_rounded
                                  : Icons.pause_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: widget.isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontWeight: widget.isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedOpacity(
                            duration: AppMotion.micro,
                            opacity: _hovered ? 0 : 1,
                            child: Text(
                              _formatDuration(widget.track.duration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.muted,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          IgnorePointer(
                            ignoring: !_hovered,
                            child: AnimatedOpacity(
                              duration: AppMotion.micro,
                              opacity: _hovered ? 1 : 0,
                              child: IconButton(
                                onPressed: () => context
                                    .read<PlayerCubit>()
                                    .removeQueueItem(widget.index),
                                tooltip: '移出队列',
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: '拖拽排序',
                      child: ReorderableDragStartListener(
                        index: widget.index,
                        child: Semantics(
                          button: true,
                          label: '拖拽调整《${widget.track.title}》的顺序',
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
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
        ),
      ),
    );
  }

  Future<void> _play() async {
    await context.read<PlayerCubit>().playIndex(widget.index);
    if (widget.closeOnPlay && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _EmptyQueueView extends StatelessWidget {
  const _EmptyQueueView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: 52,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.42),
            ),
            const SizedBox(height: 14),
            Text(
              '当前播放队列为空',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '从音乐库选择歌曲后，会显示在这里',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

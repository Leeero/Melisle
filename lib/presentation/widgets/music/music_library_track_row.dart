import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class MusicLibraryTrackRow extends StatefulWidget {
  const MusicLibraryTrackRow({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onMore,
    this.onLongPress,
  });

  final MusicTrack track;
  final int index;
  final bool isCurrent;
  final Future<void> Function() onTap;
  final VoidCallback onMore;
  final VoidCallback? onLongPress;

  @override
  State<MusicLibraryTrackRow> createState() => _MusicLibraryTrackRowState();
}

class _MusicLibraryTrackRowState extends State<MusicLibraryTrackRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = widget.isCurrent;
    final subtitle = [
      widget.track.artistName,
      widget.track.albumTitle,
    ].where((item) => item.isNotEmpty).join(' · ');

    return Semantics(
      label: '播放《${widget.track.title}》',
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 70),
          color: selected
              ? theme.selectedWash
              : _pressed
              ? theme.hoverWash
              : Colors.transparent,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: colors.primary.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: selected
                          ? Icon(
                              Icons.graphic_eq_rounded,
                              size: 18,
                              color: colors.primary,
                            )
                          : Text(
                              '${widget.index + 1}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.78,
                                ),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: selected
                                  ? colors.primary
                                  : colors.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(widget.track.duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        onPressed: widget.onMore,
                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                        tooltip: '更多操作',
                        padding: EdgeInsets.zero,
                        style: AppActionButtonStyle.icon(context),
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

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

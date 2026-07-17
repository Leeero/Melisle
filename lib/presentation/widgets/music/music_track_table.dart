import 'package:flutter/material.dart';

import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';

typedef MusicTrackTableTap = void Function(int index, MusicTrack track);
typedef MusicTrackTableAction = void Function(MusicTrack track);
typedef MusicTrackTableTrailingBuilder =
    Widget? Function(BuildContext context, MusicTrack track, bool hovered);

class MusicTrackTable extends StatelessWidget {
  const MusicTrackTable({
    super.key,
    required this.tracks,
    required this.onTrackTap,
    this.currentTrackId,
    this.trackCountLabel,
    this.onPlayAll,
    this.onShuffleAll,
    this.onAddAllToQueue,
    this.onAddTrackToQueue,
    this.trailingBuilder,
    this.showActionBar = true,
  });

  final List<MusicTrack> tracks;
  final MusicTrackTableTap onTrackTap;
  final String? currentTrackId;
  final String? trackCountLabel;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffleAll;
  final VoidCallback? onAddAllToQueue;
  final MusicTrackTableAction? onAddTrackToQueue;
  final MusicTrackTableTrailingBuilder? trailingBuilder;
  final bool showActionBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showActionBar) ...[
          _MusicTrackTableActionBar(
            countLabel: trackCountLabel ?? '${tracks.length} 首',
            onPlayAll: onPlayAll,
            onShuffleAll: onShuffleAll,
            onAddAllToQueue: onAddAllToQueue,
          ),
          const SizedBox(height: 12),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.76),
              ),
            ),
          ),
          child: Column(
            children: [
              const _MusicTrackTableHeader(),
              for (var index = 0; index < tracks.length; index++)
                _MusicTrackTableRow(
                  index: index,
                  track: tracks[index],
                  isCurrent: tracks[index].id == currentTrackId,
                  onTap: () => onTrackTap(index, tracks[index]),
                  onAddToQueue: onAddTrackToQueue == null
                      ? null
                      : () => onAddTrackToQueue!(tracks[index]),
                  trailingBuilder: trailingBuilder,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MusicTrackTableActionBar extends StatelessWidget {
  const _MusicTrackTableActionBar({
    required this.countLabel,
    this.onPlayAll,
    this.onShuffleAll,
    this.onAddAllToQueue,
  });

  final String countLabel;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffleAll;
  final VoidCallback? onAddAllToQueue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MetaPill(label: countLabel, size: MetaPillSize.compact),
        const Spacer(),
        AppActionButton(
          icon: Icons.play_arrow_rounded,
          label: '播放全部',
          tone: AppActionButtonTone.primary,
          onPressed: onPlayAll,
        ),
        if (onShuffleAll != null) ...[
          const SizedBox(width: 6),
          AppActionButton(
            icon: Icons.shuffle_rounded,
            label: '随机播放',
            onPressed: onShuffleAll,
          ),
        ],
        if (onAddAllToQueue != null) ...[
          const SizedBox(width: 6),
          AppActionButton(
            icon: Icons.playlist_add_rounded,
            label: '加入队列',
            onPressed: onAddAllToQueue,
          ),
        ],
      ],
    );
  }
}

class _MusicTrackTableHeader extends StatelessWidget {
  const _MusicTrackTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.muted,
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showAlbum = constraints.maxWidth >= 620;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '#',
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: Text('歌曲 / 歌手', style: labelStyle)),
              if (showAlbum) ...[
                const SizedBox(width: 12),
                Expanded(flex: 3, child: Text('专辑', style: labelStyle)),
              ],
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '时长',
                  style: labelStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 44),
            ],
          ),
        );
      },
    );
  }
}

class _MusicTrackTableRow extends StatefulWidget {
  const _MusicTrackTableRow({
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.onTap,
    this.onAddToQueue,
    this.trailingBuilder,
  });

  final int index;
  final MusicTrack track;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onAddToQueue;
  final MusicTrackTableTrailingBuilder? trailingBuilder;

  @override
  State<_MusicTrackTableRow> createState() => _MusicTrackTableRowState();
}

class _MusicTrackTableRowState extends State<_MusicTrackTableRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlighted = _hovered || _focused;
    final track = widget.track;
    final indexLabel = (widget.index + 1).toString().padLeft(2, '0');
    final trailing = widget.trailingBuilder?.call(context, track, _hovered);

    return Semantics(
      label: '播放《${track.title}》',
      button: true,
      selected: widget.isCurrent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        opaque: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Material(
            color: widget.isCurrent
                ? theme.selectedWash
                : highlighted
                ? theme.hoverWash
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              focusColor: colorScheme.primary.withValues(alpha: 0.08),
              hoverColor: Colors.transparent,
              splashColor: colorScheme.primary.withValues(alpha: 0.06),
              highlightColor: Colors.transparent,
              onFocusChange: (value) => setState(() => _focused = value),
              onTap: widget.onTap,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showAlbum = constraints.maxWidth >= 620;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Center(
                            child: widget.isCurrent
                                ? Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 18,
                                    color: colorScheme.primary,
                                  )
                                : highlighted
                                ? Icon(
                                    Icons.play_arrow_rounded,
                                    size: 20,
                                    color: colorScheme.primary,
                                  )
                                : Text(
                                    indexLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: _MusicTrackTitleCell(
                            track: track,
                            isCurrent: widget.isCurrent,
                            showSubtitle: true,
                          ),
                        ),
                        if (showAlbum) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: _MusicTrackTableText(track.albumTitle),
                          ),
                        ],
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: Text(
                            _formatTrackDuration(track.duration),
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedOpacity(
                          duration: AppMotion.micro,
                          curve: AppMotion.enter,
                          opacity: highlighted || widget.isCurrent ? 1 : 0,
                          child: SizedBox(
                            width: 44,
                            child:
                                trailing ??
                                (widget.onAddToQueue == null
                                    ? const SizedBox.shrink()
                                    : _MusicTrackTableIconButton(
                                        icon: Icons.playlist_add_rounded,
                                        tooltip: '加入队列',
                                        onPressed: widget.onAddToQueue!,
                                      )),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicTrackTitleCell extends StatelessWidget {
  const _MusicTrackTitleCell({
    required this.track,
    required this.isCurrent,
    required this.showSubtitle,
  });

  final MusicTrack track;
  final bool isCurrent;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isCurrent
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (track.codec?.toLowerCase() == 'flac') ...[
              const SizedBox(width: 8),
              const MetaPill(label: 'FLAC', size: MetaPillSize.compact),
            ],
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 2),
          Text(
            track.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.muted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _MusicTrackTableText extends StatelessWidget {
  const _MusicTrackTableText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
    );
  }
}

class _MusicTrackTableIconButton extends StatelessWidget {
  const _MusicTrackTableIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.standard,
        style: AppActionButtonStyle.icon(
          context,
          iconSize: 18,
          radius: AppRadiusTokens.desktopSm,
        ),
      ),
    );
  }
}

String _formatTrackDuration(Duration duration) {
  if (duration <= Duration.zero) return '--:--';
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

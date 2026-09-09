import 'package:flutter/material.dart';

import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/track_actions_sheet.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';

typedef MusicTrackTableTap = void Function(int index, MusicTrack track);
typedef MusicTrackTableAction = void Function(MusicTrack track);
typedef MusicTrackTableTrailingBuilder =
    Widget? Function(BuildContext context, MusicTrack track, bool hovered);

enum MusicTrackTableDensity { compact, comfortable }

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
    this.libraryStyle = false,
    this.playlistStyle = false,
    this.hideHoverPlayControl = false,
    this.bareMoreAction = false,
    this.actionBarTrailing,
    this.density = MusicTrackTableDensity.comfortable,
    this.trackActionsContext = TrackActionsContext.generic,
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
  final bool libraryStyle;
  final bool playlistStyle;
  final bool hideHoverPlayControl;
  final bool bareMoreAction;
  final Widget? actionBarTrailing;
  final MusicTrackTableDensity density;
  final TrackActionsContext trackActionsContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showActionBar) ...[
          _MusicTrackTableActionBar(
            countLabel: trackCountLabel ?? '${tracks.length} 首',
            onPlayAll: onPlayAll,
            onShuffleAll: onShuffleAll,
            onAddAllToQueue: onAddAllToQueue,
            libraryStyle: libraryStyle,
            trailing: actionBarTrailing,
          ),
          const SizedBox(height: 12),
        ],
        Column(
          children: [
            _MusicTrackTableHeader(
              libraryStyle: libraryStyle,
              playlistStyle: playlistStyle,
            ),
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
                libraryStyle: libraryStyle,
                playlistStyle: playlistStyle,
                hideHoverPlayControl: hideHoverPlayControl,
                bareMoreAction: bareMoreAction,
                density: density,
                trackActionsContext: trackActionsContext,
              ),
          ],
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
    required this.libraryStyle,
    this.trailing,
  });

  final String countLabel;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffleAll;
  final VoidCallback? onAddAllToQueue;
  final bool libraryStyle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (libraryStyle)
          Text('全部歌曲', style: Theme.of(context).textTheme.headlineSmall)
        else
          MetaPill(label: countLabel, size: MetaPillSize.compact),
        if (libraryStyle) ...[
          const SizedBox(width: 10),
          MetaPill(label: countLabel, size: MetaPillSize.compact),
        ],
        const Spacer(),
        MusicTrackTableActions(
          onPlayAll: onPlayAll,
          onShuffleAll: onShuffleAll,
          onAddAllToQueue: onAddAllToQueue,
          trailing: trailing,
        ),
      ],
    );
  }
}

class MusicTrackTableActions extends StatelessWidget {
  const MusicTrackTableActions({
    super.key,
    this.onPlayAll,
    this.onShuffleAll,
    this.onAddAllToQueue,
    this.trailing,
  });

  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffleAll;
  final VoidCallback? onAddAllToQueue;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        if (trailing != null) ...[const SizedBox(width: 14), trailing!],
      ],
    );
  }
}

class _MusicTrackTableHeader extends StatelessWidget {
  const _MusicTrackTableHeader({
    required this.libraryStyle,
    required this.playlistStyle,
  });

  final bool libraryStyle;
  final bool playlistStyle;

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
        final showAlbum = constraints.maxWidth >= (playlistStyle ? 680 : 620);
        final showQuality = libraryStyle && constraints.maxWidth >= 1120;
        final horizontalPadding = libraryStyle
            ? 20.0
            : playlistStyle
            ? 16.0
            : 12.0;
        final verticalPadding = libraryStyle
            ? 6.0
            : playlistStyle
            ? 8.0
            : 4.0;

        return Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            libraryStyle
                ? 6
                : playlistStyle
                ? 8
                : 8,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          child: Row(
            children: [
              if (libraryStyle)
                Expanded(
                  flex: 5,
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
                      Expanded(child: Text('歌曲 / 艺术家', style: labelStyle)),
                    ],
                  ),
                )
              else ...[
                SizedBox(
                  width: playlistStyle ? 48 : 36,
                  child: Text(
                    '#',
                    style: labelStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: playlistStyle ? 0 : 12),
                Expanded(flex: 4, child: Text('标题', style: labelStyle)),
              ],
              if (showAlbum) ...[
                SizedBox(width: playlistStyle ? 0 : 12),
                if (playlistStyle)
                  SizedBox(width: 192, child: Text('专辑', style: labelStyle))
                else
                  Expanded(
                    flex: libraryStyle ? 2 : 3,
                    child: Text('专辑', style: labelStyle),
                  ),
              ],
              if (showQuality) ...[
                const SizedBox(width: 12),
                SizedBox(width: 56, child: Text('质量', style: labelStyle)),
              ],
              SizedBox(width: playlistStyle ? 0 : 12),
              SizedBox(
                width: playlistStyle ? 64 : 80,
                child: Text(
                  '时长',
                  style: labelStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              if (!playlistStyle) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: libraryStyle ? 96 : 88,
                  child: libraryStyle
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 18,
                              color: theme.muted,
                            ),
                            const SizedBox(width: 28),
                            Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                              color: theme.muted,
                            ),
                          ],
                        )
                      : null,
                ),
              ],
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
    required this.libraryStyle,
    required this.playlistStyle,
    required this.hideHoverPlayControl,
    required this.bareMoreAction,
    required this.density,
    required this.trackActionsContext,
  });

  final int index;
  final MusicTrack track;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onAddToQueue;
  final MusicTrackTableTrailingBuilder? trailingBuilder;
  final bool libraryStyle;
  final bool playlistStyle;
  final bool hideHoverPlayControl;
  final bool bareMoreAction;
  final MusicTrackTableDensity density;
  final TrackActionsContext trackActionsContext;

  @override
  State<_MusicTrackTableRow> createState() => _MusicTrackTableRowState();
}

class _MusicTrackTableRowState extends State<_MusicTrackTableRow> {
  bool _hovered = false;
  bool _playHovered = false;
  bool _focused = false;
  bool _menuOpen = false;

  Future<void> _showMenu(MusicTrack track) async {
    setState(() => _menuOpen = true);
    await showTrackActionsSheet(
      context,
      track,
      source: widget.trackActionsContext,
    );
    if (mounted) setState(() => _menuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlighted = _hovered || _focused || _menuOpen;
    final track = widget.track;
    final displayTitle = MediaDisplayText.trackTitle(track.title);
    final indexLabel = widget.libraryStyle || widget.playlistStyle
        ? '${widget.index + 1}'
        : (widget.index + 1).toString().padLeft(2, '0');
    final trailing = widget.trailingBuilder?.call(context, track, _hovered);
    final rowHeight = switch (widget.density) {
      MusicTrackTableDensity.compact => 52.0,
      MusicTrackTableDensity.comfortable => 68.0,
    };

    return Semantics(
      container: true,
      label: widget.libraryStyle ? null : '播放《$displayTitle》',
      button: !widget.libraryStyle,
      selected: widget.isCurrent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        opaque: true,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.playlistStyle ? 0 : 1),
          child: Material(
            color: widget.isCurrent
                ? theme.selectedWash
                : highlighted
                ? theme.hoverWash
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: widget.libraryStyle
                  ? null
                  : ValueKey('track-row-play-${track.id}'),
              focusColor: colorScheme.primary.withValues(alpha: 0.08),
              hoverColor: Colors.transparent,
              splashColor: colorScheme.primary.withValues(alpha: 0.06),
              highlightColor: Colors.transparent,
              mouseCursor: widget.libraryStyle
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              onFocusChange: (value) => setState(() => _focused = value),
              onTap: widget.libraryStyle ? null : widget.onTap,
              onSecondaryTap: () => _showMenu(track),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showAlbum =
                      constraints.maxWidth >=
                      (widget.playlistStyle ? 680 : 620);
                  final showQuality =
                      widget.libraryStyle && constraints.maxWidth >= 1120;

                  return ConstrainedBox(
                    constraints: BoxConstraints(minHeight: rowHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.libraryStyle
                            ? 20
                            : widget.playlistStyle
                            ? 16
                            : 12,
                        vertical: widget.libraryStyle
                            ? 4
                            : widget.playlistStyle
                            ? 2
                            : 4,
                      ),
                      child: Row(
                        children: [
                          if (widget.libraryStyle)
                            Expanded(
                              flex: 5,
                              child: Semantics(
                                label: '播放《$displayTitle》',
                                button: true,
                                selected: widget.isCurrent,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) =>
                                      setState(() => _playHovered = true),
                                  onExit: (_) =>
                                      setState(() => _playHovered = false),
                                  child: InkWell(
                                    key: ValueKey('track-row-play-${track.id}'),
                                    onTap: widget.onTap,
                                    hoverColor: Colors.transparent,
                                    splashColor: colorScheme.primary.withValues(
                                      alpha: 0.06,
                                    ),
                                    highlightColor: Colors.transparent,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: rowHeight - 8,
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
                                                      color:
                                                          colorScheme.primary,
                                                    )
                                                  : _playHovered &&
                                                        !widget
                                                            .hideHoverPlayControl
                                                  ? Icon(
                                                      Icons.play_arrow_rounded,
                                                      size: 22,
                                                      color:
                                                          colorScheme.onSurface,
                                                    )
                                                  : Text(
                                                      indexLabel,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                            fontFeatures: const [
                                                              FontFeature.tabularFigures(),
                                                            ],
                                                          ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _MusicTrackTitleCell(
                                              track: track,
                                              isCurrent: widget.isCurrent,
                                              showSubtitle: true,
                                              showArtwork: true,
                                              showCodecBadge: false,
                                              artworkSize:
                                                  widget.density ==
                                                      MusicTrackTableDensity
                                                          .comfortable
                                                  ? 48
                                                  : 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            SizedBox(
                              width: widget.playlistStyle ? 48 : 36,
                              child: Center(
                                child: widget.isCurrent
                                    ? Icon(
                                        Icons.graphic_eq_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      )
                                    : highlighted &&
                                          !widget.hideHoverPlayControl
                                    ? Icon(
                                        Icons.play_arrow_rounded,
                                        size: 20,
                                        color: colorScheme.primary,
                                      )
                                    : Text(
                                        indexLabel,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                      ),
                              ),
                            ),
                            SizedBox(width: widget.playlistStyle ? 0 : 12),
                            Expanded(
                              flex: 4,
                              child: _MusicTrackTitleCell(
                                track: track,
                                isCurrent: widget.isCurrent,
                                showSubtitle: true,
                              ),
                            ),
                          ],
                          if (showAlbum) ...[
                            SizedBox(width: widget.playlistStyle ? 0 : 12),
                            if (widget.playlistStyle)
                              SizedBox(
                                width: 192,
                                child: _MusicTrackTableText(
                                  MediaDisplayText.albumTitle(track.albumTitle),
                                  highlighted: widget.isCurrent,
                                ),
                              )
                            else
                              Expanded(
                                flex: widget.libraryStyle ? 2 : 3,
                                child: _MusicTrackTableText(
                                  MediaDisplayText.albumTitle(track.albumTitle),
                                  highlighted: widget.isCurrent,
                                ),
                              ),
                          ],
                          if (showQuality) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 56,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: MetaPill(
                                  label: _trackQualityLabel(track),
                                  size: MetaPillSize.compact,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(width: widget.playlistStyle ? 0 : 12),
                          SizedBox(
                            width: widget.playlistStyle ? 64 : 80,
                            child: Text(
                              _formatTrackDuration(track.duration),
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.isCurrent
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          if (!widget.playlistStyle) ...[
                            const SizedBox(width: 8),
                            AnimatedOpacity(
                              duration: AppMotion.micro,
                              curve: AppMotion.enter,
                              opacity:
                                  widget.libraryStyle ||
                                      highlighted ||
                                      widget.isCurrent
                                  ? 1
                                  : 0,
                              child: SizedBox(
                                width: widget.libraryStyle ? 96 : 88,
                                child:
                                    trailing ??
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (widget.onAddToQueue != null)
                                          _MusicTrackTableIconButton(
                                            icon: Icons.playlist_add_rounded,
                                            tooltip: '加入队列',
                                            onPressed: widget.onAddToQueue!,
                                          ),
                                        _MusicTrackTableIconButton(
                                          icon: Icons.more_horiz_rounded,
                                          tooltip: '更多操作',
                                          onPressed: () => _showMenu(track),
                                          bare: widget.bareMoreAction,
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
    this.showArtwork = false,
    this.artworkSize = 40,
    this.showCodecBadge = true,
  });

  final MusicTrack track;
  final bool isCurrent;
  final bool showSubtitle;
  final bool showArtwork;
  final double artworkSize;
  final bool showCodecBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = MediaDisplayText.trackTitle(track.title);
    final displayArtist = MediaDisplayText.artistName(track.artistName);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Tooltip(
                message: displayTitle,
                child: Text(
                  displayTitle,
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
            ),
            if (showSubtitle &&
                showCodecBadge &&
                track.codec?.toLowerCase() == 'flac') ...[
              const SizedBox(width: 8),
              const MetaPill(label: 'FLAC', size: MetaPillSize.compact),
            ],
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 2),
          Tooltip(
            message: displayArtist,
            child: Text(
              displayArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.muted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
    if (!showArtwork) return text;
    return Row(
      children: [
        CachedArtwork(
          imageUrl: track.artworkUrl,
          size: artworkSize,
          borderRadius: AppRadiusTokens.desktopSm,
          semanticLabel: '$displayTitle 封面',
        ),
        const SizedBox(width: 12),
        Expanded(child: text),
      ],
    );
  }
}

String _trackQualityLabel(MusicTrack track) {
  final codec = (track.codec ?? track.container ?? '').trim().toUpperCase();
  if (codec == 'FLAC') return 'FLAC';
  if (track.bitRate != null && track.bitRate! > 0) {
    return '${(track.bitRate! / 1000).round()}k';
  }
  return codec.isEmpty ? '—' : codec;
}

class _MusicTrackTableText extends StatelessWidget {
  const _MusicTrackTableText(this.text, {this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: highlighted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MusicTrackTableIconButton extends StatelessWidget {
  const _MusicTrackTableIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.bare = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool bare;

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
        style:
            AppActionButtonStyle.icon(
              context,
              iconSize: 18,
              radius: AppRadiusTokens.desktopSm,
            ).copyWith(
              backgroundColor: bare
                  ? const WidgetStatePropertyAll(Colors.transparent)
                  : null,
              overlayColor: bare
                  ? const WidgetStatePropertyAll(Colors.transparent)
                  : null,
              side: bare ? const WidgetStatePropertyAll(BorderSide.none) : null,
              mouseCursor: bare
                  ? const WidgetStatePropertyAll(SystemMouseCursors.click)
                  : null,
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

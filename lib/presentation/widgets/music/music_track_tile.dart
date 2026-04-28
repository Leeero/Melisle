import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:flutter/material.dart';

enum MusicTrackTileStyle { card, row, list }

class MusicTrackTile extends StatefulWidget {
  const MusicTrackTile.card({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.isCurrent,
    required this.onTap,
    this.onLongPress,
    this.statusLabel,
    this.extraTrailing,
    this.idleIcon = Icons.play_arrow_rounded,
  }) : style = MusicTrackTileStyle.card;

  const MusicTrackTile.row({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.isCurrent,
    required this.onTap,
    this.onLongPress,
    this.statusLabel,
    this.extraTrailing,
    this.idleIcon = Icons.play_arrow_rounded,
  }) : style = MusicTrackTileStyle.row;

  const MusicTrackTile.list({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.onTap,
    this.idleIcon = Icons.play_arrow_rounded,
  }) : style = MusicTrackTileStyle.list,
       isCurrent = false,
       onLongPress = null,
       statusLabel = null,
       extraTrailing = null;

  final String title;
  final String subtitle;
  final String artworkUrl;
  final bool isCurrent;
  final Future<void> Function() onTap;
  final VoidCallback? onLongPress;
  final String? statusLabel;
  final Widget? extraTrailing;
  final IconData idleIcon;
  final MusicTrackTileStyle style;

  @override
  State<MusicTrackTile> createState() => _MusicTrackTileState();
}

class _MusicTrackTileState extends State<MusicTrackTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.style == MusicTrackTileStyle.list) {
      return _buildListTile(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isCard = widget.style == MusicTrackTileStyle.card;
    final radius = isCard ? 20.0 : 24.0;
    final artworkSize = isCard ? 58.0 : 48.0;
    final artworkRadius = isCard ? 20.0 : 14.0;
    final horizontalPadding = isCard ? 14.0 : 12.0;
    final verticalPadding = isCard ? 12.0 : 10.0;
    final shadow =
        widget.style == MusicTrackTileStyle.row && _hovered && !widget.isCurrent
        ? [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : const <BoxShadow>[];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: widget.isCurrent
              ? colorScheme.primaryContainer.withValues(alpha: 0.8)
              : colorScheme.surface.withValues(alpha: _hovered ? 0.82 : 0.62),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: widget.isCurrent
                ? colorScheme.primary.withValues(alpha: 0.28)
                : colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: () {
              widget.onTap();
            },
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Row(
                children: [
                  CachedArtwork(
                    imageUrl: widget.artworkUrl,
                    size: artworkSize,
                    borderRadius: artworkRadius,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCard)
                          Row(
                            children: [
                              Expanded(child: _buildTitle(context)),
                              if (widget.isCurrent) ...[
                                const SizedBox(width: 8),
                                const MetaPill(
                                  label: '当前播放',
                                  size: MetaPillSize.compact,
                                ),
                              ],
                            ],
                          )
                        else
                          _buildTitle(context),
                        SizedBox(height: isCard ? 4 : 2),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        if (!isCard && widget.statusLabel != null) ...[
                          const SizedBox(height: 8),
                          MetaPill(label: widget.statusLabel!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.extraTrailing != null) ...[
                    widget.extraTrailing!,
                    const SizedBox(width: 10),
                  ],
                  _buildIndicator(context, isCard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context) {
    return ListTile(
      leading: CachedArtwork(
        imageUrl: widget.artworkUrl,
        size: 48,
        borderRadius: 14,
      ),
      title: _buildTitle(context),
      subtitle: Text(
        widget.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(widget.idleIcon),
      onTap: () {
        widget.onTap();
      },
    );
  }

  Widget _buildTitle(BuildContext context) {
    final titleStyle = widget.style == MusicTrackTileStyle.card
        ? Theme.of(context).textTheme.titleMedium
        : null;

    return Text(
      widget.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );
  }

  Widget _buildIndicator(BuildContext context, bool isCard) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isCard) {
      return Icon(
        widget.isCurrent ? Icons.graphic_eq_rounded : widget.idleIcon,
        color: widget.isCurrent
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: widget.isCurrent
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        widget.isCurrent ? Icons.graphic_eq_rounded : widget.idleIcon,
        color: widget.isCurrent
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

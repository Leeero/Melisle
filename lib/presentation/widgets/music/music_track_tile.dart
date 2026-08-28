import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/playing_indicator.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

enum MusicTrackTileStyle { card, favorite, row, list }

class MusicTrackTile extends StatefulWidget {
  const MusicTrackTile.card({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.isCurrent,
    required this.onTap,
    this.onLongPress,
    this.onMore,
    this.statusLabel,
    this.extraTrailing,
    this.idleIcon = Icons.play_arrow_rounded,
  }) : style = MusicTrackTileStyle.card;

  const MusicTrackTile.favorite({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.isCurrent,
    required this.onTap,
    this.onLongPress,
    this.onMore,
    this.statusLabel,
    this.extraTrailing,
    this.idleIcon = Icons.play_arrow_rounded,
  }) : style = MusicTrackTileStyle.favorite;

  const MusicTrackTile.row({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.isCurrent,
    required this.onTap,
    this.onLongPress,
    this.onMore,
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
       onMore = null,
       statusLabel = null,
       extraTrailing = null;

  final String title;
  final String subtitle;
  final String artworkUrl;
  final bool isCurrent;
  final Future<void> Function() onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMore;
  final String? statusLabel;
  final Widget? extraTrailing;
  final IconData idleIcon;
  final MusicTrackTileStyle style;

  @override
  State<MusicTrackTile> createState() => _MusicTrackTileState();
}

class _MusicTrackTileState extends State<MusicTrackTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    if (widget.style == MusicTrackTileStyle.list ||
        (compact && widget.style == MusicTrackTileStyle.row)) {
      return _buildListTile(context, selected: widget.isCurrent);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCard =
        widget.style == MusicTrackTileStyle.card ||
        widget.style == MusicTrackTileStyle.favorite;
    final isFavorite = widget.style == MusicTrackTileStyle.favorite;
    final radius = isCard
        ? AppRadiusTokens.mobileLg
        : AppRadiusTokens.desktopSm;
    final artworkSize = isFavorite
        ? AppSpacingTokens.favoriteTrackArtwork
        : (isCard ? 58.0 : 44.0);
    final artworkRadius = isCard ? AppRadiusTokens.mobileLg : 8.0;
    final horizontalPadding = isFavorite
        ? AppSpacingTokens.favoriteTrackPadding
        : (isCard ? 14.0 : 12.0);
    final verticalPadding = isFavorite
        ? AppSpacingTokens.favoriteTrackPadding
        : (isCard ? 12.0 : 4.0);
    final contentGap = isFavorite
        ? AppSpacingTokens.favoriteTrackContentGap
        : 14.0;
    final shadow = isCard && _hovered && !widget.isCurrent
        ? [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.24)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : (isCard && theme.brightness == Brightness.light
            ? AppShadowTokens.card
            : <BoxShadow>[]);

    return Semantics(
      label: '播放《${widget.title}》',
      button: true,
      selected: widget.isCurrent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? theme.selectedWash
                : _pressed
                ? theme.hoverWash
                : _hovered
                ? theme.hoverWash
                : colorScheme.surface.withValues(alpha: isCard ? 0.92 : 0),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: widget.isCurrent
                  ? colorScheme.primary.withValues(alpha: 0.20)
                  : colorScheme.outlineVariant.withValues(
                      alpha: isCard ? 0.58 : 0,
                    ),
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
              mouseCursor: SystemMouseCursors.click,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
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
                      semanticLabel: '《${widget.title}》封面',
                    ),
                    SizedBox(width: contentGap),
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
                                  const PlayingIndicator(
                                    isPlaying: true,
                                    size: 8,
                                  ),
                                  const SizedBox(width: 6),
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
                            style: Theme.of(context).textTheme.bodySmall
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
                    if (widget.onMore != null)
                      _MoreButton(onPressed: widget.onMore!)
                    else
                      _buildIndicator(context, isCard),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required bool selected}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = selected
        ? theme.selectedWash
        : _pressed
        ? theme.hoverWash
        : Colors.transparent;

    return Semantics(
      label: '播放《${widget.title}》',
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: selected || _pressed
                ? BorderRadius.circular(AppRadiusTokens.mobileSm)
                : BorderRadius.zero,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.mobileSm),
              onTap: () {
                widget.onTap();
              },
              onLongPress: widget.onLongPress,
              mouseCursor: SystemMouseCursors.click,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              hoverColor: Colors.transparent,
              focusColor: colorScheme.primary.withValues(alpha: 0.08),
              splashColor: colorScheme.primary.withValues(alpha: 0.06),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacingTokens.compactGap,
                ),
                child: Row(
                  children: [
                    CachedArtwork(
                      imageUrl: widget.artworkUrl,
                      size: 44,
                      borderRadius: AppRadiusTokens.mobileSm,
                      semanticLabel: '《${widget.title}》封面',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTitle(context, selected: selected),
                          const SizedBox(height: 1),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.extraTrailing != null) ...[
                      const SizedBox(width: 8),
                      widget.extraTrailing!,
                    ] else if (widget.onMore != null) ...[
                      const SizedBox(width: 8),
                      _MoreButton(onPressed: widget.onMore!),
                    ] else ...[
                      const SizedBox(width: 8),
                      SizedBox.square(
                        dimension: 44,
                        child: Icon(
                          selected ? Icons.graphic_eq_rounded : widget.idleIcon,
                          size: 20,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, {bool selected = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compactRow =
        AppBreakpoints.isCompact(context) &&
        widget.style == MusicTrackTileStyle.row;
    final titleStyle = switch (widget.style) {
      MusicTrackTileStyle.card => theme.textTheme.titleMedium,
      MusicTrackTileStyle.favorite => theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      MusicTrackTileStyle.row =>
        compactRow
            ? theme.textTheme.bodyMedium?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              )
            : theme.textTheme.titleSmall?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
      MusicTrackTileStyle.list => theme.textTheme.bodyMedium?.copyWith(
        color: selected ? colorScheme.primary : colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    };

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

    return Icon(
      widget.isCurrent ? Icons.graphic_eq_rounded : widget.idleIcon,
      color: widget.isCurrent
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant,
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '更多操作',
      button: true,
      child: Tooltip(
        message: '更多操作',
        child: SizedBox.square(
          dimension: 44,
          child: IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ),
      ),
    );
  }
}

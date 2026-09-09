import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class MobileTrackRow extends StatefulWidget {
  const MobileTrackRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.artworkUrl,
    this.leading,
    this.trailing,
    this.onLongPress,
  }) : assert(artworkUrl != null || leading != null);

  final String title;
  final String subtitle;
  final bool selected;
  final Future<void> Function() onTap;
  final String? artworkUrl;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onLongPress;

  @override
  State<MobileTrackRow> createState() => _MobileTrackRowState();
}

class _MobileTrackRowState extends State<MobileTrackRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.mobileTheme;

    return Semantics(
      label: '播放《${widget.title}》',
      button: true,
      selected: widget.selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.outlineVariant, width: 0.5),
          ),
        ),
        child: AnimatedContainer(
          duration: AppMotion.adaptive(context, AppMotion.fast),
          constraints: const BoxConstraints(
            minHeight: AppSpacingTokens.mobileTrackRowHeight,
          ),
          color: widget.selected
              ? colors.primary.withValues(alpha: 0.08)
              : _pressed
              ? colors.surfaceMuted
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    widget.leading ?? _buildArtwork(colors),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: widget.selected
                                      ? colors.primary
                                      : colors.onSurface,
                                  fontSize:
                                      AppTypographyTokens.mobileTrackTitle,
                                  fontWeight: widget.selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontSize: AppTypographyTokens.mobileMetadata,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 8),
                      widget.trailing!,
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

  Widget _buildArtwork(AppMobileTheme colors) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CachedArtwork(
          imageUrl: widget.artworkUrl!,
          size: AppSpacingTokens.mobileTrackArtwork,
          borderRadius: AppRadiusTokens.mobileSm,
          semanticLabel: '《${widget.title}》封面',
        ),
        if (widget.selected)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.88),
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(
              dimension: 24,
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

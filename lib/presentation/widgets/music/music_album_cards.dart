import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/hover_scale.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class MusicAlbumGridCard extends StatefulWidget {
  const MusicAlbumGridCard({
    super.key,
    required this.album,
    required this.onTap,
    this.artworkRadius = AppRadiusTokens.coverGrid,
    this.scaleOnHover = 1.012,
    this.compact = false,
  });

  final MusicAlbum album;
  final VoidCallback onTap;
  final double artworkRadius;
  final double scaleOnHover;
  final bool compact;

  @override
  State<MusicAlbumGridCard> createState() => _MusicAlbumGridCardState();
}

class _MusicAlbumGridCardState extends State<MusicAlbumGridCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final album = widget.album;
    final displayTitle = MediaDisplayText.albumTitle(album.title);
    final displayArtist = MediaDisplayText.artistName(album.artistName);
    final metadata = [
      displayArtist,
      if (album.year != null) '${album.year}',
      '${album.trackCount} 首',
    ].join(' · ');
    final textTheme = theme.textTheme;
    final compact = widget.compact;
    final contentPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 4)
        : EdgeInsets.zero;
    final titleStyle = compact
        ? textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.22,
          )
        : textTheme.titleMedium;
    final subtitleStyle = compact
        ? textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.18,
          )
        : textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant);

    return Semantics(
      label: '打开专辑《$displayTitle》',
      button: true,
      child: HoverScale(
        scale: widget.scaleOnHover,
        translateY: -2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: contentPadding,
              child: AspectRatio(
                aspectRatio: 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(widget.artworkRadius),
                    onTap: widget.onTap,
                    mouseCursor: SystemMouseCursors.click,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          widget.artworkRadius,
                        ),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.30
                                : 0.50,
                          ),
                          width: 1.0,
                        ),
                        boxShadow: theme.brightness == Brightness.dark
                            ? <BoxShadow>[]
                            : AppShadowTokens.card,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          widget.artworkRadius,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return CachedArtwork(
                              imageUrl: album.artworkUrl,
                              size: constraints.maxWidth,
                              borderRadius: 0,
                              semanticLabel: '《$displayTitle》专辑封面',
                              placeholderBuilder: (_) =>
                                  _AlbumArtworkPlaceholder(
                                    size: constraints.maxWidth,
                                  ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: compact
                  ? AppSpacingTokens.compactGap
                  : AppSpacingTokens.inlineGapCompact,
            ),
            Padding(
              padding: contentPadding,
              child: Tooltip(
                message: displayTitle,
                child: Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ),
            SizedBox(height: compact ? 1 : 2),
            Padding(
              padding: contentPadding,
              child: Tooltip(
                message: metadata,
                child: Text(
                  metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumArtworkPlaceholder extends StatelessWidget {
  const _AlbumArtworkPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = size < 140;

    return ExcludeSemantics(
      child: ColoredBox(
        color: colorScheme.surfaceContainerHigh,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.album_outlined,
                size: compact ? 28 : 40,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.62),
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  '无封面',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.78,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

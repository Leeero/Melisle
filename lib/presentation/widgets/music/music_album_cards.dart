import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
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
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final album = widget.album;
    final displayTitle = MediaDisplayText.albumTitle(album.title);
    final displayArtist = MediaDisplayText.artistName(album.artistName);
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          scale: _pressed
              ? 0.992
              : _hovered
              ? widget.scaleOnHover
              : 1,
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
                      onHighlightChanged: (pressed) =>
                          setState(() => _pressed = pressed),
                      child: AnimatedContainer(
                        duration: AppMotion.micro,
                        curve: AppMotion.enter,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            widget.artworkRadius,
                          ),
                          border: Border.all(
                            color: _hovered
                                ? colorScheme.outlineVariant.withValues(
                                    alpha: theme.brightness == Brightness.dark
                                        ? 0.42
                                        : 0.56,
                                  )
                                : Colors.transparent,
                            width: 1.0,
                          ),
                          boxShadow: _hovered
                              ? [
                                  BoxShadow(
                                    color: theme.musicRose.withValues(
                                      alpha: theme.brightness == Brightness.dark
                                          ? 0.18
                                          : 0.14,
                                    ),
                                    blurRadius: compact ? 14 : 18,
                                    offset: Offset(0, compact ? 5 : 7),
                                  ),
                                ]
                              : const <BoxShadow>[],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            widget.artworkRadius,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final artworkSize = constraints.maxWidth;
                                  return CachedArtwork(
                                    imageUrl: album.artworkUrl,
                                    size: artworkSize,
                                    borderRadius: 0,
                                    semanticLabel: '《$displayTitle》专辑封面',
                                  );
                                },
                              ),
                              AnimatedOpacity(
                                duration: AppMotion.micro,
                                curve: AppMotion.enter,
                                opacity: _hovered ? 1 : 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColorTokens.darkScaffold
                                        .withValues(alpha: 0.10),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: compact ? 34 : 42,
                                      color: AppColorTokens.lightScaffold
                                          .withValues(alpha: 0.88),
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
              ),
              SizedBox(height: compact ? 7 : 10),
              Padding(
                padding: contentPadding,
                child: Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              Padding(
                padding: contentPadding,
                child: Text(
                  [
                    displayArtist,
                    if (album.year != null) '${album.year}',
                    '${album.trackCount} 首',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

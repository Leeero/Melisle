import 'package:cross_platform_music_player/domain/entities/music_album.dart';
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
  });

  final MusicAlbum album;
  final VoidCallback onTap;
  final double artworkRadius;
  final double scaleOnHover;

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
    final textTheme = theme.textTheme;

    return Semantics(
      label: '打开专辑《${album.title}》',
      button: true,
      child: MouseRegion(
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
              AspectRatio(
                aspectRatio: 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(widget.artworkRadius),
                    onTap: widget.onTap,
                    onHighlightChanged: (pressed) =>
                        setState(() => _pressed = pressed),
                    child: AnimatedContainer(
                      duration: AppMotion.micro,
                      curve: AppMotion.enter,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          widget.artworkRadius,
                        ),
                        boxShadow: _hovered
                            ? [
                                BoxShadow(
                                  color: theme.musicRose.withValues(
                                    alpha: theme.brightness == Brightness.dark
                                        ? 0.18
                                        : 0.14,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7),
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
                                  semanticLabel: '《${album.title}》专辑封面',
                                );
                              },
                            ),
                            AnimatedOpacity(
                              duration: AppMotion.micro,
                              curve: AppMotion.enter,
                              opacity: _hovered ? 1 : 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColorTokens.darkScaffold.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    size: 42,
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
              const SizedBox(height: 10),
              Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                [
                  album.artistName,
                  if (album.year != null) '${album.year}',
                  '${album.trackCount} 首',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

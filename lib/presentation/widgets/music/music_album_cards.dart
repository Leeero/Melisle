import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/meta_pill.dart';
import 'package:flutter/material.dart';

class MusicAlbumGridCard extends StatefulWidget {
  const MusicAlbumGridCard({
    super.key,
    required this.album,
    required this.onTap,
    required this.footer,
    this.badgeLabel,
    this.artworkSize = 170,
    this.artworkRadius = 24,
    this.contentRadius = 20,
    this.coverRadius = 30,
    this.scaleOnHover = 1.015,
  });

  final MusicAlbum album;
  final VoidCallback onTap;
  final Widget footer;
  final String? badgeLabel;
  final double artworkSize;
  final double artworkRadius;
  final double contentRadius;
  final double coverRadius;
  final double scaleOnHover;

  @override
  State<MusicAlbumGridCard> createState() => _MusicAlbumGridCardState();
}

class _MusicAlbumGridCardState extends State<MusicAlbumGridCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final album = widget.album;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _hovered ? widget.scaleOnHover : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.contentRadius),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.contentRadius),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer.withValues(
                            alpha: 0.58,
                          ),
                          borderRadius: BorderRadius.circular(
                            widget.coverRadius,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: CachedArtwork(
                                imageUrl: album.artworkUrl,
                                size: widget.artworkSize,
                                borderRadius: widget.artworkRadius,
                                semanticLabel: '《${album.title}》专辑封面',
                              ),
                            ),
                            if (widget.badgeLabel != null)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: _hovered ? 1 : 0.75,
                                  child: MetaPill(
                                    label: widget.badgeLabel!,
                                    size: MetaPillSize.compact,
                                    backgroundColor: colorScheme.surface
                                        .withValues(alpha: 0.72),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    widget.footer,
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

class MusicAlbumCompactCard extends StatelessWidget {
  const MusicAlbumCompactCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  final MusicAlbum album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedArtwork(
                    imageUrl: album.artworkUrl,
                    size: 160,
                    borderRadius: 18,
                    semanticLabel: '《${album.title}》专辑封面',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  album.year == null ? album.artistName : '${album.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

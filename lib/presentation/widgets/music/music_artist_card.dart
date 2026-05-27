import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:flutter/material.dart';

class MusicArtistGridCard extends StatelessWidget {
  const MusicArtistGridCard({
    super.key,
    required this.artist,
    required this.onTap,
  });

  final MusicArtist artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '打开艺术家《${artist.name}》',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artworkSize = constraints.maxWidth * 0.78;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.11,
                  ),
                  child: CachedArtwork(
                    imageUrl: artist.artworkUrl,
                    size: artworkSize,
                    borderRadius: artworkSize / 2,
                    semanticLabel: '${artist.name} 头像',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  artist.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${artist.trackCount} 首歌曲',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

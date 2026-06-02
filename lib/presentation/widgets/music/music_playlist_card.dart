import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class MusicPlaylistGridCard extends StatefulWidget {
  const MusicPlaylistGridCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.artworkRadius = AppRadiusTokens.coverGrid,
    this.scaleOnHover = 1.012,
  });

  final MusicPlaylist playlist;
  final VoidCallback onTap;
  final double artworkRadius;
  final double scaleOnHover;

  @override
  State<MusicPlaylistGridCard> createState() => _MusicPlaylistGridCardState();
}

class _MusicPlaylistGridCardState extends State<MusicPlaylistGridCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playlist = widget.playlist;
    final textTheme = theme.textTheme;

    return Semantics(
      label: '打开歌单《${playlist.name}》',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          duration: AppMotion.short,
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
                      duration: AppMotion.short,
                      curve: AppMotion.enter,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          widget.artworkRadius,
                        ),
                        boxShadow: _hovered
                            ? [
                                BoxShadow(
                                  color: theme.musicTeal.withValues(
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
                                return CachedArtwork(
                                  imageUrl: playlist.artworkUrl,
                                  size: constraints.maxWidth,
                                  borderRadius: 0,
                                  semanticLabel: '《${playlist.name}》歌单封面',
                                );
                              },
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: _PlaylistCountBadge(
                                count: playlist.trackCount,
                              ),
                            ),
                            Positioned.fill(
                              child: AnimatedOpacity(
                                duration: AppMotion.micro,
                                curve: AppMotion.enter,
                                opacity: _hovered ? 1 : 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColorTokens.darkScaffold
                                        .withValues(alpha: 0.12),
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
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                '${playlist.trackCount} 首歌曲',
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

class MusicPlaylistListTile extends StatefulWidget {
  const MusicPlaylistListTile({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  final MusicPlaylist playlist;
  final VoidCallback onTap;

  @override
  State<MusicPlaylistListTile> createState() => _MusicPlaylistListTileState();
}

class _MusicPlaylistListTileState extends State<MusicPlaylistListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playlist = widget.playlist;

    return Semantics(
      label: '打开歌单《${playlist.name}》',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          decoration: BoxDecoration(
            color: _hovered ? theme.hoverWash : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CachedArtwork(
                      imageUrl: playlist.artworkUrl,
                      size: 52,
                      borderRadius: 12,
                      semanticLabel: '《${playlist.name}》歌单封面',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${playlist.trackCount} 首歌曲',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
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

class _PlaylistCountBadge extends StatelessWidget {
  const _PlaylistCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColorTokens.darkScaffold.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.queue_music_rounded,
              size: 13,
              color: Color(0xFFF6F8FC),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFF6F8FC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

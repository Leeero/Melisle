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
    this.compact = false,
  });

  final MusicPlaylist playlist;
  final VoidCallback onTap;
  final double artworkRadius;
  final double scaleOnHover;
  final bool compact;

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
    final subtitle = _playlistSubtitle(playlist);
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
      label: '打开歌单《${playlist.name}》',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
                        duration: AppMotion.short,
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
                                    color: theme.musicTeal.withValues(
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
                                  return CachedArtwork(
                                    imageUrl: playlist.artworkUrl,
                                    size: constraints.maxWidth,
                                    borderRadius: 0,
                                    semanticLabel: '《${playlist.name}》歌单封面',
                                  );
                                },
                              ),
                              if (playlist.trackCount > 0)
                                Positioned(
                                  right: compact ? 6 : 8,
                                  bottom: compact ? 6 : 8,
                                  child: _PlaylistCountBadge(
                                    count: playlist.trackCount,
                                    compact: compact,
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
                                        size: compact ? 34 : 42,
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
              ),
              SizedBox(height: compact ? 7 : 10),
              Padding(
                padding: contentPadding,
                child: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              Padding(
                padding: contentPadding,
                child: Text(
                  subtitle,
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
    final subtitle = _playlistSubtitle(playlist);

    return Semantics(
      label: '打开歌单《${playlist.name}》',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
              mouseCursor: SystemMouseCursors.click,
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
                            subtitle,
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

String _playlistSubtitle(MusicPlaylist playlist) {
  return playlist.trackCount > 0 ? '${playlist.trackCount} 首歌曲' : '歌单';
}

class _PlaylistCountBadge extends StatelessWidget {
  const _PlaylistCountBadge({required this.count, this.compact = false});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColorTokens.darkScaffold.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: compact ? 11 : 13,
              color: const Color(0xFFF6F8FC),
            ),
            SizedBox(width: compact ? 3 : 4),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFF6F8FC),
                fontWeight: FontWeight.w700,
                fontSize: compact ? 10 : null,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

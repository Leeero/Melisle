import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class MusicArtistGridCard extends StatefulWidget {
  const MusicArtistGridCard({
    super.key,
    required this.artist,
    required this.onTap,
    this.compact = false,
  });

  final MusicArtist artist;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<MusicArtistGridCard> createState() => _MusicArtistGridCardState();
}

class _MusicArtistGridCardState extends State<MusicArtistGridCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final artist = widget.artist;
    final displayName = MediaDisplayText.artistName(artist.name);
    final compact = widget.compact;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = AppBreakpoints.usesDesktopToolbar(context);
        final narrow = constraints.maxWidth < 118 || compact;
        final artworkSize = desktop
            ? 112.0
            : compact
            ? 84.0
            : 96.0;
        final titleStyle = theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w500,
          height: 1.3,
        );
        final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: compact ? 12 : 13,
          height: 1.3,
        );
        final cardRadius = BorderRadius.circular(AppRadiusTokens.card);
        final hoverColor = theme.hoverWash;

        return Align(
          alignment: Alignment.topCenter,
          child: Semantics(
            label: '打开歌手《$displayName》',
            button: true,
            onTap: widget.onTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: AnimatedContainer(
                width: constraints.maxWidth,
                duration: AppMotion.micro,
                curve: AppMotion.enter,
                decoration: BoxDecoration(
                  borderRadius: cardRadius,
                  color: _hovered
                      ? hoverColor
                      : hoverColor.withValues(alpha: 0),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: cardRadius,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: cardRadius,
                    mouseCursor: SystemMouseCursors.click,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: colorScheme.primary.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: theme.brightness == Brightness.dark
                                      ? 0.52
                                      : 0.78,
                                ),
                              ),
                              boxShadow: theme.brightness == Brightness.dark
                                  ? const <BoxShadow>[]
                                  : AppShadowTokens.card,
                            ),
                            child: CachedArtwork(
                              imageUrl: artist.artworkUrl,
                              size: artworkSize,
                              borderRadius: artworkSize / 2,
                              semanticLabel: '$displayName 头像',
                              placeholderBuilder: (_) =>
                                  _ArtistArtworkPlaceholder(size: artworkSize),
                            ),
                          ),
                          SizedBox(height: desktop ? 12 : (narrow ? 7 : 10)),
                          Text(
                            displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: titleStyle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            MediaDisplayText.artistItemCount(artist),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: subtitleStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtistArtworkPlaceholder extends StatelessWidget {
  const _ArtistArtworkPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHigh,
      ),
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.36,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

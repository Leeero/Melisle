import 'dart:math' as math;

import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final artist = widget.artist;
    final compact = widget.compact;

    return Semantics(
      label: '打开艺术家《${artist.name}》',
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
              ? 1.012
              : 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScaler = MediaQuery.textScalerOf(context);
                final narrow = constraints.maxWidth < 118 || compact;
                final titleStyle = theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: compact ? 13 : null,
                  fontWeight: FontWeight.w500,
                  height: narrow ? 1.22 : 1.28,
                );
                final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: compact ? 12 : null,
                  height: narrow ? 1.18 : 1.25,
                );
                final titleGap = narrow ? 7.0 : 10.0;
                final subtitleGap = narrow ? 1.0 : 2.0;
                final titleLineHeight =
                    textScaler.scale(
                      titleStyle?.fontSize ??
                          theme.textTheme.bodyMedium?.fontSize ??
                          14,
                    ) *
                    (titleStyle?.height ?? 1.22);
                final subtitleLineHeight =
                    textScaler.scale(
                      subtitleStyle?.fontSize ??
                          theme.textTheme.bodySmall?.fontSize ??
                          12,
                    ) *
                    (subtitleStyle?.height ?? 1.18);
                final textHeight =
                    titleLineHeight * 2 +
                    subtitleLineHeight +
                    titleGap +
                    subtitleGap;
                final preferredArtworkSize = constraints.maxWidth * 0.78;
                final maxArtworkSize = constraints.maxHeight.isFinite
                    ? constraints.maxHeight - textHeight
                    : preferredArtworkSize;
                final artworkSize = math.min(
                  compact
                      ? math.min(preferredArtworkSize, 96.0)
                      : preferredArtworkSize,
                  math.max(56.0, maxArtworkSize),
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            constraints.maxWidth * (compact ? 0.16 : 0.11),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _hovered
                              ? [
                                  BoxShadow(
                                    color: theme.musicTeal.withValues(
                                      alpha: theme.brightness == Brightness.dark
                                          ? 0.16
                                          : 0.12,
                                    ),
                                    blurRadius: compact ? 14 : 18,
                                    offset: Offset(0, compact ? 5 : 7),
                                  ),
                                ]
                              : const <BoxShadow>[],
                        ),
                        child: CachedArtwork(
                          imageUrl: artist.artworkUrl,
                          size: artworkSize,
                          borderRadius: artworkSize / 2,
                          semanticLabel: '${artist.name} 头像',
                        ),
                      ),
                    ),
                    SizedBox(height: titleGap),
                    Text(
                      artist.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                    SizedBox(height: subtitleGap),
                    Text(
                      '${artist.trackCount} 首歌曲',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: subtitleStyle,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

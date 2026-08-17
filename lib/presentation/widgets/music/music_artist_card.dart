import 'dart:math' as math;

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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final artist = widget.artist;
    final displayName = MediaDisplayText.artistName(artist.name);
    final compact = widget.compact;

    return Semantics(
      label: '打开艺术家《$displayName》',
      button: true,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: AnimatedScale(
          duration: AppMotion.short,
          curve: AppMotion.enter,
          scale: _pressed
              ? 0.992
              : _hovered
              ? 1.012
              : 1,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScaler = MediaQuery.textScalerOf(context);
                final desktop = AppBreakpoints.usesDesktopToolbar(context);
                final narrow = constraints.maxWidth < 118 || compact;
                final titleStyle = (desktop
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: compact ? 13 : null,
                      fontWeight: desktop ? FontWeight.w600 : FontWeight.w500,
                      height: desktop ? 1.28 : (narrow ? 1.22 : 1.28),
                    );
                final subtitleStyle = (desktop
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodySmall)
                    ?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: desktop ? 0.76 : 0.7,
                      ),
                      fontSize: compact ? 12 : null,
                      height: desktop ? 1.28 : (narrow ? 1.18 : 1.25),
                    );
                final titleGap = desktop ? 14.0 : (narrow ? 7.0 : 10.0);
                final subtitleGap = desktop ? 3.0 : (narrow ? 1.0 : 2.0);
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
                    titleLineHeight * (desktop ? 1 : 2) +
                    subtitleLineHeight +
                    titleGap +
                    subtitleGap;
                final preferredArtworkSize = desktop
                    ? 150.0
                    : constraints.maxWidth * 0.78;
                final maxArtworkSize = constraints.maxHeight.isFinite
                    ? constraints.maxHeight - textHeight
                    : preferredArtworkSize;
                final artworkHorizontalPadding = desktop
                    ? 0.0
                    : constraints.maxWidth * (compact ? 0.16 : 0.11);
                final artworkSize = math.min(
                  desktop
                      ? preferredArtworkSize
                      : compact
                      ? math.min(preferredArtworkSize, 96.0)
                      : math.min(preferredArtworkSize, 100.0),
                  math.max(56.0, maxArtworkSize),
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: artworkHorizontalPadding,
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
                          semanticLabel: '$displayName 头像',
                        ),
                      ),
                    ),
                    SizedBox(height: titleGap),
                    Text(
                      displayName,
                      maxLines: desktop ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                    SizedBox(height: subtitleGap),
                    Text(
                      MediaDisplayText.artistItemCount(artist),
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

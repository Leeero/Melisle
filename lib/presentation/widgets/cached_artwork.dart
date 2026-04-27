import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_state.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CachedArtwork extends StatelessWidget {
  const CachedArtwork({
    super.key,
    required this.imageUrl,
    this.size = 64,
    this.borderRadius = 20,
    this.semanticLabel,
    this.sourceContext,
  });

  final String imageUrl;
  final double size;
  final double borderRadius;
  final String? semanticLabel;
  final ArtworkSourceContext? sourceContext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) =>
          a.customArtworkSourceEnabled != b.customArtworkSourceEnabled ||
          a.customArtworkSourceUrl != b.customArtworkSourceUrl,
      builder: (context, _) {
        final resolution = context.read<CustomMediaSourceResolver>().resolveArtworkSource(
          fallbackUrl: imageUrl,
          context: sourceContext,
          size: size.round(),
        );
        final placeholder = _ArtworkPlaceholder(
          seed: resolution.hasPrimary
              ? resolution.primaryUrl
              : (resolution.fallbackUrl.isEmpty ? imageUrl : resolution.fallbackUrl),
          size: size,
          borderRadius: borderRadius,
        );

        Widget artwork;
        if (!resolution.hasPrimary) {
          artwork = placeholder;
        } else {
          artwork = ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _ArtworkNetworkImage(
              imageUrl: resolution.primaryUrl,
              fallbackUrl: resolution.hasFallback ? resolution.fallbackUrl : null,
              size: size,
              placeholder: placeholder,
            ),
          );
        }

        return Semantics(
          image: true,
          label: semanticLabel ?? '',
          child: artwork,
        );
      },
    );
  }
}

class _ArtworkNetworkImage extends StatelessWidget {
  const _ArtworkNetworkImage({
    required this.imageUrl,
    required this.size,
    required this.placeholder,
    this.fallbackUrl,
  });

  final String imageUrl;
  final String? fallbackUrl;
  final double size;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: const {'User-Agent': AppConstants.httpUserAgent},
      width: size,
      height: size,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 260),
      fadeOutDuration: const Duration(milliseconds: 140),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) {
        final normalizedFallbackUrl = fallbackUrl?.trim();
        if (normalizedFallbackUrl != null &&
            normalizedFallbackUrl.isNotEmpty &&
            normalizedFallbackUrl != imageUrl) {
          return CachedNetworkImage(
            imageUrl: normalizedFallbackUrl,
            httpHeaders: const {'User-Agent': AppConstants.httpUserAgent},
            width: size,
            height: size,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 260),
            fadeOutDuration: const Duration(milliseconds: 140),
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          );
        }
        return placeholder;
      },
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder({
    required this.seed,
    required this.size,
    required this.borderRadius,
  });

  final String seed;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = _placeholderPalette(colorScheme, seed);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: size * 0.56,
              height: size * 0.56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              size: math.max(24, size * 0.34),
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _placeholderPalette(ColorScheme colorScheme, String seed) {
    final hash = seed.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final saturation = 0.34 + ((hash % 11) / 100);
    final lightness = colorScheme.brightness == Brightness.dark ? 0.42 : 0.62;

    final primary = HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
    final secondary = HSLColor.fromAHSL(
      1,
      (hue + 42) % 360,
      saturation * 0.92,
      (lightness + 0.08).clamp(0.0, 1.0),
    ).toColor();

    return [
      Color.alphaBlend(colorScheme.secondary.withValues(alpha: 0.2), primary),
      Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.16), secondary),
    ];
  }
}

import 'dart:ui';

import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_state.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator/palette_generator.dart';

class BlurredCoverBackground extends StatelessWidget {
  const BlurredCoverBackground({
    super.key,
    required this.imageUrl,
    this.sourceContext,
  });

  final String? imageUrl;
  final ArtworkSourceContext? sourceContext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) =>
          a.customArtworkSourceEnabled != b.customArtworkSourceEnabled ||
          a.customArtworkSourceUrl != b.customArtworkSourceUrl,
      builder: (context, _) {
        final fallbackUrl = imageUrl?.trim() ?? '';
        final resolution = context
            .read<CustomMediaSourceResolver>()
            .resolveArtworkSource(
              fallbackUrl: fallbackUrl,
              context: sourceContext,
            );
        return _ResolvedBlurredCoverBackground(
          primaryUrl: resolution.primaryUrl,
          fallbackUrl: resolution.hasFallback ? resolution.fallbackUrl : null,
        );
      },
    );
  }
}

class _ResolvedBlurredCoverBackground extends StatefulWidget {
  const _ResolvedBlurredCoverBackground({
    required this.primaryUrl,
    this.fallbackUrl,
  });

  final String primaryUrl;
  final String? fallbackUrl;

  @override
  State<_ResolvedBlurredCoverBackground> createState() =>
      _ResolvedBlurredCoverBackgroundState();
}

class _ResolvedBlurredCoverBackgroundState
    extends State<_ResolvedBlurredCoverBackground> {
  PaletteGenerator? _palette;
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    _resolvePalette();
  }

  @override
  void didUpdateWidget(covariant _ResolvedBlurredCoverBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryUrl != widget.primaryUrl ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _resolvePalette();
    }
  }

  Future<void> _resolvePalette() async {
    final candidateUrls = <String>{
      widget.primaryUrl.trim(),
      widget.fallbackUrl?.trim() ?? '',
    }.where((url) => url.isNotEmpty).toList();

    if (candidateUrls.isEmpty) {
      if (mounted) {
        setState(() {
          _palette = null;
          _resolvedImageUrl = null;
        });
      }
      return;
    }

    for (final imageUrl in candidateUrls) {
      _resolvedImageUrl = imageUrl;
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          NetworkImage(
            imageUrl,
            headers: const {'User-Agent': AppConstants.httpUserAgent},
          ),
          size: const Size(160, 160),
          maximumColorCount: 12,
        );
        if (!mounted || _resolvedImageUrl != imageUrl) {
          return;
        }
        setState(() {
          _palette = palette;
          _resolvedImageUrl = imageUrl;
        });
        return;
      } catch (_) {
        if (!mounted || _resolvedImageUrl != imageUrl) {
          return;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _palette = null;
      _resolvedImageUrl = candidateUrls.last;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedImageUrl = _resolvedImageUrl;
    final hasImage = resolvedImageUrl != null && resolvedImageUrl.isNotEmpty;
    final palette = _palette;

    final dominant = palette?.dominantColor?.color ?? colorScheme.primary;
    final accent =
        palette?.vibrantColor?.color ??
        palette?.lightMutedColor?.color ??
        colorScheme.secondary;
    final container =
        palette?.darkMutedColor?.color ?? colorScheme.surfaceContainerHighest;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(dominant.withValues(alpha: 0.44), background),
                Color.alphaBlend(accent.withValues(alpha: 0.28), background),
                Color.alphaBlend(container.withValues(alpha: 0.18), background),
                background,
              ],
              stops: const [0.0, 0.36, 0.72, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -140,
          left: -80,
          child: RepaintBoundary(
            child: _GlowOrb(color: dominant.withValues(alpha: 0.32), size: 320),
          ),
        ),
        Positioned(
          right: -120,
          top: 120,
          child: RepaintBoundary(
            child: _GlowOrb(color: accent.withValues(alpha: 0.22), size: 280),
          ),
        ),
        if (hasImage)
          RepaintBoundary(
            child: Opacity(
              opacity: 0.42,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Image.network(
                  resolvedImageUrl,
                  fit: BoxFit.cover,
                  headers: const {'User-Agent': AppConstants.httpUserAgent},
                  cacheWidth: 320,
                  cacheHeight: 320,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                background.withValues(alpha: 0.08),
                background.withValues(alpha: 0.42),
                background.withValues(alpha: 0.82),
                background.withValues(alpha: 0.98),
              ],
              stops: const [0.0, 0.34, 0.72, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: color.a * 0.46),
                Colors.transparent,
              ],
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

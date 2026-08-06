import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class AppPageHeaderCard extends StatelessWidget {
  const AppPageHeaderCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.headerPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadiusTokens.shellContainer),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: child,
    );
  }
}

class AppDetailHeroFrame extends StatelessWidget {
  const AppDetailHeroFrame({
    super.key,
    required this.coverBuilder,
    required this.contentBuilder,
    this.padding = const EdgeInsets.all(22),
    this.spacing = 24,
    this.compactGap = 20,
  });

  final Widget Function(BuildContext context, bool isWide) coverBuilder;
  final Widget Function(BuildContext context, bool isWide) contentBuilder;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double compactGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = AppBreakpoints.usesWideContentWidth(
            constraints.maxWidth,
          );
          final cover = coverBuilder(context, isWide);
          final content = contentBuilder(context, isWide);
          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: cover),
                SizedBox(height: compactGap),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              cover,
              SizedBox(width: spacing),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class ReadingWidthConstraint extends StatelessWidget {
  const ReadingWidthConstraint({
    super.key,
    required this.child,
    this.maxWidth = 680,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

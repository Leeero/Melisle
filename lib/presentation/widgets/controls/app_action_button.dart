import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

enum AppActionButtonTone { primary, secondary, neutral, danger }

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tone = AppActionButtonTone.neutral,
    this.dense = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final AppActionButtonTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: dense ? 18 : 20),
      label: Text(label),
      style: AppActionButtonStyle.text(context, tone: tone, dense: dense),
    );
  }
}

abstract final class AppActionButtonStyle {
  static ButtonStyle text(
    BuildContext context, {
    AppActionButtonTone tone = AppActionButtonTone.neutral,
    bool dense = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPrimary = tone == AppActionButtonTone.primary;
    final isDanger = tone == AppActionButtonTone.danger;
    final foreground = switch (tone) {
      AppActionButtonTone.primary => colorScheme.onPrimary,
      AppActionButtonTone.secondary => colorScheme.secondary,
      AppActionButtonTone.neutral => colorScheme.onSurfaceVariant,
      AppActionButtonTone.danger => colorScheme.error,
    };
    final background = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primary,
      AppActionButtonTone.secondary =>
        colorScheme.secondaryContainer.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.42 : 0.74,
        ),
      AppActionButtonTone.neutral => Colors.transparent,
      AppActionButtonTone.danger => Colors.transparent,
    };
    final borderColor = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primary.withValues(alpha: 0),
      AppActionButtonTone.secondary => colorScheme.secondary.withValues(
        alpha: 0.18,
      ),
      AppActionButtonTone.neutral => colorScheme.outlineVariant.withValues(
        alpha: 0.72,
      ),
      AppActionButtonTone.danger => colorScheme.error.withValues(alpha: 0.20),
    };

    return TextButton.styleFrom(
      foregroundColor: foreground,
      disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.34),
      backgroundColor: background,
      disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 14 : 18,
        vertical: dense ? 10 : 10,
      ),
      minimumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.padded,
      textStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.button),
      ),
      side: BorderSide(color: borderColor),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.06);
        }
        if (isPrimary) {
          if (states.contains(WidgetState.pressed)) {
            return theme.accentHover;
          }
          return colorScheme.primary;
        }
        if (isDanger && states.contains(WidgetState.pressed)) {
          return colorScheme.errorContainer.withValues(alpha: 0.42);
        }
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return tone == AppActionButtonTone.neutral
              ? theme.hoverWash
              : background;
        }
        return background;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (isPrimary) return Colors.transparent;
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          if (tone == AppActionButtonTone.neutral) {
            return theme.hoverWash;
          }
          return foreground.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
    );
  }
}

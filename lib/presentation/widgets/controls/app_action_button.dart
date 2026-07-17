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
    final hoverBackground = switch (tone) {
      AppActionButtonTone.primary => theme.accentHover,
      AppActionButtonTone.secondary => colorScheme.secondaryContainer
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.52 : 0.82),
      AppActionButtonTone.neutral => theme.hoverWash,
      AppActionButtonTone.danger => colorScheme.errorContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.28 : 0.36,
      ),
    };
    final pressedBackground = switch (tone) {
      AppActionButtonTone.primary => theme.accentHover,
      AppActionButtonTone.secondary => colorScheme.secondaryContainer
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.60 : 0.90),
      AppActionButtonTone.neutral => _pressedWash(theme),
      AppActionButtonTone.danger => colorScheme.errorContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.42 : 0.50,
      ),
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
        if (states.contains(WidgetState.pressed)) {
          return pressedBackground;
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return hoverBackground;
        }
        return background;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  static ButtonStyle icon(
    BuildContext context, {
    AppActionButtonTone tone = AppActionButtonTone.neutral,
    bool selected = false,
    double size = 44,
    double iconSize = 20,
    double? radius,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primary,
      AppActionButtonTone.secondary => colorScheme.secondary,
      AppActionButtonTone.neutral => colorScheme.onSurfaceVariant,
      AppActionButtonTone.danger => colorScheme.error,
    };
    final activeForeground = tone == AppActionButtonTone.neutral
        ? colorScheme.primary
        : foreground;
    final selectedBackground = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primaryContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.44 : 0.62,
      ),
      AppActionButtonTone.secondary => colorScheme.secondaryContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.44 : 0.62,
      ),
      AppActionButtonTone.neutral => theme.selectedWash.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.62 : 0.72,
      ),
      AppActionButtonTone.danger => colorScheme.errorContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.36 : 0.48,
      ),
    };
    final pressedBackground = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primaryContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.52 : 0.70,
      ),
      AppActionButtonTone.secondary => colorScheme.secondaryContainer
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.52 : 0.70),
      AppActionButtonTone.neutral => _pressedWash(theme),
      AppActionButtonTone.danger => colorScheme.errorContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.42 : 0.56,
      ),
    };
    final hoverBackground = switch (tone) {
      AppActionButtonTone.danger => colorScheme.errorContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.26 : 0.34,
      ),
      _ => selected ? selectedBackground : theme.hoverWash,
    };
    final interactiveForeground = tone == AppActionButtonTone.neutral
        ? (selected ? activeForeground : colorScheme.onSurface)
        : foreground;

    return IconButton.styleFrom(
      fixedSize: Size.square(size),
      minimumSize: Size.square(size),
      maximumSize: Size.square(size),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.padded,
      iconSize: iconSize,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          radius ?? AppRadiusTokens.iconButton,
        ),
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return Colors.transparent;
        if (states.contains(WidgetState.pressed)) return pressedBackground;
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return hoverBackground;
        }
        return selected ? selectedBackground : Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurfaceVariant.withValues(alpha: 0.40);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return interactiveForeground;
        }
        return selected ? activeForeground : foreground;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      side: WidgetStateProperty.resolveWith((states) {
        final visible =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed);
        return BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: visible ? 0.30 : 0,
          ),
        );
      }),
    );
  }

  static Color _pressedWash(ThemeData theme) {
    return Color.alphaBlend(
      theme.musicTealSoft.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.72 : 0.78,
      ),
      theme.colorScheme.surfaceContainerHighest,
    );
  }
}

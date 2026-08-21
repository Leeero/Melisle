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
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: AppActionButtonStyle.text(context, tone: tone, dense: dense),
    );
  }
}

/// Refined button styles with consistent tokens and polished interactions.
abstract final class AppActionButtonStyle {
  static final WidgetStateProperty<MouseCursor?> _mouseCursor =
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
      );

  /// Link-style button (inline text action).
  static ButtonStyle link(
    BuildContext context, {
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: AppSpacingTokens.inlineGap,
    ),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextButton.styleFrom(
      minimumSize: Size.square(AppSpacingTokens.buttonHeight),
      padding: padding,
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.sm),
      ),
    ).copyWith(
      alignment: Alignment.center,
      mouseCursor: _mouseCursor,
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.34);
        }
        if (states.contains(WidgetState.pressed)) {
          return Color.lerp(colorScheme.primary, colorScheme.onSurface, 0.24);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return theme.accentHover;
        }
        return colorScheme.primary;
      }),
      textStyle: WidgetStatePropertyAll(
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.focused)) return BorderSide.none;
        return BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.58),
          width: AppBorderTokens.focus,
        );
      }),
    );
  }

  /// Text button with optional background tint.
  static ButtonStyle text(
    BuildContext context, {
    AppActionButtonTone tone = AppActionButtonTone.neutral,
    bool dense = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final foreground = switch (tone) {
      AppActionButtonTone.primary => colorScheme.onPrimary,
      AppActionButtonTone.secondary => colorScheme.secondary,
      AppActionButtonTone.neutral => colorScheme.onSurfaceVariant,
      AppActionButtonTone.danger => colorScheme.error,
    };
    final background = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primary,
      AppActionButtonTone.secondary => colorScheme.secondaryContainer.withValues(
        alpha: isDark ? 0.42 : 0.74,
      ),
      AppActionButtonTone.neutral => Colors.transparent,
      AppActionButtonTone.danger => Colors.transparent,
    };
    final pressedBackground = switch (tone) {
      AppActionButtonTone.primary => theme.accentHover,
      AppActionButtonTone.secondary => colorScheme.secondaryContainer
          .withValues(alpha: isDark ? 0.60 : 0.90),
      AppActionButtonTone.neutral => _pressedWash(theme),
      AppActionButtonTone.danger => colorScheme.errorContainer.withValues(
        alpha: isDark ? 0.42 : 0.50,
      ),
    };
    final borderColor = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primary.withValues(alpha: 0),
      AppActionButtonTone.secondary => colorScheme.secondary.withValues(
        alpha: 0.18,
      ),
      AppActionButtonTone.neutral => colorScheme.outlineVariant.withValues(
        alpha: isDark ? 0.46 : 0.72,
      ),
      AppActionButtonTone.danger => colorScheme.error.withValues(alpha: 0.20),
    };

    return TextButton.styleFrom(
      foregroundColor: foreground,
      disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.34),
      backgroundColor: background,
      disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
      padding: EdgeInsets.symmetric(
        horizontal: dense
            ? AppSpacingTokens.buttonPaddingCompactH
            : AppSpacingTokens.buttonPaddingH,
        vertical: AppSpacingTokens.buttonPaddingV,
      ),
      minimumSize: Size(0, dense ? 40 : AppSpacingTokens.buttonHeight),
      tapTargetSize: MaterialTapTargetSize.padded,
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.sm),
      ),
      side: BorderSide(color: borderColor),
    ).copyWith(
      alignment: Alignment.center,
      mouseCursor: _mouseCursor,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.06);
        }
        if (states.contains(WidgetState.pressed)) {
          return pressedBackground;
        }
        return background;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  /// Icon button with refined hover/press states.
  static ButtonStyle icon(
    BuildContext context, {
    AppActionButtonTone tone = AppActionButtonTone.neutral,
    bool selected = false,
    double size = 48, // 44 → 48
    double iconSize = 20,
    double? radius,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
        alpha: isDark ? 0.44 : 0.62,
      ),
      AppActionButtonTone.secondary => colorScheme.secondaryContainer.withValues(
        alpha: isDark ? 0.44 : 0.62,
      ),
      AppActionButtonTone.neutral => theme.selectedWash.withValues(
        alpha: isDark ? 0.62 : 0.72,
      ),
      AppActionButtonTone.danger => colorScheme.errorContainer.withValues(
        alpha: isDark ? 0.36 : 0.48,
      ),
    };

    final pressedBackground = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primaryContainer.withValues(
        alpha: isDark ? 0.52 : 0.70,
      ),
      AppActionButtonTone.secondary => colorScheme.secondaryContainer
          .withValues(alpha: isDark ? 0.52 : 0.70),
      AppActionButtonTone.neutral => _pressedWash(theme),
      AppActionButtonTone.danger => colorScheme.errorContainer.withValues(
        alpha: isDark ? 0.42 : 0.56,
      ),
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
          radius ?? AppRadiusTokens.sm,
        ),
      ),
    ).copyWith(
      mouseCursor: _mouseCursor,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return Colors.transparent;
        if (states.contains(WidgetState.pressed)) return pressedBackground;
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
        final focused = states.contains(WidgetState.focused);
        if (!focused) return BorderSide.none;
        return BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.72),
          width: AppBorderTokens.focus,
        );
      }),
    );
  }

  static Color _pressedWash(ThemeData theme) {
    return Color.alphaBlend(
      theme.colorScheme.primaryContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.72 : 0.78,
      ),
      theme.colorScheme.surfaceContainerHighest,
    );
  }
}

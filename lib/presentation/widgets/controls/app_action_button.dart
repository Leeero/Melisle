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
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = switch (tone) {
      AppActionButtonTone.primary => colorScheme.primary,
      AppActionButtonTone.secondary => colorScheme.secondary,
      AppActionButtonTone.neutral => colorScheme.onSurfaceVariant,
      AppActionButtonTone.danger => colorScheme.error,
    };

    return TextButton.styleFrom(
      foregroundColor: foreground,
      disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.34),
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 14,
        vertical: dense ? 10 : 10,
      ),
      minimumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.padded,
      textStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.iconButton),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: 0.10);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return foreground.withValues(alpha: 0.06);
        }
        return Colors.transparent;
      }),
    );
  }
}

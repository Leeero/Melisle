import 'package:flutter/material.dart';

import 'package:cross_platform_music_player/shared/theme/app_tokens.dart';

@immutable
class AppMobileTheme extends ThemeExtension<AppMobileTheme> {
  const AppMobileTheme({
    required this.scaffold,
    required this.surface,
    required this.surfaceMuted,
    required this.primary,
    required this.primaryPressed,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outlineVariant,
    required this.brass,
  });

  const AppMobileTheme.light()
    : scaffold = AppMobileColorTokens.lightScaffold,
      surface = AppMobileColorTokens.lightSurface,
      surfaceMuted = AppMobileColorTokens.lightSurfaceMuted,
      primary = AppMobileColorTokens.lightPrimary,
      primaryPressed = AppMobileColorTokens.lightPrimaryPressed,
      onSurface = AppMobileColorTokens.lightOnSurface,
      onSurfaceVariant = AppMobileColorTokens.lightOnSurfaceVariant,
      outlineVariant = AppMobileColorTokens.lightOutlineVariant,
      brass = AppMobileColorTokens.lightBrass;

  const AppMobileTheme.dark()
    : scaffold = AppMobileColorTokens.darkScaffold,
      surface = AppMobileColorTokens.darkSurface,
      surfaceMuted = AppMobileColorTokens.darkSurfaceMuted,
      primary = AppMobileColorTokens.darkPrimary,
      primaryPressed = AppMobileColorTokens.darkPrimaryPressed,
      onSurface = AppMobileColorTokens.darkOnSurface,
      onSurfaceVariant = AppMobileColorTokens.darkOnSurfaceVariant,
      outlineVariant = AppMobileColorTokens.darkOutlineVariant,
      brass = AppMobileColorTokens.darkBrass;

  final Color scaffold;
  final Color surface;
  final Color surfaceMuted;
  final Color primary;
  final Color primaryPressed;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outlineVariant;
  final Color brass;

  @override
  AppMobileTheme copyWith({
    Color? scaffold,
    Color? surface,
    Color? surfaceMuted,
    Color? primary,
    Color? primaryPressed,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outlineVariant,
    Color? brass,
  }) {
    return AppMobileTheme(
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      brass: brass ?? this.brass,
    );
  }

  @override
  AppMobileTheme lerp(covariant AppMobileTheme? other, double t) {
    if (other == null) return this;
    return AppMobileTheme(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(
        onSurfaceVariant,
        other.onSurfaceVariant,
        t,
      )!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      brass: Color.lerp(brass, other.brass, t)!,
    );
  }
}

extension AppMobileThemeContext on BuildContext {
  AppMobileTheme get mobileTheme {
    final theme = Theme.of(this);
    return theme.extension<AppMobileTheme>() ??
        (theme.brightness == Brightness.dark
            ? const AppMobileTheme.dark()
            : const AppMobileTheme.light());
  }
}

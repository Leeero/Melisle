import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme color scheme', () {
    test('uses the unified brand palette', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.colorScheme.primary, AppColorTokens.lightPrimary);
      expect(dark.colorScheme.primary, AppColorTokens.darkPrimary);
      expect(light.accentGreen, light.colorScheme.primary);
      expect(dark.accentGreen, dark.colorScheme.primary);
    });

    test('keeps key text combinations WCAG AA compliant', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final scheme = theme.colorScheme;

        expect(
          _contrast(scheme.primary, scheme.onPrimary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.surface, scheme.onSurface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(theme.scaffoldBackgroundColor, theme.muted),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('separates status colors from music ambience colors', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.success, isNot(theme.colorScheme.primary));
        expect(theme.success, isNot(theme.musicTeal));
        expect(theme.warning, isNot(theme.musicWarm));
        expect(theme.colorScheme.error, isNot(theme.musicRose));
      }
    });

    test('defines stable error and surface container roles', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final scheme = theme.colorScheme;

        expect(scheme.errorContainer, isNot(scheme.error));
        expect(scheme.surfaceContainerLow, isNot(scheme.surfaceContainerHigh));
        expect(scheme.surfaceTint, Colors.transparent);
      }
    });
  });
}

double _contrast(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

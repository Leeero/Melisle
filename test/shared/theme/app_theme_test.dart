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
      expect(light.colorScheme.primaryContainer, const Color(0xFF117E6E));
      expect(light.colorScheme.onPrimaryContainer, const Color(0xFFCFFFF3));
      expect(light.colorScheme.onSurface, const Color(0xFF181D1B));
      expect(light.colorScheme.onSurfaceVariant, const Color(0xFF3E4946));
      expect(light.colorScheme.outlineVariant, const Color(0xFFBDC9C5));
      expect(dark.colorScheme.surface, const Color(0xFF141C1E));
      expect(dark.colorScheme.surfaceContainer, const Color(0xFF1B2325));
      expect(dark.colorScheme.outline, const Color(0xFF2B3233));
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

  group('Stitch V3 layout tokens', () {
    test('keeps canonical radius tokens shared by components', () {
      expect(AppRadiusTokens.xs, 4);
      expect(AppRadiusTokens.sm, 8);
      expect(AppRadiusTokens.md, 12);
      expect(AppRadiusTokens.lg, 16);
      expect(AppRadiusTokens.xl, 24);
      expect(AppRadiusTokens.button, 8);
      expect(AppRadiusTokens.miniPlayer, 14);
      expect(AppRadiusTokens.miniPlayerArtwork, 10);
    });

    test('keeps the canonical mobile spacing and MiniPlayer height', () {
      expect(AppSpacingTokens.pageHorizontalCompact, 20);
      expect(AppSpacingTokens.mobilePageX, 20);
      expect(AppSpacingTokens.mobileMiniPlayerHeight, 60);
    });

    test('keeps the V3-46 desktop shell dimensions', () {
      expect(AppSpacingTokens.desktopSidebarWidth, 220);
      expect(AppSpacingTokens.desktopToolbarHeight, 54);
      expect(AppSpacingTokens.desktopMiniPlayerHeight, 72);
    });

    test('keeps V3-46 breakpoint edges stable', () {
      expect(AppBreakpoints.fromWidth(767), AppLayoutSize.compact);
      expect(AppBreakpoints.fromWidth(768), AppLayoutSize.medium);
      expect(AppBreakpoints.fromWidth(1079), AppLayoutSize.medium);
      expect(AppBreakpoints.fromWidth(1080), AppLayoutSize.desktop);
      expect(AppBreakpoints.fromWidth(1439), AppLayoutSize.desktop);
      expect(AppBreakpoints.fromWidth(1440), AppLayoutSize.largeDesktop);
      expect(AppBreakpoints.usesDesktopShellWidth(1079), isFalse);
      expect(AppBreakpoints.usesDesktopShellWidth(1080), isTrue);
    });
  });

  group('Stitch V3 typography and motion tokens', () {
    test('uses fixed V3 type scale with zero letter spacing', () {
      final text = AppTheme.light().textTheme;

      expect(text.headlineMedium?.fontSize, 26);
      expect(text.headlineMedium?.height, 34 / 26);
      expect(text.titleLarge?.fontSize, 18);
      expect(text.titleLarge?.height, 24 / 18);
      expect(text.bodyMedium?.fontSize, 15);
      expect(text.bodyMedium?.height, 22 / 15);
      expect(text.bodySmall?.fontSize, 13);
      expect(text.bodySmall?.height, 18 / 13);
      expect(text.labelSmall?.fontSize, 12);
      expect(text.labelSmall?.height, 16 / 12);
      expect(text.headlineMedium?.letterSpacing, 0);
    });

    test('keeps V3 motion durations', () {
      expect(AppMotion.tap, const Duration(milliseconds: 150));
      expect(AppMotion.hover, const Duration(milliseconds: 200));
      expect(AppMotion.state, const Duration(milliseconds: 300));
      expect(AppMotion.page, const Duration(milliseconds: 320));
      expect(AppMotion.sheet, const Duration(milliseconds: 300));
      expect(AppMotion.overlay, const Duration(milliseconds: 420));
      expect(AppMotion.lyrics, const Duration(milliseconds: 450));
    });
  });

  group('Stitch V3 component themes', () {
    test('covers button hover pressed focus and disabled states', () {
      final light = AppTheme.light();
      final style = light.filledButtonTheme.style!;
      final background = style.backgroundColor!;
      final foreground = style.foregroundColor!;
      final side = style.side!;

      expect(background.resolve({}), AppColorTokens.lightPrimary);
      expect(
        background.resolve({WidgetState.pressed}),
        AppColorTokens.lightPrimaryHover,
      );
      expect(
        foreground.resolve({WidgetState.disabled}),
        light.colorScheme.onSurface.withValues(alpha: 0.34),
      );
      expect(
        side.resolve({WidgetState.focused})?.color,
        light.colorScheme.primary.withValues(alpha: 0.42),
      );
    });

    test('uses shared radii in card button input and bottom sheet themes', () {
      final theme = AppTheme.light();

      expect(
        _radius(theme.cardTheme.shape as RoundedRectangleBorder),
        AppRadiusTokens.card,
      );
      expect(
        _radius(
          theme.filledButtonTheme.style!.shape!.resolve({})!
              as RoundedRectangleBorder,
        ),
        AppRadiusTokens.button,
      );
      expect(
        (theme.inputDecorationTheme.border! as OutlineInputBorder)
            .borderRadius
            .topLeft
            .x,
        AppRadiusTokens.input,
      );
      expect(
        ((theme.bottomSheetTheme.shape! as RoundedRectangleBorder).borderRadius
                as BorderRadius)
            .topLeft
            .x,
        AppRadiusTokens.xl,
      );
    });
  });

  group('Stitch V3 text scaling support', () {
    testWidgets('allows required text scale factors without clamping', (
      tester,
    ) async {
      for (final scale in [1.0, 1.3, 2.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const Scaffold(body: Text('Melisle 乐岛')),
            ),
          ),
        );

        final context = tester.element(find.text('Melisle 乐岛'));
        expect(MediaQuery.textScalerOf(context).scale(15), 15 * scale);
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

double _radius(RoundedRectangleBorder shape) {
  final borderRadius = shape.borderRadius as BorderRadius;
  return borderRadius.topLeft.x;
}

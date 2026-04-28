import 'package:flutter/material.dart';

import 'package:cross_platform_music_player/shared/theme/app_tokens.dart';

/// Design-system tokens for the Melisle (乐岛) visual redesign v2.
///
/// Colour palette, typography (Righteous + Poppins), border-radii, spacing
/// and component themes all live here so they stay in sync with
/// `design-system/melisle/MASTER.md` and `visual-redesign.md`.
abstract final class AppTheme {
  // ──────────────────── Colour Palette ────────────────────

  // — Brand seed
  static const _seedColor = AppColorTokens.seed;

  // — Dark mode surfaces (deep-blue-black)
  static const _darkScaffold = AppColorTokens.darkScaffold;
  static const _darkSurface = AppColorTokens.darkSurface;
  static const _darkSurfaceHigh = AppColorTokens.darkSurfaceHigh;
  static const _darkSurfaceHighest = AppColorTokens.darkSurfaceHighest;

  // — Light mode surfaces
  static const _lightScaffold = AppColorTokens.lightScaffold;
  static const _lightSurface = AppColorTokens.lightSurface;
  static const _lightSurfaceHigh = AppColorTokens.lightSurfaceHigh;
  static const _lightSurfaceHighest = AppColorTokens.lightSurfaceHighest;

  // — Semantic colours (dark)
  static const _darkPrimary = AppColorTokens.darkPrimary;
  static const _darkPrimaryContainer = AppColorTokens.darkPrimaryContainer;
  static const _darkSecondary = AppColorTokens.darkSecondary;
  static const _darkSecondaryContainer = AppColorTokens.darkSecondaryContainer;
  static const _darkOnSurface = AppColorTokens.darkOnSurface;
  static const _darkOnSurfaceVariant = AppColorTokens.darkOnSurfaceVariant;
  static const _darkOutline = AppColorTokens.darkOutline;
  static const _darkOutlineVariant = AppColorTokens.darkOutlineVariant;

  // — Semantic colours (light)
  static const _lightPrimary = AppColorTokens.lightPrimary;
  static const _lightPrimaryContainer = AppColorTokens.lightPrimaryContainer;
  static const _lightSecondary = AppColorTokens.lightSecondary;
  static const _lightSecondaryContainer =
      AppColorTokens.lightSecondaryContainer;
  static const _lightOnSurfaceVariant = AppColorTokens.lightOnSurfaceVariant;
  static const _lightOutline = AppColorTokens.lightOutline;
  static const _lightOutlineVariant = AppColorTokens.lightOutlineVariant;

  // — Shared accents
  static const accent = AppColorTokens.accent;
  static const lyricHighlight = AppColorTokens.lyricHighlight;

  // ──────────────────── Typography ────────────────────

  static const _displayFont = 'Righteous';
  static const _bodyFont = 'Poppins';

  // ──────────────────── Border Radii ────────────────────

  static const double radiusCard = AppRadiusTokens.card;
  static const double radiusButton = AppRadiusTokens.button; // capsule
  static const double radiusInput = AppRadiusTokens.input;
  static const double radiusIconButton = AppRadiusTokens.iconButton;
  static const double radiusCoverGrid = AppRadiusTokens.coverGrid;
  static const double radiusCoverDetail = AppRadiusTokens.coverDetail;

  // ──────────────────── Spacing ────────────────────

  static const double sectionGap = AppSpacingTokens.sectionGap;
  static const double sectionTitleBottomGap =
      AppSpacingTokens.sectionTitleBottomGap;
  static const double cardPadding = AppSpacingTokens.cardPadding;
  static const double headerPadding = AppSpacingTokens.headerPadding;

  // ──────────────────── Public API ────────────────────

  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  // ──────────────────── Internal ────────────────────

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // --- ColorScheme ---
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    final colorScheme = isDark
        ? baseScheme.copyWith(
            primary: _darkPrimary,
            onPrimary: Colors.white,
            primaryContainer: _darkPrimaryContainer,
            onPrimaryContainer: const Color(0xFFE2D8FF),
            secondary: _darkSecondary,
            onSecondary: const Color(0xFF003823),
            secondaryContainer: _darkSecondaryContainer,
            onSecondaryContainer: const Color(0xFF99F6E4),
            surface: _darkSurface,
            surfaceContainer: _darkSurfaceHigh,
            surfaceContainerHigh: _darkSurfaceHigh,
            surfaceContainerHighest: _darkSurfaceHighest,
            onSurface: _darkOnSurface,
            onSurfaceVariant: _darkOnSurfaceVariant,
            outline: _darkOutline,
            outlineVariant: _darkOutlineVariant,
            shadow: Colors.black,
            scrim: Colors.black,
          )
        : baseScheme.copyWith(
            primary: _lightPrimary,
            primaryContainer: _lightPrimaryContainer,
            secondary: _lightSecondary,
            secondaryContainer: _lightSecondaryContainer,
            surface: _lightSurface,
            surfaceContainer: _lightSurfaceHigh,
            surfaceContainerHigh: _lightSurfaceHigh,
            surfaceContainerHighest: _lightSurfaceHighest,
            onSurfaceVariant: _lightOnSurfaceVariant,
            outline: _lightOutline,
            outlineVariant: _lightOutlineVariant,
          );

    // --- TextTheme ---
    final baseTextTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;

    final textTheme = baseTextTheme
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        )
        .copyWith(
          // Display — Righteous for brand personality
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontFamily: _displayFont,
            fontWeight: FontWeight.w400, // Righteous only has Regular
            letterSpacing: -1.5,
          ),
          displayMedium: baseTextTheme.displayMedium?.copyWith(
            fontFamily: _displayFont,
            fontWeight: FontWeight.w400,
            letterSpacing: -1.2,
          ),
          displaySmall: baseTextTheme.displaySmall?.copyWith(
            fontFamily: _displayFont,
            fontWeight: FontWeight.w400,
            letterSpacing: -1.0,
          ),
          // Headlines — Righteous for pages/albums/artists
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontFamily: _displayFont,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.9,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontFamily: _displayFont,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.6,
          ),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.45,
          ),
          // Title — Poppins SemiBold/Bold
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w600,
          ),
          // Body — Poppins Regular
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontFamily: _bodyFont,
            height: 1.4,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontFamily: _bodyFont,
            height: 1.4,
          ),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            fontFamily: _bodyFont,
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
          // Labels — Poppins SemiBold/Medium
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelMedium: baseTextTheme.labelMedium?.copyWith(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: baseTextTheme.labelSmall?.copyWith(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w500,
          ),
        );

    // --- ThemeData ---
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? _darkScaffold : _lightScaffold,
      canvasColor: isDark ? _darkScaffold : _lightScaffold,
      splashFactory: InkRipple.splashFactory,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),

      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.72 : 1),
        thickness: 1,
        space: 1,
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.82)
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
        elevation: isDark ? 0 : 0.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.52 : 0.88,
            ),
          ),
        ),
      ),

      // ─── ListTile ───
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 0,
        minVerticalPadding: 10,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),

      // ─── Chip (MetaPill) ───
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface.withValues(
          alpha: isDark ? 0.46 : 1,
        ),
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.55 : 0.9,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),

      // ─── InputDecoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.72)
            : colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: _inputBorder(
          colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.9),
        ),
        enabledBorder: _inputBorder(
          colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.9),
        ),
        focusedBorder: _inputBorder(
          colorScheme.primary.withValues(alpha: isDark ? 0.78 : 0.95),
          width: 1.25,
        ),
        errorBorder: _inputBorder(colorScheme.error.withValues(alpha: 0.78)),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.25),
      ),

      // ─── FilledButton (Capsule) ───
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),

      // ─── OutlinedButton (Capsule) ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.68 : 1,
            ),
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),

      // ─── TextButton ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusIconButton),
          ),
        ),
      ),

      // ─── IconButton ───
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: isDark
              ? colorScheme.surface.withValues(alpha: 0.26)
              : colorScheme.surface,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.all(10),
          iconSize: 22,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.5 : 0.9,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusIconButton),
          ),
        ),
      ),

      // ─── NavigationBar (mobile) ───
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer.withValues(
          alpha: isDark ? 0.88 : 0.92,
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // ─── NavigationRail (desktop sidebar) ───
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        useIndicator: false,
        groupAlignment: -0.84,
        labelType: NavigationRailLabelType.all,
        minWidth: 96,
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),

      // ─── Slider (progress & volume) ───
      sliderTheme: SliderThemeData(
        trackHeight: 4.5,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.outlineVariant.withValues(
          alpha: isDark ? 0.48 : 0.72,
        ),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),

      // ─── ProgressIndicator ───
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // ─── SnackBar ───
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? colorScheme.onSurface : colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),

      // ─── PageTransitions ───
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusInput),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Extension on [ThemeData] to expose Melisle-specific accent colours
/// that don't map directly to Material 3 [ColorScheme].
extension MelisleThemeX on ThemeData {
  /// Playback-green for CTA buttons and active progress segments.
  Color get accentGreen => AppTheme.accent;

  /// Warm yellow for the current lyric line highlight.
  Color get lyricHighlight => AppTheme.lyricHighlight;
}

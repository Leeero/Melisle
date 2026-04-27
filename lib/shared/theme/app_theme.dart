import 'package:flutter/material.dart';

/// Design-system tokens for the Melisle (乐岛) visual redesign v2.
///
/// Colour palette, typography (Righteous + Poppins), border-radii, spacing
/// and component themes all live here so they stay in sync with
/// `design-system/melisle/MASTER.md` and `visual-redesign.md`.
abstract final class AppTheme {
  // ──────────────────── Colour Palette ────────────────────

  // — Brand seed
  static const _seedColor = Color(0xFF7C4DFF);

  // — Dark mode surfaces (deep-blue-black)
  static const _darkScaffold = Color(0xFF0A0A16);
  static const _darkSurface = Color(0xFF161D2D);
  static const _darkSurfaceHigh = Color(0xFF1B2335);
  static const _darkSurfaceHighest = Color(0xFF232D40);

  // — Light mode surfaces
  static const _lightScaffold = Color(0xFFF5F7FB);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceHigh = Color(0xFFF1F4FA);
  static const _lightSurfaceHighest = Color(0xFFE5EBF5);

  // — Semantic colours (dark)
  static const _darkPrimary = Color(0xFF7C4DFF);
  static const _darkPrimaryContainer = Color(0xFF31175D);
  static const _darkSecondary = Color(0xFF00E5A0);
  static const _darkSecondaryContainer = Color(0xFF0D3D2F);
  static const _darkOnSurface = Color(0xFFE8ECF4);
  static const _darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const _darkOutline = Color(0xFF5A6478);
  static const _darkOutlineVariant = Color(0xFF2A3342);

  // — Semantic colours (light)
  static const _lightPrimary = Color(0xFF5B2EE6);
  static const _lightPrimaryContainer = Color(0xFFE2D8FF);
  static const _lightSecondary = Color(0xFF059669);
  static const _lightSecondaryContainer = Color(0xFFD1FAE5);
  static const _lightOnSurfaceVariant = Color(0xFF5E687C);
  static const _lightOutline = Color(0xFF8A93A7);
  static const _lightOutlineVariant = Color(0xFFD8DFEA);

  // — Shared accents
  static const accent = Color(0xFF22C55E);
  static const lyricHighlight = Color(0xFFFFD43B);

  // ──────────────────── Typography ────────────────────

  static const _displayFont = 'Righteous';
  static const _bodyFont = 'Poppins';

  // ──────────────────── Border Radii ────────────────────

  static const double radiusCard = 20;
  static const double radiusButton = 999; // capsule
  static const double radiusInput = 16;
  static const double radiusIconButton = 18;
  static const double radiusCoverGrid = 16;
  static const double radiusCoverDetail = 24;

  // ──────────────────── Spacing ────────────────────

  static const double sectionGap = 24;
  static const double sectionTitleBottomGap = 16;
  static const double cardPadding = 16;
  static const double headerPadding = 22;

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
            color: colorScheme.outlineVariant
                .withValues(alpha: isDark ? 0.52 : 0.88),
          ),
        ),
      ),

      // ─── ListTile ───
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        backgroundColor:
            colorScheme.surface.withValues(alpha: isDark ? 0.46 : 1),
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
        side: BorderSide(
          color: colorScheme.outlineVariant
              .withValues(alpha: isDark ? 0.55 : 0.9),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),

      // ─── InputDecoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.72)
            : colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
        focusedErrorBorder:
            _inputBorder(colorScheme.error, width: 1.25),
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
            color: colorScheme.outlineVariant
                .withValues(alpha: isDark ? 0.68 : 1),
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
            color: colorScheme.outlineVariant
                .withValues(alpha: isDark ? 0.5 : 0.9),
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
        indicatorColor: colorScheme.primaryContainer
            .withValues(alpha: isDark ? 0.88 : 0.92),
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
        inactiveTrackColor: colorScheme.outlineVariant
            .withValues(alpha: isDark ? 0.48 : 0.72),
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
          color:
              isDark ? colorScheme.onSurface : colorScheme.onInverseSurface,
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

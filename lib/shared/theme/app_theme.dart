import 'package:flutter/material.dart';

import 'package:cross_platform_music_player/shared/theme/app_tokens.dart';

/// Design-system tokens for the Melisle (乐岛) visual redesign v2.
///
/// Colour palette, typography, border-radii, spacing and component themes live
/// here so the product UI keeps one coherent visual language.
abstract final class AppTheme {
  // ──────────────────── Colour Palette ────────────────────

  // — Brand seed
  static const _seedColor = AppColorTokens.seed;

  // — Dark mode surfaces (deep-blue-black)
  static const _darkScaffold = AppColorTokens.darkScaffold;
  static const _darkSurface = AppColorTokens.darkSurface;
  static const _darkSurfaceHigh = AppColorTokens.darkSurfaceHigh;
  static const _darkSurfaceHighest = AppColorTokens.darkSurfaceHighest;
  static const _darkSurfaceSidebar = AppColorTokens.darkSurfaceSidebar;

  // — Light mode surfaces
  static const _lightScaffold = AppColorTokens.lightScaffold;
  static const _lightSurface = AppColorTokens.lightSurface;
  static const _lightSurfaceHigh = AppColorTokens.lightSurfaceHigh;
  static const _lightSurfaceHighest = AppColorTokens.lightSurfaceHighest;
  static const _lightSurfaceSidebar = AppColorTokens.lightSurfaceSidebar;

  // — Semantic colours (dark)
  static const _darkPrimary = AppColorTokens.darkPrimary;
  static const _darkPrimaryContainer = AppColorTokens.darkPrimaryContainer;
  static const _darkSecondary = AppColorTokens.darkSecondary;
  static const _darkSecondaryContainer = AppColorTokens.darkSecondaryContainer;
  static const _darkOnSurface = AppColorTokens.darkOnSurface;
  static const _darkOnSurfaceVariant = AppColorTokens.darkOnSurfaceVariant;
  static const _darkMuted = AppColorTokens.darkMuted;
  static const _darkOutline = AppColorTokens.darkOutline;
  static const _darkOutlineVariant = AppColorTokens.darkOutlineVariant;

  // — Semantic colours (light)
  static const _lightPrimary = AppColorTokens.lightPrimary;
  static const _lightPrimaryContainer = AppColorTokens.lightPrimaryContainer;
  static const _lightSecondary = AppColorTokens.lightSecondary;
  static const _lightSecondaryContainer =
      AppColorTokens.lightSecondaryContainer;
  static const _lightOnSurface = AppColorTokens.lightOnSurface;
  static const _lightOnSurfaceVariant = AppColorTokens.lightOnSurfaceVariant;
  static const _lightMuted = AppColorTokens.lightMuted;
  static const _lightOutline = AppColorTokens.lightOutline;
  static const _lightOutlineVariant = AppColorTokens.lightOutlineVariant;

  // — Shared accents
  static const accent = AppColorTokens.accent;
  static const darkLyricHighlight = AppColorTokens.darkLyricHighlight;
  static const lightLyricHighlight = AppColorTokens.lightLyricHighlight;

  // ──────────────────── Typography ────────────────────

  static const String? _productFont = null;
  static const _brandFont = 'Righteous';

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
            onPrimary: _darkScaffold,
            primaryContainer: _darkPrimaryContainer,
            onPrimaryContainer: _darkOnSurface,
            secondary: _darkSecondary,
            onSecondary: _darkScaffold,
            secondaryContainer: _darkSecondaryContainer,
            onSecondaryContainer: _darkOnSurface,
            error: AppColorTokens.darkDanger,
            onError: _darkScaffold,
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
            onPrimary: const Color(0xFFF9FAFF),
            primaryContainer: _lightPrimaryContainer,
            onPrimaryContainer: _lightOnSurface,
            secondary: _lightSecondary,
            onSecondary: const Color(0xFFF8FCFC),
            secondaryContainer: _lightSecondaryContainer,
            onSecondaryContainer: _lightOnSurface,
            error: AppColorTokens.lightDanger,
            onError: const Color(0xFFFFFAF8),
            surface: _lightSurface,
            surfaceContainer: _lightSurfaceHigh,
            surfaceContainerHigh: _lightSurfaceHigh,
            surfaceContainerHighest: _lightSurfaceHighest,
            onSurface: _lightOnSurface,
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
          // Display is reserved for brand-led moments such as the player page.
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontFamily: _brandFont,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          displayMedium: baseTextTheme.displayMedium?.copyWith(
            fontFamily: _brandFont,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          displaySmall: baseTextTheme.displaySmall?.copyWith(
            fontFamily: _brandFont,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          // Product pages use the platform font for Chinese readability.
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontFamily: _productFont,
            height: 1.4,
            letterSpacing: 0,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontFamily: _productFont,
            height: 1.4,
            letterSpacing: 0,
          ),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            fontFamily: _productFont,
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
            letterSpacing: 0,
          ),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          labelMedium: baseTextTheme.labelMedium?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          labelSmall: baseTextTheme.labelSmall?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
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
            ? colorScheme.surface.withValues(alpha: 0.78)
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0 : 0.05),
        elevation: isDark ? 0 : 0.35,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.46 : 0.82,
            ),
          ),
        ),
      ),

      // ─── ListTile ───
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        minLeadingWidth: 0,
        minVerticalPadding: 8,
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
          alpha: isDark ? 0.42 : 0.92,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),

      // ─── InputDecoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.58)
            : colorScheme.surfaceContainer.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: _inputBorder(
          colorScheme.outlineVariant.withValues(alpha: isDark ? 0.42 : 0.82),
        ),
        enabledBorder: _inputBorder(
          colorScheme.outlineVariant.withValues(alpha: isDark ? 0.42 : 0.82),
        ),
        focusedBorder: _inputBorder(
          colorScheme.primary.withValues(alpha: isDark ? 0.68 : 0.86),
          width: 1.25,
        ),
        errorBorder: _inputBorder(colorScheme.error.withValues(alpha: 0.78)),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.25),
      ),

      // ─── Buttons ───
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(colorScheme, textTheme, isDark),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(colorScheme, textTheme, isDark),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(colorScheme, textTheme, isDark),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _iconButtonStyle(colorScheme, isDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _tonalButtonStyle(colorScheme, textTheme, isDark),
      ),

      // ─── Checkbox / Switch / Radio ───
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: colorScheme.outline),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurfaceVariant.withValues(alpha: 0.34);
          }
          if (states.contains(WidgetState.selected)) {
            return isDark ? _darkOnSurface : _lightSurface;
          }
          return colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.outlineVariant.withValues(alpha: 0.28);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.50 : 0.78,
          );
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.36 : 0.64,
          );
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // ─── Legacy MaterialButton defaults ───
      buttonTheme: ButtonThemeData(
        minWidth: 44,
        height: 44,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
      ),

      // ─── FloatingActionButton ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 1,
        highlightElevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ─── Tooltip ───
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        showDuration: const Duration(milliseconds: 1800),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: isDark ? colorScheme.onSurface : colorScheme.onInverseSurface,
        ),
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.48 : 0.78,
            ),
          ),
        ),
      ),

      // ─── BottomSheet ───
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surface,
        modalBarrierColor: colorScheme.scrim.withValues(alpha: 0.46),
        dragHandleColor: colorScheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),

      // ─── Menu / Popup ───
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.48 : 0.78,
            ),
          ),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      // ─── IconButton ───
      // Defined above with explicit overlay states.

      // ─── NavigationBar (mobile) ───
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer.withValues(
          alpha: isDark ? 0.76 : 0.82,
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
            size: 23,
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
        minWidth: 92,
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
          size: 23,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 23,
        ),
      ),

      // ─── Slider (progress & volume) ───
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.outlineVariant.withValues(
          alpha: isDark ? 0.48 : 0.72,
        ),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  static ButtonStyle _filledButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      elevation: 0,
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton),
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.pressed)) {
          return _buttonAccentHover(isDark);
        }
        return colorScheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.34);
        }
        return colorScheme.onPrimary;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colorScheme.onPrimary.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.72 : 0.42),
          );
        }
        return BorderSide.none;
      }),
    );
  }

  static ButtonStyle _outlinedButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      foregroundColor: colorScheme.onSurface,
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton),
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return _buttonPressedWash(colorScheme, isDark);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return _buttonHoverWash(colorScheme, isDark);
        }
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final alpha = states.contains(WidgetState.disabled)
            ? 0.32
            : states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)
            ? (isDark ? 0.86 : 1.0)
            : (isDark ? 0.56 : 0.78);
        return BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: alpha),
        );
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  static ButtonStyle _textButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return TextButton.styleFrom(
      foregroundColor: colorScheme.onSurfaceVariant,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.padded,
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton),
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return _buttonPressedWash(colorScheme, isDark);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return _buttonHoverWash(colorScheme, isDark);
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.34);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return colorScheme.onSurface;
        }
        return colorScheme.onSurfaceVariant;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  static ButtonStyle _iconButtonStyle(ColorScheme colorScheme, bool isDark) {
    return IconButton.styleFrom(
      foregroundColor: colorScheme.onSurfaceVariant,
      backgroundColor: Colors.transparent,
      minimumSize: const Size.square(44),
      fixedSize: const Size.square(44),
      padding: EdgeInsets.zero,
      iconSize: 22,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusIconButton),
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return _buttonPressedWash(colorScheme, isDark);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return _buttonHoverWash(colorScheme, isDark);
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurfaceVariant.withValues(alpha: 0.40);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return colorScheme.onSurface;
        }
        return colorScheme.onSurfaceVariant;
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

  static ButtonStyle _tonalButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton),
      ),
    ).copyWith(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.06);
        }
        if (states.contains(WidgetState.pressed)) {
          return Color.alphaBlend(
            colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            colorScheme.surfaceContainerHighest,
          );
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return _buttonHoverWash(colorScheme, isDark);
        }
        return colorScheme.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.74 : 0.86,
        );
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.34);
        }
        return colorScheme.onSurface;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      side: WidgetStateProperty.resolveWith((states) {
        final visible =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed);
        return BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: visible ? (isDark ? 0.52 : 0.72) : 0,
          ),
        );
      }),
    );
  }

  static Color _buttonHoverWash(ColorScheme colorScheme, bool isDark) {
    final tint = isDark
        ? AppColorTokens.darkMusicTealSoft
        : AppColorTokens.lightMusicTealSoft;
    return Color.alphaBlend(
      tint.withValues(alpha: isDark ? 0.50 : 0.58),
      colorScheme.surface,
    );
  }

  static Color _buttonPressedWash(ColorScheme colorScheme, bool isDark) {
    final tint = isDark
        ? AppColorTokens.darkMusicTealSoft
        : AppColorTokens.lightMusicTealSoft;
    return Color.alphaBlend(
      tint.withValues(alpha: isDark ? 0.70 : 0.76),
      colorScheme.surfaceContainerHighest,
    );
  }

  static Color _buttonAccentHover(bool isDark) {
    return isDark
        ? AppColorTokens.darkPrimaryHover
        : AppColorTokens.lightPrimaryHover;
  }
}

/// Extension on [ThemeData] to expose Melisle-specific accent colours
/// that don't map directly to Material 3 [ColorScheme].
extension MelisleThemeX on ThemeData {
  /// Playback-green for CTA buttons and active progress segments.
  Color get accentGreen => AppTheme.accent;

  /// Lyric highlight tuned for Melisle's deep-blue / purple palette.
  Color get lyricHighlight => brightness == Brightness.dark
      ? AppTheme.darkLyricHighlight
      : AppTheme.lightLyricHighlight;

  Color get surfaceSidebar => brightness == Brightness.dark
      ? AppTheme._darkSurfaceSidebar
      : AppTheme._lightSurfaceSidebar;

  Color get muted => brightness == Brightness.dark
      ? AppTheme._darkMuted
      : AppTheme._lightMuted;

  Color get accentHover => brightness == Brightness.dark
      ? AppColorTokens.darkPrimaryHover
      : AppColorTokens.lightPrimaryHover;

  Color get musicWarm => brightness == Brightness.dark
      ? AppColorTokens.darkMusicWarm
      : AppColorTokens.lightMusicWarm;

  Color get musicWarmSoft => brightness == Brightness.dark
      ? AppColorTokens.darkMusicWarmSoft
      : AppColorTokens.lightMusicWarmSoft;

  Color get musicRose => brightness == Brightness.dark
      ? AppColorTokens.darkMusicRose
      : AppColorTokens.lightMusicRose;

  Color get musicRoseSoft => brightness == Brightness.dark
      ? AppColorTokens.darkMusicRoseSoft
      : AppColorTokens.lightMusicRoseSoft;

  Color get musicTeal => brightness == Brightness.dark
      ? AppColorTokens.darkMusicTeal
      : AppColorTokens.lightMusicTeal;

  Color get musicTealSoft => brightness == Brightness.dark
      ? AppColorTokens.darkMusicTealSoft
      : AppColorTokens.lightMusicTealSoft;

  Color get musicInk => brightness == Brightness.dark
      ? AppColorTokens.darkMusicInk
      : AppColorTokens.lightMusicInk;

  Color get hoverWash => Color.alphaBlend(
    musicTealSoft.withValues(
      alpha: brightness == Brightness.dark ? 0.46 : 0.54,
    ),
    colorScheme.surface,
  );

  Color get selectedWash => Color.alphaBlend(
    musicWarmSoft.withValues(
      alpha: brightness == Brightness.dark ? 0.60 : 0.64,
    ),
    colorScheme.surface,
  );
}

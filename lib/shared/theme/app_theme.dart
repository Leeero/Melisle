import 'package:flutter/material.dart';

import 'package:cross_platform_music_player/shared/theme/app_mobile_theme.dart';
import 'package:cross_platform_music_player/shared/theme/app_tokens.dart';

/// Design-system theme for the Melisle (乐岛) Tidal Blue V4 design.
///
/// Colour palette, typography, border-radii, spacing and component themes live
/// here so the product UI keeps one coherent visual language.
abstract final class AppTheme {
  static final WidgetStateProperty<MouseCursor?> _buttonMouseCursor =
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
      );

  // ──────────────────── Colour Palette ────────────────────

  // — Brand seed
  static const _seedColor = AppColorTokens.seed;

  // — Dark mode surfaces (deeper, more refined)
  static const _darkScaffold = AppColorTokens.darkScaffold;
  static const _darkSurface = AppColorTokens.darkSurface;
  static const _darkSurfaceElevated = AppColorTokens.darkSurfaceElevated;
  static const _darkSurfaceHigh = AppColorTokens.darkSurfaceHigh;
  static const _darkSurfaceHighest = AppColorTokens.darkSurfaceHighest;
  static const _darkSurfaceOverlay = AppColorTokens.darkSurfaceOverlay;
  static const _darkSurfaceSidebar = AppColorTokens.darkSurfaceSidebar;

  // — Light mode surfaces
  static const _lightScaffold = AppColorTokens.lightScaffold;
  static const _lightSurface = AppColorTokens.lightSurface;
  static const _lightSurfaceLow = AppColorTokens.lightSurfaceLow;
  static const _lightSurfaceMid = AppColorTokens.lightSurfaceMid;
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
  static const _lightOnPrimaryContainer =
      AppColorTokens.lightOnPrimaryContainer;
  static const _lightSecondary = AppColorTokens.lightSecondary;
  static const _lightSecondaryContainer =
      AppColorTokens.lightSecondaryContainer;
  static const _lightOnSurface = AppColorTokens.lightOnSurface;
  static const _lightOnSurfaceVariant = AppColorTokens.lightOnSurfaceVariant;
  static const _lightMuted = AppColorTokens.lightMuted;
  static const _lightOutline = AppColorTokens.lightOutline;
  static const _lightOutlineVariant = AppColorTokens.lightOutlineVariant;

  // — Shared accents
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
      seedColor: isDark ? _darkPrimary : _seedColor,
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
            errorContainer: const Color(0xFF48241F),
            onErrorContainer: const Color(0xFFFFDAD9),
            surface: _darkSurface,
            surfaceDim: _darkScaffold,
            surfaceBright: _darkSurfaceHighest,
            surfaceContainerLowest: _darkScaffold,
            surfaceContainerLow: _darkSurfaceElevated,
            surfaceContainer: _darkSurfaceHigh,
            surfaceContainerHigh: _darkSurfaceHighest,
            surfaceContainerHighest: _darkSurfaceOverlay,
            onSurface: _darkOnSurface,
            onSurfaceVariant: _darkOnSurfaceVariant,
            outline: _darkOutline,
            outlineVariant: _darkOutlineVariant,
            shadow: Colors.black,
            scrim: Colors.black,
            inverseSurface: _darkOnSurface,
            onInverseSurface: _darkScaffold,
            inversePrimary: _lightPrimary,
            surfaceTint: Colors.transparent,
          )
        : baseScheme.copyWith(
            primary: _lightPrimary,
            onPrimary: Colors.white,
            primaryContainer: _lightPrimaryContainer,
            onPrimaryContainer: _lightOnPrimaryContainer,
            secondary: _lightSecondary,
            onSecondary: Colors.white,
            secondaryContainer: _lightSecondaryContainer,
            onSecondaryContainer: _lightOnSurface,
            error: AppColorTokens.lightDanger,
            onError: Colors.white,
            errorContainer: const Color(0xFFFFE7E2),
            onErrorContainer: const Color(0xFF501E18),
            surface: _lightSurface,
            surfaceDim: _lightSurfaceLow,
            surfaceBright: _lightSurface,
            surfaceContainerLowest: _lightSurface,
            surfaceContainerLow: _lightSurfaceLow,
            surfaceContainer: _lightSurfaceMid,
            surfaceContainerHigh: _lightSurfaceHigh,
            surfaceContainerHighest: _lightSurfaceHighest,
            onSurface: _lightOnSurface,
            onSurfaceVariant: _lightOnSurfaceVariant,
            outline: _lightOutline,
            outlineVariant: _lightOutlineVariant,
            inverseSurface: const Color(0xFF1C2A31),
            onInverseSurface: const Color(0xFFF1F6F6),
            inversePrimary: _darkPrimary,
            surfaceTint: Colors.transparent,
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
          // Refined: larger sizes, more breathing room
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w700,
            fontSize: 34, // 31 → 34
            height: 1.2,
            letterSpacing: -0.5,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            fontSize: 28, // 26 → 28
            height: 1.25,
            letterSpacing: -0.3,
          ),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            fontSize: 24,
            height: 1.3,
            letterSpacing: 0,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            fontSize: 20, // 18 → 20
            height: 1.3,
            letterSpacing: 0,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.4,
            letterSpacing: 0,
          ),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.4,
            letterSpacing: 0,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontFamily: _productFont,
            fontSize: 16,
            height: 1.5, // 1.4 → 1.5
            letterSpacing: 0,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontFamily: _productFont,
            fontSize: 15,
            height: 1.5, // 1.4 → 1.5
            letterSpacing: 0,
          ),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            fontFamily: _productFont,
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            height: 1.4,
            letterSpacing: 0,
          ),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.4,
            letterSpacing: 0,
          ),
          labelMedium: baseTextTheme.labelMedium?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            height: 1.4,
            letterSpacing: 0,
          ),
          labelSmall: baseTextTheme.labelSmall?.copyWith(
            fontFamily: _productFont,
            fontWeight: FontWeight.w500,
            fontSize: 11, // 12 → 11
            height: 1.3,
            letterSpacing: 0.5,
          ),
        );

    // --- ThemeData ---
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? const AppMobileTheme.dark() : const AppMobileTheme.light(),
      ],
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
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark ? Colors.transparent : AppShadowTokens.sm.color,
        elevation: isDark ? 0 : AppShadowTokens.sm.blurRadius / 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: isDark
              ? const BorderSide(color: AppShadowTokens.darkBorder)
              : BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
        ),
      ),

      // ─── ListTile ───
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          horizontal: AppSpacingTokens.inputPadding,
          vertical: AppSpacingTokens.formFieldVerticalPadding,
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
          width: AppBorderTokens.focus,
        ),
        errorBorder: _inputBorder(colorScheme.error.withValues(alpha: 0.78)),
        focusedErrorBorder: _inputBorder(
          colorScheme.error,
          width: AppBorderTokens.focus,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadiusTokens.xl),
          ),
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
      minimumSize: Size(0, AppSpacingTokens.buttonHeight),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.buttonPaddingH,
        vertical: AppSpacingTokens.buttonPaddingV,
      ),
      elevation: 0,
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton),
      ),
    ).copyWith(
      mouseCursor: _buttonMouseCursor,
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
        if (states.contains(WidgetState.focused)) {
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
      minimumSize: Size(0, AppSpacingTokens.buttonHeight),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.buttonPaddingH,
        vertical: AppSpacingTokens.buttonPaddingV,
      ),
      foregroundColor: colorScheme.onSurface,
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton),
      ),
    ).copyWith(
      mouseCursor: _buttonMouseCursor,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return _buttonPressedWash(colorScheme, isDark);
        }
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final alpha = states.contains(WidgetState.disabled)
            ? 0.32
            : states.contains(WidgetState.focused) ||
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
      mouseCursor: _buttonMouseCursor,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return _buttonPressedWash(colorScheme, isDark);
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
      mouseCursor: _buttonMouseCursor,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return _buttonPressedWash(colorScheme, isDark);
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
        final focused = states.contains(WidgetState.focused);
        if (!focused) return BorderSide.none;
        return BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.72),
          width: 1.5,
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
      mouseCursor: _buttonMouseCursor,
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
        final visible = states.contains(WidgetState.focused);
        return BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: visible ? (isDark ? 0.52 : 0.72) : 0,
          ),
        );
      }),
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
  /// Brand accent for CTA buttons and active progress segments.
  Color get accentGreen => colorScheme.primary;

  /// Lyric highlight follows the playback accent in the night-sailing palette.
  Color get lyricHighlight => brightness == Brightness.dark
      ? AppTheme.darkLyricHighlight
      : AppTheme.lightLyricHighlight;

  /// Secondary lyric text stays legible without competing with the active line.
  Color get lyricInactive => brightness == Brightness.dark
      ? AppColorTokens.darkLyricInactive
      : AppColorTokens.lightLyricInactive;

  Color get surfaceSidebar => brightness == Brightness.dark
      ? AppTheme._darkSurfaceSidebar
      : AppTheme._lightSurfaceSidebar;

  Color get muted => brightness == Brightness.dark
      ? AppTheme._darkMuted
      : AppTheme._lightMuted;

  Color get success => brightness == Brightness.dark
      ? AppColorTokens.darkSuccess
      : AppColorTokens.lightSuccess;

  Color get warning => brightness == Brightness.dark
      ? AppColorTokens.darkWarn
      : AppColorTokens.lightWarn;

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
    colorScheme.primaryContainer.withValues(
      alpha: brightness == Brightness.dark ? 0.46 : 0.54,
    ),
    colorScheme.surface,
  );

  Color get selectedWash => Color.alphaBlend(
    colorScheme.primaryContainer.withValues(
      alpha: brightness == Brightness.dark ? 0.60 : 0.64,
    ),
    colorScheme.surface,
  );

  /// 内容区背景渐变的左上角色调。
  Color get ambientGradientStart => brightness == Brightness.dark
      ? AppColorTokens.darkAmbientGradientStart
      : AppColorTokens.lightAmbientGradientStart;

  // ──── Overlay & Scrim ────

  /// 封面/图片上深色渐变遮罩（轻量，12% 黑）。
  Color get overlayDark => AppColorTokens.overlayDark;

  /// 封面/图片上深色渐变遮罩（中等，16% 黑）。
  Color get overlayDarkMedium => AppColorTokens.overlayDarkMedium;

  /// 封面/图片上深色渐变遮罩（重度，65% 黑），用于重叠文字。
  Color get overlayDarkHeavy => AppColorTokens.overlayDarkHeavy;

  /// 深色背景上的白色前景图标（12% 白）。
  Color get onDarkSubtle => AppColorTokens.onDarkOverlaySubtle;

  /// 深色背景上的白色前景文字（88% 白）。
  Color get onDarkStrong => AppColorTokens.onDarkOverlayStrong;

  /// 深色背景上的次要白色文字（70% 白）。
  Color get onDarkMuted => AppColorTokens.onDarkOverlayMuted;

  // ──── Semantic State ────

  /// 收藏/喜欢心形图标颜色。
  Color get favoriteColor => brightness == Brightness.dark
      ? AppColorTokens.darkFavorite
      : AppColorTokens.lightFavorite;

  /// 失败态 artwork 去饱和灰色。
  Color get desaturated => AppColorTokens.desaturatedGrey;

  // ──── Shadow ────

  /// 卡片/浮层阴影基准色（浅色 3% 黑，深色 0%）。
  Color get shadowBase => brightness == Brightness.dark
      ? Colors.transparent
      : Colors.black.withValues(alpha: 0.03);
}

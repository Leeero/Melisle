import 'package:flutter/material.dart';

abstract final class AppColorTokens {
  static const seed = Color(0xFF9CA6FF);

  static const darkScaffold = Color(0xFF090C12);
  static const darkSurface = Color(0xFF121723);
  static const darkSurfaceHigh = Color(0xFF171E2B);
  static const darkSurfaceHighest = Color(0xFF212A3B);

  static const lightScaffold = Color(0xFFF6F8FC);
  static const lightSurface = Color(0xFFFBFCFF);
  static const lightSurfaceHigh = Color(0xFFF0F3F9);
  static const lightSurfaceHighest = Color(0xFFE4EAF3);

  static const darkPrimary = Color(0xFF9CA6FF);
  static const darkPrimaryContainer = Color(0xFF2B3150);
  static const darkSecondary = Color(0xFF86D3D0);
  static const darkSecondaryContainer = Color(0xFF1D333C);
  static const darkOnSurface = Color(0xFFE8ECF4);
  static const darkOnSurfaceVariant = Color(0xFFACB6C7);
  static const darkOutline = Color(0xFF5A6478);
  static const darkOutlineVariant = Color(0xFF2A3342);

  static const lightPrimary = Color(0xFF6172E3);
  static const lightPrimaryContainer = Color(0xFFE0E4FF);
  static const lightSecondary = Color(0xFF4BA9A4);
  static const lightSecondaryContainer = Color(0xFFD4F3F0);
  static const lightOnSurfaceVariant = Color(0xFF5E687C);
  static const lightOutline = Color(0xFF8A93A7);
  static const lightOutlineVariant = Color(0xFFD8DFEA);

  static const accent = Color(0xFF4BA9A4);
  static const darkLyricHighlight = Color(0xFFECA35B);
  static const lightLyricHighlight = Color(0xFFECA35B);
}

abstract final class AppRadiusTokens {
  static const double shellContainer = 22;
  static const double card = 14;
  static const double button = 999;
  static const double input = 14;
  static const double iconButton = 12;
  static const double coverGrid = 14;
  static const double coverDetail = 22;
}

abstract final class AppSpacingTokens {
  static const double pageTop = 20;
  static const double pageTopCompact = 12;
  static const double headerBottomGap = 14;
  static const double contentBottom = 24;
  static const double compactFieldBottomGap = 12;
  static const double sectionGap = 24;
  static const double sectionTitleBottomGap = 16;
  static const double cardPadding = 16;
  static const double headerPadding = 22;

  static const double pageHorizontalCompact = 16;
  static const double pageHorizontalMedium = 24;
  static const double pageHorizontalExpanded = 24;

  static const double shellOuterPadding = 14;
  static const double shellGap = 14;
  static const double shellBottomInset = 10;
  static const double macOsTrafficLightInset = 28;
  static const double desktopSidebarWidth = 80;

  static const double playerHorizontalPadding = 28;
  static const double playerControlGap = 14;
  static const double playerToolbarGap = 10;
  static const double desktopSidebarTopGap = 12;
  static const double desktopSidebarBottomGap = 18;

  static const double miniPlayerOuterHorizontal = 12;
  static const double miniPlayerOuterTop = 8;
  static const double miniPlayerOuterBottomCompact = 8;
  static const double miniPlayerOuterBottomWide = 12;
  static const double miniPlayerInnerHorizontal = 14;
  static const double miniPlayerInnerVerticalCompact = 10;
  static const double miniPlayerInnerVerticalWide = 12;
  static const double miniPlayerControlGap = 8;
  static const double miniPlayerSectionGap = 10;
}

abstract final class AppBorderTokens {
  static const double thin = 1;
  static const double focus = 1.25;
}

import 'package:flutter/material.dart';

abstract final class AppColorTokens {
  static const seed = Color(0xFF7C4DFF);

  static const darkScaffold = Color(0xFF0A0A16);
  static const darkSurface = Color(0xFF161D2D);
  static const darkSurfaceHigh = Color(0xFF1B2335);
  static const darkSurfaceHighest = Color(0xFF232D40);

  static const lightScaffold = Color(0xFFF5F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFF1F4FA);
  static const lightSurfaceHighest = Color(0xFFE5EBF5);

  static const darkPrimary = Color(0xFF7C4DFF);
  static const darkPrimaryContainer = Color(0xFF31175D);
  static const darkSecondary = Color(0xFF00E5A0);
  static const darkSecondaryContainer = Color(0xFF0D3D2F);
  static const darkOnSurface = Color(0xFFE8ECF4);
  static const darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const darkOutline = Color(0xFF5A6478);
  static const darkOutlineVariant = Color(0xFF2A3342);

  static const lightPrimary = Color(0xFF5B2EE6);
  static const lightPrimaryContainer = Color(0xFFE2D8FF);
  static const lightSecondary = Color(0xFF059669);
  static const lightSecondaryContainer = Color(0xFFD1FAE5);
  static const lightOnSurfaceVariant = Color(0xFF5E687C);
  static const lightOutline = Color(0xFF8A93A7);
  static const lightOutlineVariant = Color(0xFFD8DFEA);

  static const accent = Color(0xFF22C55E);
  static const lyricHighlight = Color(0xFFFFD43B);
}

abstract final class AppRadiusTokens {
  static const double shellContainer = 24;
  static const double card = 20;
  static const double button = 999;
  static const double input = 16;
  static const double iconButton = 18;
  static const double coverGrid = 16;
  static const double coverDetail = 24;
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

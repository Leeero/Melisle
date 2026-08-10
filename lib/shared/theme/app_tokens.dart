import 'package:flutter/material.dart';

abstract final class AppColorTokens {
  static const seed = Color(0xFF117E6E);

  // Keep these values aligned with the Stitch V3 design system.
  static const darkScaffold = Color(0xFF0C1315);
  static const darkSurface = Color(0xFF141C1E);
  static const darkSurfaceHigh = Color(0xFF1B2325);
  static const darkSurfaceHighest = Color(0xFF202B2E);
  static const darkSurfaceSidebar = Color(0xFF101719);

  static const lightScaffold = Color(0xFFF7FCFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFFAFEFE);
  static const lightSurfaceHighest = Color(0xFFF1F9F8);
  static const lightSurfaceSidebar = Color(0xFFF1F9F8);
  static const onArtworkScrim = Color(0xFFF6F8FC);

  static const darkPrimary = Color(0xFF46B49E);
  static const darkPrimaryHover = Color(0xFF5CC5AF);
  static const darkPrimaryContainer = Color(0xFF062D26);
  static const darkSecondary = Color(0xFF5FB7A5);
  static const darkSecondaryContainer = Color(0xFF122C26);
  static const darkOnSurface = Color(0xFFE3E9E9);
  static const darkOnSurfaceVariant = Color(0xFF96A1A1);
  static const darkMuted = Color(0xFF7D898A);
  static const darkOutline = Color(0xFF2B3233);
  static const darkOutlineVariant = Color(0xFF222829);

  static const lightPrimary = Color(0xFF117E6E);
  static const lightPrimaryHover = Color(0xFF0B695F);
  static const lightPrimaryContainer = Color(0xFFD4F1E9);
  static const lightSecondary = Color(0xFF45A592);
  static const lightSecondaryContainer = Color(0xFFD9F4ED);
  static const lightOnSurface = Color(0xFF070F11);
  static const lightOnSurfaceVariant = Color(0xFF444F52);
  static const lightMuted = Color(0xFF647173);
  static const lightOutline = Color(0xFFD8DEDD);
  static const lightOutlineVariant = Color(0xFFE8ECEC);

  static const darkLyricHighlight = Color(0xFFD6917B);
  static const lightLyricHighlight = Color(0xFF20373B);

  static const lightMusicWarm = Color(0xFFD6A771);
  static const lightMusicWarmSoft = Color(0xFFFDEDDC);
  static const lightMusicRose = Color(0xFFDC937C);
  static const lightMusicRoseSoft = Color(0xFFFFE8E0);
  static const lightMusicTeal = Color(0xFF45A592);
  static const lightMusicTealSoft = Color(0xFFD9F4ED);
  static const lightMusicInk = Color(0xFF20373B);

  static const darkMusicWarm = Color(0xFFCEA26F);
  static const darkMusicWarmSoft = Color(0xFF312313);
  static const darkMusicRose = Color(0xFFD6917B);
  static const darkMusicRoseSoft = Color(0xFF362019);
  static const darkMusicTeal = Color(0xFF5FB7A5);
  static const darkMusicTealSoft = Color(0xFF122C26);
  static const darkMusicInk = Color(0xFFBECECF);

  static const lightSuccess = Color(0xFF2E7D4F);
  static const lightWarn = Color(0xFF9A6700);
  static const lightDanger = Color(0xFFB9383A);
  static const darkSuccess = Color(0xFF65C98A);
  static const darkWarn = Color(0xFFE2B85B);
  static const darkDanger = Color(0xFFF08B8D);

  /// 内容区背景渐变 — 左上角色调。
  static const darkAmbientGradientStart = Color(0xFF0C1315);
  static const lightAmbientGradientStart = Color(0xFFF7FCFC);
}

abstract final class AppRadiusTokens {
  static const double desktopSm = 6;
  static const double desktopMd = 10;
  static const double desktopLg = 14;
  static const double desktopXl = 20;
  static const double mobileSm = 8;
  static const double mobileMd = 12;
  static const double mobileLg = 16;
  static const double mobileXl = 24;
  static const double shellContainer = desktopXl;
  static const double card = desktopLg;
  static const double button = 999;
  static const double input = desktopMd;
  static const double iconButton = mobileMd;
  static const double coverGrid = desktopLg;
  static const double coverDetail = desktopXl;
}

abstract final class AppSpacingTokens {
  static const double pageTop = 28;
  static const double pageTopCompact = 18;
  static const double headerBottomGap = 14;
  static const double contentBottom = 24;
  static const double compactFieldBottomGap = 12;
  static const double sectionGap = 24;
  static const double sectionTitleBottomGap = 16;
  static const double cardPadding = 16;
  static const double headerPadding = 22;

  static const double pageHorizontalCompact = 20;
  static const double pageHorizontalMedium = 28;
  static const double pageHorizontalExpanded = 36;

  static const double shellOuterPadding = 0;
  static const double shellGap = 0;
  static const double shellBottomInset = 0;
  static const double macOsTrafficLightInset = 28;
  static const double desktopSidebarWidth = 220;
  static const double desktopMiniPlayerHeight = 72;
  static const double mobileMiniPlayerHeight = 60;
  static const double mobileTabContentHeight = 54;
  static const double desktopMainContentPaddingX = 36;
  static const double desktopMainContentPaddingY = 28;
  static const double mobilePageX = 20;
  static const double desktopCardGridMinWidth = 160;
  static const double desktopCardGridGapX = 18;
  static const double desktopCardGridGapY = 22;

  static const double playerHorizontalPadding = 28;
  static const double playerControlGap = 14;
  static const double playerToolbarGap = 10;
  static const double desktopSidebarTopGap = 12;
  static const double desktopSidebarBottomGap = 18;

  static const double miniPlayerOuterHorizontal = 0;
  static const double miniPlayerOuterTop = 0;
  static const double miniPlayerOuterBottomCompact = 0;
  static const double miniPlayerOuterBottomWide = 0;
  static const double miniPlayerInnerHorizontal = 20;
  static const double miniPlayerInnerVerticalCompact = 0;
  static const double miniPlayerInnerVerticalWide = 0;
  static const double miniPlayerControlGap = 6;
  static const double miniPlayerSectionGap = 10;
}

abstract final class AppBorderTokens {
  static const double thin = 1;
  static const double focus = 1.25;
}

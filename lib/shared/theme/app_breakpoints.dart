import 'package:flutter/widgets.dart';

enum AppLayoutSize { compact, medium, desktop, largeDesktop }

abstract final class AppBreakpoints {
  static const double mediumMinWidth = 768;
  static const double desktopMinWidth = 1080;
  static const double largeDesktopMinWidth = 1440;

  static AppLayoutSize of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  static AppLayoutSize fromWidth(double width) {
    if (width >= largeDesktopMinWidth) {
      return AppLayoutSize.largeDesktop;
    }
    if (width >= desktopMinWidth) {
      return AppLayoutSize.desktop;
    }
    if (width >= mediumMinWidth) {
      return AppLayoutSize.medium;
    }
    return AppLayoutSize.compact;
  }

  static bool isCompact(BuildContext context) =>
      of(context) == AppLayoutSize.compact;

  static bool isMedium(BuildContext context) =>
      of(context) == AppLayoutSize.medium;

  static bool isDesktop(BuildContext context) =>
      of(context) == AppLayoutSize.desktop;

  static bool isLargeDesktop(BuildContext context) =>
      of(context) == AppLayoutSize.largeDesktop;

  static bool isCompactWidth(double width) =>
      fromWidth(width) == AppLayoutSize.compact;

  static bool isMediumWidth(double width) =>
      fromWidth(width) == AppLayoutSize.medium;

  static bool isDesktopWidth(double width) =>
      fromWidth(width) == AppLayoutSize.desktop;

  static bool isLargeDesktopWidth(double width) =>
      fromWidth(width) == AppLayoutSize.largeDesktop;

  static bool usesDesktopShell(BuildContext context) =>
      usesDesktopShellWidth(MediaQuery.sizeOf(context).width);

  static bool usesDesktopShellWidth(double width) => width >= desktopMinWidth;

  static bool usesTrackTable(BuildContext context) =>
      usesDesktopShell(context);

  static bool usesTrackTableWidth(double width) =>
      usesDesktopShellWidth(width);

  static bool usesDesktopToolbar(BuildContext context) =>
      usesDesktopShell(context);

  static bool usesLargeGrid(BuildContext context) =>
      isLargeDesktop(context);

  static bool usesLargeGridWidth(double width) =>
      isLargeDesktopWidth(width);

  static bool usesWideContent(BuildContext context) => !isCompact(context);

  static bool usesWideContentWidth(double width) => !isCompactWidth(width);

  static int adaptiveAlbumGridCount(double width) {
    if (width >= largeDesktopMinWidth) {
      return 7;
    }
    if (width >= desktopMinWidth) {
      return 5;
    }
    if (width >= 960) {
      return 4;
    }
    if (width >= 640) {
      return 3;
    }
    return 2;
  }
}

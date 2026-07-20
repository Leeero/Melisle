import 'package:flutter/widgets.dart';

enum AppLayoutSize { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const double mediumMinWidth = 768;
  static const double expandedMinWidth = 1200;

  static AppLayoutSize of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  static AppLayoutSize fromWidth(double width) {
    if (width >= expandedMinWidth) {
      return AppLayoutSize.expanded;
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

  static bool isExpanded(BuildContext context) =>
      of(context) == AppLayoutSize.expanded;

  static bool isCompactWidth(double width) =>
      fromWidth(width) == AppLayoutSize.compact;

  static bool isMediumWidth(double width) =>
      fromWidth(width) == AppLayoutSize.medium;

  static bool isExpandedWidth(double width) =>
      fromWidth(width) == AppLayoutSize.expanded;

  static bool usesWideContent(BuildContext context) => !isCompact(context);

  static bool usesWideContentWidth(double width) => !isCompactWidth(width);

  static int adaptiveAlbumGridCount(double width) {
    if (width >= expandedMinWidth) {
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

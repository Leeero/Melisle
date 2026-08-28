import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

final class AppPageLayout {
  const AppPageLayout._();

  static const double topInset = AppSpacingTokens.pageTop;
  static const double headerBottomGap = AppSpacingTokens.headerBottomGap;
  static const double contentBottomInset = AppSpacingTokens.contentBottom;
  static const double compactTopInset = AppSpacingTokens.pageTopCompact;
  static const double compactFieldBottomGap =
      AppSpacingTokens.compactFieldBottomGap;
  static const double sectionGap = AppSpacingTokens.sectionGap;
  static const double sectionTitleBottomGap =
      AppSpacingTokens.sectionTitleBottomGap;

  static double contentTopInset(BuildContext context) {
    return AppBreakpoints.isCompact(context)
        ? compactTopInset
        : topInset;
  }

  static double horizontalPadding(BuildContext context) {
    return switch (AppBreakpoints.of(context)) {
      AppLayoutSize.compact => AppSpacingTokens.pageHorizontalCompact,
      AppLayoutSize.medium => AppSpacingTokens.pageHorizontalMedium,
      AppLayoutSize.desktop ||
      AppLayoutSize.largeDesktop => AppSpacingTokens.pageHorizontalExpanded,
    };
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double? top,
    double bottom = contentBottomInset,
  }) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(
      horizontal,
      top ?? contentTopInset(context),
      horizontal,
      bottom,
    );
  }

  static EdgeInsets headerPadding(
    BuildContext context, {
    double? top,
    double bottom = headerBottomGap,
  }) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(
      horizontal,
      top ?? contentTopInset(context),
      horizontal,
      bottom,
    );
  }

  static EdgeInsets sectionPadding(
    BuildContext context, {
    double top = 0,
    double bottom = sectionGap,
  }) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }
}

class AppContentPage extends StatefulWidget {
  const AppContentPage({
    super.key,
    this.header,
    required this.body,
    this.topSafeArea = true,
  });

  final Widget? header;
  final Widget body;
  final bool topSafeArea;

  @override
  State<AppContentPage> createState() => _AppContentPageState();
}

class _AppContentPageState extends State<AppContentPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppMotion.enter,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(_fadeAnimation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAnimated) return;
    _hasAnimated = true;

    if (MediaQuery.of(context).disableAnimations) {
      _fadeController.value = 1;
    } else {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: widget.topSafeArea,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              if (widget.header != null)
                Padding(
                  padding: AppPageLayout.headerPadding(context),
                  child: widget.header!,
                ),
              Expanded(child: widget.body),
            ],
          ),
        ),
      ),
    );
  }
}

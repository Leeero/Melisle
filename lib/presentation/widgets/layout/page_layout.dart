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

  static double horizontalPadding(BuildContext context) {
    return switch (AppBreakpoints.of(context)) {
      AppLayoutSize.compact => AppSpacingTokens.pageHorizontalCompact,
      AppLayoutSize.medium => AppSpacingTokens.pageHorizontalMedium,
      AppLayoutSize.expanded => AppSpacingTokens.pageHorizontalExpanded,
    };
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = topInset,
    double bottom = contentBottomInset,
  }) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static EdgeInsets headerPadding(
    BuildContext context, {
    double top = topInset,
    double bottom = headerBottomGap,
  }) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
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
    required this.header,
    required this.body,
    this.topSafeArea = true,
  });

  final Widget header;
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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppMotion.enter,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(_fadeAnimation);
    _fadeController.forward();
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
      child: _AppContentViewport(
        header: widget.header,
        body: widget.body,
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
      ),
    );
  }
}

class _AppContentViewport extends StatelessWidget {
  const _AppContentViewport({
    required this.header,
    required this.body,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  final Widget header;
  final Widget body;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Column(
          children: [
            _AppContentHeader(child: header),
            Expanded(child: _AppContentBody(child: body)),
          ],
        ),
      ),
    );
  }
}

class _AppContentHeader extends StatelessWidget {
  const _AppContentHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: AppPageLayout.headerPadding(context), child: child);
  }
}

class _AppContentBody extends StatelessWidget {
  const _AppContentBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class AppPageHeaderCard extends StatelessWidget {
  const AppPageHeaderCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.headerPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadiusTokens.shellContainer),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: child,
    );
  }
}

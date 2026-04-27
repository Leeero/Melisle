import 'package:flutter/material.dart';

final class AppPageLayout {
  const AppPageLayout._();

  static const double topInset = 20;
  static const double headerBottomGap = 14;
  static const double contentBottomInset = 24;
  static const double compactTopInset = 12;
  static const double compactFieldBottomGap = 12;
  static const double sectionGap = 24;
  static const double sectionTitleBottomGap = 16;

  static double horizontalPadding(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 960 ? 24 : 16;
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
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Padding(
                padding: AppPageLayout.headerPadding(context),
                child: widget.header,
              ),
              Expanded(child: widget.body),
            ],
          ),
        ),
      ),
    );
  }
}

class AppPageHeaderCard extends StatelessWidget {
  const AppPageHeaderCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: child,
    );
  }
}

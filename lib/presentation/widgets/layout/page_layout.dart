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

class AppPageTitleRow extends StatelessWidget {
  const AppPageTitleRow({
    super.key,
    required this.title,
    this.description,
    this.badge,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final String title;
  final String? description;
  final Widget? badge;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (description != null) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 12), badge!],
          if (action != null) ...[const SizedBox(width: 10), action!],
        ],
      ),
    );
  }
}

class AppSectionTitleRow extends StatelessWidget {
  const AppSectionTitleRow({
    super.key,
    required this.title,
    this.badge,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(0, 6, 0, 10),
    this.titleStyle,
  });

  final String title;
  final Widget? badge;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final trailingChildren = <Widget>[];
    final action = this.action;
    if (action != null) {
      trailingChildren.addAll([action, const SizedBox(width: 10)]);
    }
    final badge = this.badge;
    if (badge != null) {
      trailingChildren.add(badge);
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(
            title,
            style: titleStyle ?? Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          ...trailingChildren,
        ],
      ),
    );
  }
}

class AppBodyStateView extends StatelessWidget {
  const AppBodyStateView.loading({super.key})
    : message = null,
      action = null,
      _isLoading = true;

  const AppBodyStateView.message({
    super.key,
    required this.message,
    this.action,
  }) : _isLoading = false;

  final String? message;
  final Widget? action;
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message!, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

class AppSliverStateView extends StatelessWidget {
  const AppSliverStateView.loading({super.key})
    : message = null,
      action = null,
      _isLoading = true;

  const AppSliverStateView.message({
    super.key,
    required this.message,
    this.action,
  }) : _isLoading = false;

  final String? message;
  final Widget? action;
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: _isLoading
          ? const AppBodyStateView.loading()
          : AppBodyStateView.message(message: message!, action: action),
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

class AppDetailHeroFrame extends StatelessWidget {
  const AppDetailHeroFrame({
    super.key,
    required this.coverBuilder,
    required this.contentBuilder,
    this.padding = const EdgeInsets.all(22),
    this.spacing = 24,
    this.compactGap = 20,
  });

  final Widget Function(BuildContext context, bool isWide) coverBuilder;
  final Widget Function(BuildContext context, bool isWide) contentBuilder;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double compactGap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = AppBreakpoints.usesWideContentWidth(
            constraints.maxWidth,
          );
          final cover = coverBuilder(context, isWide);
          final content = contentBuilder(context, isWide);
          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: cover),
                SizedBox(height: compactGap),
                content,
              ],
            );
          }

          return Row(
            children: [
              cover,
              SizedBox(width: spacing),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

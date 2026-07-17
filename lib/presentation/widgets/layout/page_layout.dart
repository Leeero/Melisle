import 'dart:ui';

import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
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

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.description,
    this.center,
    this.trailing,
    this.leading,
    this.automaticImplyLeading = true,
    this.hideTitleOnCompactWithCenter = true,
    this.centerWidth,
    this.titleMaxWidth = 300,
    this.maxWidth = 1320,
  });

  final String title;
  final String? description;
  final Widget? center;
  final Widget? trailing;
  final Widget? leading;
  final bool automaticImplyLeading;
  final bool hideTitleOnCompactWithCenter;
  final double? centerWidth;
  final double titleMaxWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final impliedLeading =
        automaticImplyLeading && Navigator.of(context).canPop()
        ? AppBackButton(onPressed: () => Navigator.of(context).maybePop())
        : null;
    final leadingWidget = leading ?? impliedLeading;

    if (compact && center != null && hideTitleOnCompactWithCenter) {
      return Row(
        children: [
          if (leadingWidget != null) ...[
            leadingWidget,
            const SizedBox(width: 8),
          ],
          Expanded(child: center!),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      );
    }

    if (compact && center != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AppPageTitleRow(
                  title: title,
                  description: description,
                  padding: EdgeInsets.zero,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          const SizedBox(height: 12),
          center!,
        ],
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingWidget != null) ...[
            leadingWidget,
            const SizedBox(width: 12),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 0, maxWidth: titleMaxWidth),
            child: AppPageTitleRow(
              title: title,
              description: description,
              padding: EdgeInsets.zero,
            ),
          ),
          if (center != null) ...[
            const SizedBox(width: 24),
            if (centerWidth == null)
              Expanded(child: center!)
            else
              SizedBox(width: centerWidth, child: center!),
            if (centerWidth != null) const Spacer(),
          ] else
            const Spacer(),
          if (trailing != null) ...[const SizedBox(width: 16), trailing!],
        ],
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
      tooltip: '返回',
      onPressed: onPressed,
      style: AppActionButtonStyle.icon(context, iconSize: 22),
    );
  }
}

class AppDetailBackNav extends StatelessWidget {
  const AppDetailBackNav({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.chevron_left_rounded, size: 22),
        label: const Text('返回'),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText,
    this.hintText = '搜索',
    this.semanticLabel = '搜索',
    this.clearTooltip = '清空搜索',
    this.onClear,
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.cancelLabel = '取消',
    this.autofocus = false,
    this.dense = false,
    this.enabled = true,
    this.showCancelAction,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String hintText;
  final String semanticLabel;
  final String clearTooltip;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final bool autofocus;
  final bool dense;
  final bool enabled;
  final bool? showCancelAction;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
  }

  void _attachFocusNode(FocusNode? node) {
    _ownsFocusNode = node == null;
    _focusNode = node ?? FocusNode();
    _focused = _focusNode.hasFocus;
    _focusNode.addListener(_onFocusChanged);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  void _clear() {
    if (widget.onClear != null) {
      widget.onClear!();
      return;
    }
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  void _cancel() {
    widget.onCancel?.call();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _detachFocusNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final showCancel = widget.showCancelAction ?? compact;
    final fieldHeight = compact ? 46.0 : 46.0;
    final radius = compact ? AppRadiusTokens.mobileMd : AppRadiusTokens.button;
    final fillColor = compact
        ? Color.alphaBlend(
            colorScheme.outlineVariant.withValues(alpha: 0.34),
            colorScheme.surfaceContainerHigh,
          )
        : colorScheme.surface.withValues(alpha: 0.86);
    final focusedFillColor = compact
        ? Color.alphaBlend(
            colorScheme.outlineVariant.withValues(alpha: 0.18),
            colorScheme.surfaceContainerHigh,
          )
        : colorScheme.surface;
    final borderColor = _focused
        ? colorScheme.primary.withValues(alpha: compact ? 0.0 : 0.46)
        : colorScheme.outlineVariant.withValues(alpha: compact ? 0.0 : 0.74);
    final focusRing = colorScheme.primary.withValues(
      alpha: compact ? 0.0 : 0.12,
    );
    final inputTextStyle =
        (compact ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium)
            ?.copyWith(color: colorScheme.onSurface);

    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.micro,
              curve: AppMotion.enter,
              height: fieldHeight,
              decoration: BoxDecoration(
                color: _focused ? focusedFillColor : fillColor,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: borderColor),
                boxShadow: _focused && !compact
                    ? [
                        BoxShadow(
                          color: focusRing,
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: compact ? 0 : 18,
                    sigmaY: compact ? 0 : 18,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    enabled: widget.enabled,
                    textInputAction: TextInputAction.search,
                    textAlignVertical: TextAlignVertical.center,
                    style: inputTextStyle,
                    decoration: InputDecoration(
                      labelText: widget.labelText,
                      hintText: widget.hintText,
                      isDense: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: compact ? 40 : 44,
                        minHeight: fieldHeight,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: Icon(
                              Icons.cancel_rounded,
                              size: compact ? 18 : 20,
                            ),
                            tooltip: widget.clearTooltip,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.standard,
                            constraints: const BoxConstraints.tightFor(
                              width: 46,
                              height: 46,
                            ),
                            style: AppActionButtonStyle.icon(
                              context,
                              size: 46,
                              iconSize: compact ? 18 : 20,
                            ),
                            onPressed: _clear,
                          );
                        },
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 46,
                        minHeight: 46,
                      ),
                    ),
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                  ),
                ),
              ),
            ),
          ),
          if (showCancel) ...[
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: AppMotion.micro,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              child: _focused
                  ? TextButton(
                      key: const ValueKey('search-cancel'),
                      onPressed: _cancel,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        textStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Text(widget.cancelLabel),
                    )
                  : const SizedBox.shrink(key: ValueKey('search-cancel-empty')),
            ),
          ],
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final compact = AppBreakpoints.isCompact(context);
    final effectiveTitleStyle =
        titleStyle ??
        (compact ? theme.textTheme.titleMedium : theme.textTheme.titleSmall)
            ?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: compact ? 18 : 17,
              fontWeight: FontWeight.w600,
            );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: effectiveTitleStyle,
          ),
          const Spacer(),
          if (badge != null) ...[const SizedBox(width: 10), badge!],
          if (action != null) ...[const SizedBox(width: 10), action!],
        ],
      ),
    );
  }
}

class AppBodyStateView extends StatelessWidget {
  const AppBodyStateView.loading({
    super.key,
    this.title = '正在加载内容',
    this.description = '请稍候，数据会在完成后自动显示。',
  }) : message = null,
       icon = null,
       action = null,
       _isLoading = true;

  const AppBodyStateView.message({
    super.key,
    required this.message,
    this.title,
    this.description,
    this.icon,
    this.action,
  }) : _isLoading = false;

  final String? message;
  final String? title;
  final String? description;
  final IconData? icon;
  final Widget? action;
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppLoadingView(title: title, description: description);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = title ?? message!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
            ],
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.title = '正在加载内容',
    this.description = '请稍候，数据会在完成后自动显示。',
  });

  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final title = this.title;
    final description = this.description;

    return Semantics(
      label: title ?? '正在加载',
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppPageLayout.horizontalPadding(context),
            vertical: compact ? 28 : 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: compact ? 48 : 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: compact ? 2.4 : 2.6,
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.outlineVariant.withValues(
                          alpha: 0.36,
                        ),
                      ),
                      Icon(
                        Icons.library_music_rounded,
                        size: compact ? 20 : 22,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: compact ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
                if (description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.muted,
                      fontSize: compact ? 12 : 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppSliverStateView extends StatelessWidget {
  const AppSliverStateView.loading({
    super.key,
    this.title = '正在加载内容',
    this.description = '请稍候，数据会在完成后自动显示。',
  }) : message = null,
       icon = null,
       action = null,
       _isLoading = true;

  const AppSliverStateView.message({
    super.key,
    required this.message,
    this.title,
    this.description,
    this.icon,
    this.action,
  }) : _isLoading = false;

  final String? message;
  final String? title;
  final String? description;
  final IconData? icon;
  final Widget? action;
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: _isLoading
          ? AppBodyStateView.loading(title: title, description: description)
          : AppBodyStateView.message(
              message: message!,
              title: title,
              description: description,
              icon: icon,
              action: action,
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
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = AppBreakpoints.usesWideContentWidth(
            constraints.maxWidth,
          );
          final cover = coverBuilder(context, isWide);
          final content = contentBuilder(context, isWide);
          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: cover),
                SizedBox(height: compactGap),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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

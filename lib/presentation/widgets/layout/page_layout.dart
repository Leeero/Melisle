import 'dart:ui';

import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

export 'package:cross_platform_music_player/presentation/widgets/feedback/app_state_view.dart';
export 'app_page_layout.dart';
export 'detail_layout.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.description,
    this.titleBadge,
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
  final Widget? titleBadge;
  final Widget? center;
  final Widget? trailing;
  final Widget? leading;
  final bool automaticImplyLeading;
  final bool hideTitleOnCompactWithCenter;
  final double? centerWidth;
  final double titleMaxWidth;
  final double maxWidth;

  static const _stackedTrailingBreakpoint = 720.0;

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
                  titleBadge: titleBadge,
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

    if (compact) {
      return Row(
        children: [
          if (leadingWidget != null) ...[
            leadingWidget,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: AppPageTitleRow(
              title: title,
              description: description,
              titleBadge: titleBadge,
              padding: EdgeInsets.zero,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackTrailing =
              center == null &&
              trailing != null &&
              constraints.maxWidth < _stackedTrailingBreakpoint;
          if (stackTrailing) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (leadingWidget != null) ...[
                      leadingWidget,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: AppPageTitleRow(
                        title: title,
                        description: description,
                        titleBadge: titleBadge,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: 12),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 0,
                  maxWidth: titleMaxWidth,
                ),
                child: AppPageTitleRow(
                  title: title,
                  description: description,
                  titleBadge: titleBadge,
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
          );
        },
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
  const AppDetailBackNav({
    super.key,
    required this.onPressed,
    this.label = '返回',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.chevron_left_rounded, size: 22),
        label: Text(label),
        style:
            AppActionButtonStyle.link(
              context,
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            ).copyWith(
              textStyle: WidgetStatePropertyAll(
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                            constraints: BoxConstraints.tightFor(
                              width: compact ? 40 : 46,
                              height: compact ? 40 : 46,
                            ),
                            style: AppActionButtonStyle.icon(
                              context,
                              size: compact ? 40 : 46,
                              iconSize: compact ? 18 : 20,
                            ),
                            onPressed: _clear,
                          );
                        },
                      ),
                      suffixIconConstraints: BoxConstraints(
                        minWidth: compact ? 40 : 46,
                        minHeight: compact ? 40 : 46,
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
                      style: AppActionButtonStyle.link(context),
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
    this.titleBadge,
    this.badge,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final String title;
  final String? description;
  final Widget? titleBadge;
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
                if (titleBadge != null) ...[
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(0, -7),
                    child: titleBadge!,
                  ),
                ],
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
    this.padding = const EdgeInsets.only(
      top: AppSpacingTokens.compactGap,
      bottom: AppSpacingTokens.listTileVPadding,
    ),
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

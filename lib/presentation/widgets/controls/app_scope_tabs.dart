import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class AppScopeTabItem<T> {
  const AppScopeTabItem({
    required this.value,
    required this.label,
    this.count,
    this.icon,
    this.semanticLabel,
  });

  final T value;
  final String label;
  final int? count;
  final IconData? icon;
  final String? semanticLabel;

  String get displayLabel => count == null ? label : '$label $count';
}

class AppScopeTabs<T> extends StatelessWidget {
  const AppScopeTabs({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.variant,
    this.semanticLabel = '分类',
    this.fillWidth = false,
    this.tabGap,
  });

  final List<AppScopeTabItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final AppScopeTabsVariant? variant;
  final String semanticLabel;
  final bool fillWidth;
  final double? tabGap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveVariant =
        variant ??
        (AppBreakpoints.usesWideContent(context)
            ? AppScopeTabsVariant.underline
            : AppScopeTabsVariant.pill);
    final fillAvailableWidth =
        fillWidth && effectiveVariant == AppScopeTabsVariant.pill;
    final tabGap =
        this.tabGap ??
        (effectiveVariant == AppScopeTabsVariant.underline ? 18.0 : 2.0);
    final tabChildren = [
      for (var index = 0; index < items.length; index++) ...[
        if (fillAvailableWidth)
          Expanded(
            child: _AppScopeTab(
              item: items[index],
              selected: items[index].value == selectedValue,
              variant: effectiveVariant,
              compact: fillAvailableWidth,
              onPressed: () => onChanged(items[index].value),
            ),
          )
        else
          _AppScopeTab(
            item: items[index],
            selected: items[index].value == selectedValue,
            variant: effectiveVariant,
            compact: false,
            onPressed: () => onChanged(items[index].value),
          ),
        if (index != items.length - 1) SizedBox(width: tabGap),
      ],
    ];
    final tabs = fillAvailableWidth
        ? Row(children: tabChildren)
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: tabChildren),
          );

    return Semantics(
      label: semanticLabel,
      child: effectiveVariant == AppScopeTabsVariant.underline
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.76),
                  ),
                ),
              ),
              child: tabs,
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.32
                      : 0.58,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(padding: const EdgeInsets.all(2), child: tabs),
            ),
    );
  }
}

enum AppScopeTabsVariant { underline, pill }

class _AppScopeTab<T> extends StatefulWidget {
  const _AppScopeTab({
    required this.item,
    required this.selected,
    required this.variant,
    required this.compact,
    required this.onPressed,
  });

  final AppScopeTabItem<T> item;
  final bool selected;
  final AppScopeTabsVariant variant;
  final bool compact;
  final VoidCallback onPressed;

  @override
  State<_AppScopeTab<T>> createState() => _AppScopeTabState<T>();
}

class _AppScopeTabState<T> extends State<_AppScopeTab<T>> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final active = widget.compact
        ? widget.selected
        : widget.selected || _hovered || _focused;
    final isUnderline = widget.variant == AppScopeTabsVariant.underline;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.semanticLabel ?? '查看${widget.item.label}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              widget.variant == AppScopeTabsVariant.pill
                  ? AppRadiusTokens.button
                  : AppRadiusTokens.iconButton,
            ),
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onFocusChange: (value) => setState(() => _focused = value),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: widget.compact ? Duration.zero : AppMotion.micro,
              curve: AppMotion.enter,
              constraints: BoxConstraints(minWidth: isUnderline ? 0 : 0),
              height: isUnderline ? 40 : 34,
              padding: EdgeInsets.symmetric(
                horizontal: isUnderline
                    ? 0
                    : widget.compact
                    ? 6
                    : 14,
              ),
              decoration: _decoration(context),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: widget.compact
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.item.icon != null) ...[
                    Icon(
                      widget.item.icon,
                      size: 18,
                      color: widget.selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    widget.item.displayLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (isUnderline
                                ? theme.textTheme.labelLarge
                                : theme.textTheme.labelMedium)
                            ?.copyWith(
                              color: widget.selected
                                  ? colorScheme.onSurface
                                  : active
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: widget.selected
                                  ? FontWeight.w600
                                  : FontWeight.w600,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.variant == AppScopeTabsVariant.underline) {
      return BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 2,
            color: widget.selected ? colorScheme.primary : Colors.transparent,
          ),
        ),
      );
    }

    return BoxDecoration(
      color: widget.selected
          ? colorScheme.surface
          : (!widget.compact && (_hovered || _focused)
                ? theme.hoverWash
                : Colors.transparent),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: widget.selected
            ? colorScheme.outlineVariant.withValues(alpha: 0.34)
            : Colors.transparent,
      ),
      boxShadow: widget.selected
          ? [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.10),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ]
          : const <BoxShadow>[],
    );
  }
}

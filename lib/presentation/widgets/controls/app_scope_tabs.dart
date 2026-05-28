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
  });

  final List<AppScopeTabItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final AppScopeTabsVariant? variant;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveVariant =
        variant ??
        (AppBreakpoints.usesWideContent(context)
            ? AppScopeTabsVariant.underline
            : AppScopeTabsVariant.pill);
    final tabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _AppScopeTab(
              item: items[index],
              selected: items[index].value == selectedValue,
              variant: effectiveVariant,
              onPressed: () => onChanged(items[index].value),
            ),
            if (effectiveVariant == AppScopeTabsVariant.pill &&
                index != items.length - 1)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );

    return Semantics(
      label: semanticLabel,
      child: effectiveVariant == AppScopeTabsVariant.underline
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.68),
                  ),
                ),
              ),
              child: tabs,
            )
          : tabs,
    );
  }
}

enum AppScopeTabsVariant { underline, pill }

class _AppScopeTab<T> extends StatefulWidget {
  const _AppScopeTab({
    required this.item,
    required this.selected,
    required this.variant,
    required this.onPressed,
  });

  final AppScopeTabItem<T> item;
  final bool selected;
  final AppScopeTabsVariant variant;
  final VoidCallback onPressed;

  @override
  State<_AppScopeTab<T>> createState() => _AppScopeTabState<T>();
}

class _AppScopeTabState<T> extends State<_AppScopeTab<T>> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = widget.selected || _hovered || _focused;

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
            focusColor: colorScheme.primary.withValues(alpha: 0.08),
            splashColor: colorScheme.primary.withValues(alpha: 0.06),
            highlightColor: Colors.transparent,
            onFocusChange: (value) => setState(() => _focused = value),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: AppMotion.micro,
              curve: AppMotion.enter,
              constraints: BoxConstraints(
                minWidth: widget.variant == AppScopeTabsVariant.underline
                    ? 116
                    : 0,
              ),
              height: widget.variant == AppScopeTabsVariant.underline ? 48 : 44,
              padding: EdgeInsets.symmetric(
                horizontal: widget.variant == AppScopeTabsVariant.underline
                    ? 18
                    : 16,
              ),
              decoration: _decoration(context),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.item.icon != null) ...[
                    Icon(
                      widget.item.icon,
                      size: 18,
                      color: widget.selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.item.displayLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: widget.selected
                          ? widget.variant == AppScopeTabsVariant.underline
                                ? colorScheme.primary
                                : colorScheme.onPrimaryContainer
                          : active
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontWeight: widget.selected
                          ? FontWeight.w700
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
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.variant == AppScopeTabsVariant.underline) {
      return BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: widget.selected ? 2.5 : 2,
            color: widget.selected ? colorScheme.primary : Colors.transparent,
          ),
        ),
      );
    }

    return BoxDecoration(
      color: widget.selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.82)
          : colorScheme.surface.withValues(
              alpha: _hovered || _focused ? 0.7 : 0.5,
            ),
      borderRadius: BorderRadius.circular(AppRadiusTokens.button),
      border: Border.all(
        color: widget.selected
            ? colorScheme.primary.withValues(alpha: 0.5)
            : colorScheme.outlineVariant.withValues(alpha: 0.72),
      ),
    );
  }
}

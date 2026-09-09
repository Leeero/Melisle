import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class AppTextTabItem<T> {
  const AppTextTabItem({required this.value, required this.label, this.count});

  final T value;
  final String label;
  final int? count;
}

/// Underlined text tabs used for switching between peer content scopes.
class AppTextTabs<T> extends StatelessWidget {
  const AppTextTabs({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<AppTextTabItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final mobileColors = context.mobileTheme;

    return Wrap(
      spacing: compact ? 18 : 28,
      runSpacing: compact ? 4 : 10,
      children: [
        for (final item in items)
          Semantics(
            button: true,
            selected: selectedValue == item.value,
            child: InkWell(
              onTap: () => onChanged(item.value),
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(AppRadiusTokens.sm),
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 4 : 2,
                    vertical: compact ? 8 : 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Text(
                            item.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: selectedValue == item.value
                                  ? compact
                                        ? mobileColors.onSurface
                                        : colors.onSurface
                                  : compact
                                  ? mobileColors.onSurfaceVariant
                                  : colors.onSurfaceVariant,
                              fontWeight: selectedValue == item.value
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (item.count != null)
                            Positioned(
                              top: -8,
                              right: -16,
                              child: _TabCountBadge(count: item.count!),
                            ),
                        ],
                      ),
                      SizedBox(height: compact ? 4 : 7),
                      AnimatedContainer(
                        duration: AppMotion.adaptive(context, AppMotion.fast),
                        height: compact ? 2 : 3,
                        width: compact ? 18 : 22,
                        decoration: BoxDecoration(
                          color: selectedValue == item.value
                              ? compact
                                    ? mobileColors.primary
                                    : colors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TabCountBadge extends StatelessWidget {
  const _TabCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$count 项',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minWidth: 16),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

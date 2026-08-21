import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class AppTextTabItem<T> {
  const AppTextTabItem({required this.value, required this.label});

  final T value;
  final String label;
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

    return Wrap(
      spacing: 28,
      runSpacing: 10,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selectedValue == item.value
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                        fontWeight: selectedValue == item.value
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    AnimatedContainer(
                      duration: AppMotion.micro,
                      height: 3,
                      width: 22,
                      decoration: BoxDecoration(
                        color: selectedValue == item.value
                            ? colors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

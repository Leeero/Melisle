import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class SearchEmptyView extends StatelessWidget {
  const SearchEmptyView({
    super.key,
    required this.hotQueries,
    required this.onQuerySelected,
    this.recentQueries = const [],
    this.onClearRecent,
  });

  final List<String> hotQueries;
  final List<String> recentQueries;
  final ValueChanged<String> onQuerySelected;
  final VoidCallback? onClearRecent;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final hasRecent = recentQueries.isNotEmpty;
    final recentSet = recentQueries.map((query) => query.trim()).toSet();
    final visibleHotQueries = hotQueries
        .where((query) => !recentSet.contains(query.trim()))
        .toList(growable: false);

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? double.infinity : 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasRecent) ...[
              SearchChipGroup(
                title: '最近搜索',
                action: onClearRecent == null
                    ? null
                    : TextButton.icon(
                        onPressed: onClearRecent,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('清空'),
                      ),
                chips: [
                  for (final query in recentQueries)
                    SearchSuggestionChip(
                      label: query,
                      icon: Icons.history_rounded,
                      onPressed: () => onQuerySelected(query),
                    ),
                ],
              ),
            ],
            if (visibleHotQueries.isNotEmpty) ...[
              const SizedBox(height: 22),
              SearchChipGroup(
                title: '热门搜索',
                chips: [
                  for (final query in visibleHotQueries)
                    SearchSuggestionChip(
                      label: query,
                      icon: Icons.north_east_rounded,
                      onPressed: () => onQuerySelected(query),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SearchChipGroup extends StatelessWidget {
  const SearchChipGroup({
    super.key,
    required this.title,
    required this.chips,
    this.action,
  });

  final String title;
  final List<Widget> chips;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 10), action!],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }
}

class SearchSuggestionChip extends StatelessWidget {
  const SearchSuggestionChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
      label: Text(label),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.82),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.28),
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      onPressed: onPressed,
    );
  }
}

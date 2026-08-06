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

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns =
            !compact &&
            constraints.maxWidth >= 760 &&
            hasRecent &&
            visibleHotQueries.isNotEmpty;
        final recentPanel = _SearchDiscoveryPanel(
          title: '最近搜索',
          icon: Icons.history_rounded,
          action: onClearRecent == null
              ? null
              : TextButton(onPressed: onClearRecent, child: const Text('清空')),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final query in recentQueries)
                SearchSuggestionChip(
                  label: query,
                  icon: Icons.history_rounded,
                  onPressed: () => onQuerySelected(query),
                ),
            ],
          ),
        );
        final popularPanel = _SearchDiscoveryPanel(
          title: '热门发现',
          icon: Icons.local_fire_department_outlined,
          child: _PopularSearchGrid(
            queries: visibleHotQueries,
            onSelected: onQuerySelected,
            twoColumns: !compact,
          ),
        );

        return Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发现你想听的音乐',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '可以搜索歌曲、艺术家、专辑或歌单',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                if (useColumns)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 330, child: recentPanel),
                      const SizedBox(width: 18),
                      Expanded(child: popularPanel),
                    ],
                  )
                else ...[
                  if (hasRecent) ...[recentPanel, const SizedBox(height: 18)],
                  if (visibleHotQueries.isNotEmpty) popularPanel,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchDiscoveryPanel extends StatelessWidget {
  const _SearchDiscoveryPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PopularSearchGrid extends StatelessWidget {
  const _PopularSearchGrid({
    required this.queries,
    required this.onSelected,
    required this.twoColumns,
  });

  final List<String> queries;
  final ValueChanged<String> onSelected;
  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = twoColumns
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (var index = 0; index < queries.length; index++)
              SizedBox(
                width: itemWidth,
                child: _PopularSearchItem(
                  rank: index + 1,
                  label: queries[index],
                  onPressed: () => onSelected(queries[index]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PopularSearchItem extends StatelessWidget {
  const _PopularSearchItem({
    required this.rank,
    required this.label,
    required this.onPressed,
  });

  final int rank;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '搜索$label',
      child: InkWell(
        onTap: onPressed,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(AppRadiusTokens.iconButton),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: rank <= 3
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.north_east_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
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

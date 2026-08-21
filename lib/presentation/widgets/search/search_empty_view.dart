import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class SearchEmptyView extends StatelessWidget {
  const SearchEmptyView({
    super.key,
    required this.onQuerySelected,
    this.recentQueries = const [],
    this.onClearRecent,
    this.onQueryRemoved,
  });

  final List<String> recentQueries;
  final ValueChanged<String> onQuerySelected;
  final VoidCallback? onClearRecent;
  final ValueChanged<String>? onQueryRemoved;

  @override
  Widget build(BuildContext context) {
    final hasRecent = recentQueries.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
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
                  onDeleted: onQueryRemoved == null
                      ? null
                      : () => onQueryRemoved!(query),
                ),
            ],
          ),
        );
        return Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasRecent)
                  recentPanel
                else
                  _SearchDiscoveryPanel(
                    title: '搜索音乐库',
                    icon: Icons.search_rounded,
                    child: Text(
                      '输入歌曲、专辑、歌手或歌单名称。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
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
    this.onDeleted,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputChip(
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
      onDeleted: onDeleted,
      deleteButtonTooltipMessage: onDeleted == null ? null : '删除搜索历史：$label',
    );
  }
}

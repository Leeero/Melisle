import 'package:flutter/material.dart';

enum MetaPillSize { compact, regular }

class MetaPill extends StatelessWidget {
  const MetaPill({
    super.key,
    required this.label,
    this.size = MetaPillSize.regular,
    this.backgroundColor,
  });

  final String label;
  final MetaPillSize size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = size == MetaPillSize.compact;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            colorScheme.surface.withValues(alpha: compact ? 0.48 : 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: compact
            ? theme.textTheme.labelSmall
            : theme.textTheme.labelMedium,
      ),
    );
  }
}

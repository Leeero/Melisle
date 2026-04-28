import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 12),
    this.bold = true,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
    );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: textStyle)),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

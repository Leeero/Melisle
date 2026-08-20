import 'package:cross_platform_music_player/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacingTokens.pageHorizontalCompact,
      AppSpacingTokens.inlineGap,
      AppSpacingTokens.pageHorizontalCompact,
      AppSpacingTokens.contentGap,
    ),
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

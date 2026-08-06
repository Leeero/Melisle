import 'package:cross_platform_music_player/presentation/widgets/layout/app_page_layout.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class AppBodyStateView extends StatelessWidget {
  const AppBodyStateView.loading({
    super.key,
    this.title = '正在加载内容',
    this.description = '请稍候，数据会在完成后自动显示。',
  }) : message = null,
       icon = null,
       action = null,
       _isLoading = true;

  const AppBodyStateView.message({
    super.key,
    required this.message,
    this.title,
    this.description,
    this.icon,
    this.action,
  }) : _isLoading = false;

  final String? message;
  final String? title;
  final String? description;
  final IconData? icon;
  final Widget? action;
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppLoadingView(title: title, description: description);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = title ?? message!;

    return Semantics(
      label: displayTitle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.mobilePageX),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
              ],
              Text(
                displayTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (description != null) ...[
                const SizedBox(height: 6),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 14), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.title = '正在加载内容',
    this.description = '请稍候，数据会在完成后自动显示。',
  });

  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final effectiveTitle = title;
    final effectiveDescription = description;

    return Semantics(
      label: effectiveTitle ?? '正在加载',
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppPageLayout.horizontalPadding(context),
            vertical: compact ? 28 : 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: compact ? 48 : 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: compact ? 2.4 : 2.6,
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.outlineVariant.withValues(
                          alpha: 0.36,
                        ),
                      ),
                      Icon(
                        Icons.library_music_rounded,
                        size: compact ? 20 : 22,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                if (effectiveTitle != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    effectiveTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: compact ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
                if (effectiveDescription != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    effectiveDescription,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.muted,
                      fontSize: compact ? 12 : 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppSliverStateView extends StatelessWidget {
  const AppSliverStateView.loading({
    super.key,
    this.title = '正在加载内容',
    this.description = '请稍候，数据会在完成后自动显示。',
  }) : message = null,
       icon = null,
       action = null,
       _isLoading = true;

  const AppSliverStateView.message({
    super.key,
    required this.message,
    this.title,
    this.description,
    this.icon,
    this.action,
  }) : _isLoading = false;

  final String? message;
  final String? title;
  final String? description;
  final IconData? icon;
  final Widget? action;
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: _isLoading
          ? AppBodyStateView.loading(title: title, description: description)
          : AppBodyStateView.message(
              message: message!,
              title: title,
              description: description,
              icon: icon,
              action: action,
            ),
    );
  }
}

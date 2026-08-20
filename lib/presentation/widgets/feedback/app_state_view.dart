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
          padding: const EdgeInsets.all(AppSpacingTokens.sectionGap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: AppSpacingTokens.cardPadding),
              ],
              Text(
                displayTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: AppSpacingTokens.inlineGap),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacingTokens.sectionGap),
                action!,
              ],
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

enum AppPaginationStatus { idle, loading, failed, complete }

class AppPaginationFooter extends StatelessWidget {
  const AppPaginationFooter({
    super.key,
    required this.status,
    this.errorMessage,
    this.onRetry,
    this.completeLabel = '到底了',
  });

  final AppPaginationStatus status;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String completeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      liveRegion:
          status == AppPaginationStatus.loading ||
          status == AppPaginationStatus.failed,
      label: switch (status) {
        AppPaginationStatus.idle => '可以继续加载',
        AppPaginationStatus.loading => '正在加载更多内容',
        AppPaginationStatus.failed => errorMessage ?? '加载更多失败',
        AppPaginationStatus.complete => completeLabel,
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
        child: Center(
          child: switch (status) {
            AppPaginationStatus.idle => const SizedBox(height: 12),
            AppPaginationStatus.loading => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 9),
                Text(
                  '正在加载更多…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            AppPaginationStatus.failed => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 24,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 6),
                Text(
                  errorMessage ?? '无法连接到服务器',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('重试'),
                  ),
                ],
              ],
            ),
            AppPaginationStatus.complete => Text(
              completeLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          },
        ),
      ),
    );
  }
}

class AppSliverPaginationFooter extends StatelessWidget {
  const AppSliverPaginationFooter({
    super.key,
    required this.status,
    this.errorMessage,
    this.onRetry,
    this.completeLabel = '到底了',
  });

  final AppPaginationStatus status;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String completeLabel;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AppPaginationFooter(
        status: status,
        errorMessage: errorMessage,
        onRetry: onRetry,
        completeLabel: completeLabel,
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

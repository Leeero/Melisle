import 'package:cross_platform_music_player/presentation/widgets/layout/app_page_layout.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

enum AppSnackBarTone { confirmation, error, info }

/// 统一的 SnackBar 反馈。
///
/// 使用场景：收藏、添加队列、下载等成功操作后给出轻量确认。
/// 所有样式通过与 [SnackBarTheme] 保持一致来自定义。
class AppSnackBar {
  AppSnackBar._();

  /// 显示一条成功消息。
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    AppSnackBarTone tone = AppSnackBarTone.confirmation,
  }) {
    assert(actionLabel == null || onAction != null);
    final horizontalMargin = AppPageLayout.horizontalPadding(context);
    final compact = AppBreakpoints.isCompact(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        compact
            ? _mobileSnackBar(
                context,
                message,
                tone: tone,
                actionLabel: actionLabel,
                onAction: onAction,
                horizontalMargin: horizontalMargin,
              )
            : SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacingTokens.cardPadding,
                  vertical: AppSpacingTokens.buttonPaddingV,
                ),
                margin: EdgeInsets.fromLTRB(
                  horizontalMargin,
                  0,
                  horizontalMargin,
                  AppSpacingTokens.snackbarMargin,
                ),
                action: actionLabel == null
                    ? null
                    : SnackBarAction(label: actionLabel, onPressed: onAction!),
              ),
      );
  }

  static SnackBar _mobileSnackBar(
    BuildContext context,
    String message, {
    required AppSnackBarTone tone,
    required String? actionLabel,
    required VoidCallback? onAction,
    required double horizontalMargin,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isError = tone == AppSnackBarTone.error;
    final accent = isError ? colors.error : colors.primary;
    final surface = Color.alphaBlend(
      accent.withValues(alpha: isError ? 0.08 : 0.05),
      colors.surfaceContainerHighest,
    );
    final icon = switch (tone) {
      AppSnackBarTone.confirmation => Icons.check_circle_rounded,
      AppSnackBarTone.error => Icons.error_rounded,
      AppSnackBarTone.info => Icons.info_rounded,
    };

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      duration: Duration(seconds: actionLabel == null ? 2 : 4),
      dismissDirection: DismissDirection.horizontal,
      margin: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 12),
      content: Semantics(
        liveRegion: true,
        label: message,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
            border: Border.all(
              color: accent.withValues(alpha: isError ? 0.24 : 0.14),
            ),
            boxShadow: AppShadowTokens.card,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction?.call();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: accent,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

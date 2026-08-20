import 'package:flutter/material.dart';

import 'package:cross_platform_music_player/shared/theme/theme.dart';

enum AppModalTone { neutral, danger }

class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacingTokens.pageHorizontalCompact,
      AppSpacingTokens.contentGap,
      AppSpacingTokens.pageHorizontalCompact,
      AppSpacingTokens.sectionPadding,
    ),
  });

  final String title;
  final String? description;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final sheetRadius = compact
        ? AppRadiusTokens.mobileXl
        : AppRadiusTokens.coverDetail;

    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: compact ? 0.96 : 1),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.36),
            ),
          ),
          boxShadow: compact
              ? [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.14),
                    blurRadius: 48,
                    offset: const Offset(0, -18),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _AppSheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style:
                                (compact
                                        ? theme.textTheme.titleMedium
                                        : theme.textTheme.titleLarge)
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppSheetHandle extends StatelessWidget {
  const _AppSheetHandle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class AppOptionTile<T> extends StatefulWidget {
  const AppOptionTile({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onSelected,
    this.subtitle,
    this.icon,
    this.trailing,
    this.showRadio = true,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final T value;
  final T groupValue;
  final ValueChanged<T> onSelected;
  final bool showRadio;
  final bool enabled;

  @override
  State<AppOptionTile<T>> createState() => _AppOptionTileState<T>();
}

class _AppOptionTileState<T> extends State<AppOptionTile<T>> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = widget.value == widget.groupValue;
    final interactive = widget.enabled;
    final foregroundColor = widget.enabled
        ? selected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
    final secondaryColor = widget.enabled
        ? theme.muted
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
    final backgroundColor = selected
        ? theme.selectedWash
        : _pressed && interactive
        ? theme.hoverWash
        : (_hovered || _focused) && interactive
        ? theme.hoverWash
        : Colors.transparent;
    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: _focused ? 0.24 : 0.0)
        : colorScheme.outlineVariant.withValues(
            alpha: _focused && interactive ? 0.28 : 0.0,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enabled) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (!mounted) return;
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        },
        child: Semantics(
          selected: selected,
          button: true,
          enabled: widget.enabled,
          child: AnimatedContainer(
            duration: AppMotion.micro,
            curve: AppMotion.enter,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadiusTokens.card),
              border: Border.all(color: borderColor),
            ),
            constraints: const BoxConstraints(minHeight: 48),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.card),
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              onHover: widget.enabled
                  ? (hovered) => setState(() => _hovered = hovered)
                  : null,
              onFocusChange: widget.enabled
                  ? (focused) => setState(() => _focused = focused)
                  : null,
              onHighlightChanged: widget.enabled
                  ? (pressed) => setState(() => _pressed = pressed)
                  : null,
              onTap: widget.enabled
                  ? () => widget.onSelected(widget.value)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacingTokens.contentGap,
                  vertical: AppSpacingTokens.listTileVPadding,
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 20,
                        color: !widget.enabled
                            ? secondaryColor
                            : selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: foregroundColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    widget.trailing ??
                        (widget.showRadio
                            ? Radio<T>(value: widget.value)
                            : Icon(
                                selected
                                    ? Icons.check_rounded
                                    : Icons.chevron_right_rounded,
                                color: !widget.enabled
                                    ? secondaryColor
                                    : selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = '取消',
  IconData icon = Icons.info_outline_rounded,
  AppModalTone tone = AppModalTone.neutral,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _AppConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      tone: tone,
    ),
  );
  return result ?? false;
}

class _AppConfirmationDialog extends StatelessWidget {
  const _AppConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final AppModalTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = tone == AppModalTone.danger
        ? colorScheme.error
        : colorScheme.primary;
    final container = tone == AppModalTone.danger
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final onContainer = tone == AppModalTone.danger
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.sectionPadding,
        vertical: AppSpacingTokens.sectionPadding,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacingTokens.buttonPaddingH,
            AppSpacingTokens.buttonPaddingH,
            AppSpacingTokens.buttonPaddingH,
            AppSpacingTokens.contentGap + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: container.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadiusTokens.card),
                    ),
                    child: Icon(icon, size: 20, color: onContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

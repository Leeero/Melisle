import 'package:flutter/material.dart';

enum PlayAllButtonVariant { primary, compact, iconOnly }

class PlayAllButton extends StatelessWidget {
  const PlayAllButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.variant = PlayAllButtonVariant.compact,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final PlayAllButtonVariant variant;

  static const _label = '播放全部';

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return switch (variant) {
      PlayAllButtonVariant.primary => FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: _PlayAllButtonIcon(isLoading: isLoading, highContrast: true),
        label: const Text(_label),
      ),
      PlayAllButtonVariant.compact => TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: _PlayAllButtonIcon(isLoading: isLoading),
        label: const Text(_label),
      ),
      PlayAllButtonVariant.iconOnly => Semantics(
        label: _label,
        button: true,
        enabled: enabled,
        child: Tooltip(
          message: _label,
          child: SizedBox.square(
            dimension: 48,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: _PlayAllButtonIcon(
                isLoading: isLoading,
                highContrast: true,
              ),
            ),
          ),
        ),
      ),
    };
  }
}

class _PlayAllButtonIcon extends StatelessWidget {
  const _PlayAllButtonIcon({this.isLoading = false, this.highContrast = false});

  final bool isLoading;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const Icon(Icons.play_arrow_rounded);
    }

    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: highContrast ? colorScheme.onPrimary : colorScheme.primary,
      ),
    );
  }
}

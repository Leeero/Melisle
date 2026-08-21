import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:flutter/material.dart';

enum PlayAllButtonVariant { primary, compact, iconOnly }

class PlayAllButton extends StatelessWidget {
  const PlayAllButton({
    super.key,
    required this.onPressed,
    this.onShufflePressed,
    this.isLoading = false,
    this.variant = PlayAllButtonVariant.compact,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onShufflePressed;
  final bool isLoading;
  final PlayAllButtonVariant variant;

  static const _label = '播放全部';
  static const _shuffleLabel = '随机播放';

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final shuffleEnabled = onShufflePressed != null && !isLoading;

    final playButton = switch (variant) {
      PlayAllButtonVariant.primary => _PlayAllTextButton(
        onPressed: enabled ? onPressed : null,
        icon: _PlayAllButtonIcon(isLoading: isLoading, highContrast: true),
        label: _label,
        tone: AppActionButtonTone.primary,
      ),
      PlayAllButtonVariant.compact => _PlayAllTextButton(
        onPressed: enabled ? onPressed : null,
        icon: _PlayAllButtonIcon(isLoading: isLoading),
        label: _label,
        tone: AppActionButtonTone.primary,
        dense: true,
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

    if (onShufflePressed == null) {
      return playButton;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        playButton,
        const SizedBox(width: 8),
        _ShuffleAllButton(
          onPressed: shuffleEnabled ? onShufflePressed : null,
          variant: variant,
        ),
      ],
    );
  }
}

class _ShuffleAllButton extends StatelessWidget {
  const _ShuffleAllButton({required this.onPressed, required this.variant});

  final VoidCallback? onPressed;
  final PlayAllButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final icon = const Icon(Icons.shuffle_rounded, size: 20);

    return switch (variant) {
      PlayAllButtonVariant.primary => _PlayAllTextButton(
        onPressed: onPressed,
        icon: icon,
        label: PlayAllButton._shuffleLabel,
        tone: AppActionButtonTone.secondary,
      ),
      PlayAllButtonVariant.compact => _PlayAllTextButton(
        onPressed: onPressed,
        icon: icon,
        label: PlayAllButton._shuffleLabel,
        tone: AppActionButtonTone.secondary,
        dense: true,
      ),
      PlayAllButtonVariant.iconOnly => Semantics(
        label: PlayAllButton._shuffleLabel,
        button: true,
        enabled: onPressed != null,
        child: Tooltip(
          message: PlayAllButton._shuffleLabel,
          child: SizedBox.square(
            dimension: 48,
            child: IconButton(
              onPressed: onPressed,
              style: AppActionButtonStyle.icon(
                context,
                tone: AppActionButtonTone.secondary,
                size: 48,
              ),
              icon: icon,
            ),
          ),
        ),
      ),
    };
  }
}

class _PlayAllTextButton extends StatelessWidget {
  const _PlayAllTextButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.tone,
    this.dense = false,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final AppActionButtonTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: AppActionButtonStyle.text(context, tone: tone, dense: dense),
      ),
    );
  }
}

class _PlayAllButtonIcon extends StatelessWidget {
  const _PlayAllButtonIcon({this.isLoading = false, this.highContrast = false});

  final bool isLoading;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const Icon(Icons.play_arrow_rounded, size: 20);
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

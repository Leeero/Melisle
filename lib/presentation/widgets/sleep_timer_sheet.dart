import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 睡眠定时器底部表。提供常用预设和"本曲结束"模式。
class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PlayerCubit>(),
        child: const SleepTimerSheet(),
      ),
    );
  }

  static const _presets = <Duration>[
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BlocBuilder<PlayerCubit, PlayerViewState>(
        builder: (context, state) {
          final cubit = context.read<PlayerCubit>();
          final remaining = state.sleepRemaining;
          final active = remaining != null || state.sleepEndOfTrack;

          return AppSheetScaffold(
            title: '睡眠定时',
            description: active ? '当前定时已开启。' : '选择一个暂停时间。',
            trailing: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('完成'),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SleepTimerStatusCard(
                  remaining: remaining,
                  endOfTrack: state.sleepEndOfTrack,
                ),
                const SizedBox(height: 18),
                const _SleepTimerSectionLabel('选择时长'),
                const SizedBox(height: 10),
                _SleepTimerPresetGrid(
                  presets: _presets,
                  remaining: remaining,
                  onSelected: (preset) async {
                    await cubit.startSleepTimer(preset);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 12),
                _SleepTimerOptionRow(
                  icon: Icons.skip_next_rounded,
                  title: '本曲结束后暂停',
                  subtitle: '播放完当前歌曲后停止',
                  selected: state.sleepEndOfTrack,
                  trailingStyle: _SleepTimerOptionTrailingStyle.switcher,
                  onTap: () async {
                    await cubit.startSleepTimerEndOfTrack();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
                if (active) ...[
                  const SizedBox(height: 8),
                  _SleepTimerOptionRow(
                    icon: Icons.alarm_off_rounded,
                    title: '取消睡眠定时',
                    subtitle: '恢复连续播放',
                    danger: true,
                    trailingStyle: _SleepTimerOptionTrailingStyle.close,
                    onTap: () async {
                      await cubit.cancelSleepTimer();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatRemaining(Duration d) {
    final total = d.inSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _SleepTimerStatusCard extends StatelessWidget {
  const _SleepTimerStatusCard({
    required this.remaining,
    required this.endOfTrack,
  });

  final Duration? remaining;
  final bool endOfTrack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = remaining != null || endOfTrack;
    final title = endOfTrack
        ? '本曲结束后暂停'
        : remaining != null
        ? '剩余 ${SleepTimerSheet._formatRemaining(remaining!)}'
        : '未开启';
    final subtitle = endOfTrack
        ? '不会自动进入下一首。'
        : remaining != null
        ? '倒计时结束后自动暂停。'
        : '轻触下方时间即可开启。';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? theme.selectedWash.withValues(alpha: 0.84)
            : theme.hoverWash.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
        border: Border.all(
          color: active
              ? colorScheme.primary.withValues(alpha: 0.18)
              : colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: active
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
              ),
              child: Icon(
                active ? Icons.bedtime_rounded : Icons.timer_rounded,
                color: active ? colorScheme.primary : theme.muted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: active
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimerSectionLabel extends StatelessWidget {
  const _SleepTimerSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SleepTimerPresetGrid extends StatelessWidget {
  const _SleepTimerPresetGrid({
    required this.presets,
    required this.remaining,
    required this.onSelected,
  });

  final List<Duration> presets;
  final Duration? remaining;
  final ValueChanged<Duration> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.hoverWash.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg + 2),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 330 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: presets.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: columns == 3 ? 2.32 : 2.7,
              ),
              itemBuilder: (context, index) {
                final preset = presets[index];
                return _SleepTimerPresetButton(
                  duration: preset,
                  selected: _isPresetSelected(preset, remaining),
                  onTap: () => onSelected(preset),
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _isPresetSelected(Duration preset, Duration? remaining) {
    if (remaining == null) return false;
    final difference = preset.inSeconds - remaining.inSeconds;
    return difference >= 0 && difference < 60;
  }
}

class _SleepTimerPresetButton extends StatefulWidget {
  const _SleepTimerPresetButton({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  final Duration duration;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SleepTimerPresetButton> createState() =>
      _SleepTimerPresetButtonState();
}

class _SleepTimerPresetButtonState extends State<_SleepTimerPresetButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
      label: '${widget.duration.inMinutes} 分钟后暂停播放',
      child: AnimatedScale(
        duration: AppMotion.micro,
        curve: AppMotion.enter,
        scale: _pressed ? 0.98 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
            onTap: widget.onTap,
            mouseCursor: SystemMouseCursors.click,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashColor: colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: selected
                    ? theme.selectedWash.withValues(alpha: 0.86)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  '${widget.duration.inMinutes} 分钟',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepTimerOptionRow extends StatefulWidget {
  const _SleepTimerOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.danger = false,
    this.trailingStyle = _SleepTimerOptionTrailingStyle.chevron,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;
  final _SleepTimerOptionTrailingStyle trailingStyle;

  @override
  State<_SleepTimerOptionRow> createState() => _SleepTimerOptionRowState();
}

class _SleepTimerOptionRowState extends State<_SleepTimerOptionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = widget.danger ? colorScheme.error : colorScheme.primary;
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.title,
      child: AnimatedContainer(
        duration: AppMotion.micro,
        curve: AppMotion.enter,
        decoration: BoxDecoration(
          color: selected
              ? theme.selectedWash.withValues(alpha: 0.78)
              : _pressed
              ? theme.hoverWash
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : colorScheme.outlineVariant.withValues(alpha: 0.36),
          ),
        ),
        constraints: const BoxConstraints(minHeight: 56),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
            onTap: widget.onTap,
            mouseCursor: SystemMouseCursors.click,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.contentGap,
                vertical: AppSpacingTokens.listTileVPadding,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 21, color: accent),
                  const SizedBox(width: AppSpacingTokens.contentGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: widget.danger
                                ? colorScheme.error
                                : selected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SleepTimerOptionTrailing(
                    selected: selected,
                    danger: widget.danger,
                    style: widget.trailingStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _SleepTimerOptionTrailingStyle { chevron, switcher, close }

class _SleepTimerOptionTrailing extends StatelessWidget {
  const _SleepTimerOptionTrailing({
    required this.selected,
    required this.danger,
    required this.style,
  });

  final bool selected;
  final bool danger;
  final _SleepTimerOptionTrailingStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = danger ? colorScheme.error : colorScheme.primary;

    return switch (style) {
      _SleepTimerOptionTrailingStyle.switcher => AnimatedContainer(
        duration: AppMotion.micro,
        curve: AppMotion.enter,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: selected ? Alignment.centerRight : Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const SizedBox(width: 22, height: 22),
        ),
      ),
      _SleepTimerOptionTrailingStyle.close => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, size: 17, color: accent),
      ),
      _ => Icon(
        selected ? Icons.check_rounded : Icons.chevron_right_rounded,
        size: 20,
        color: selected ? accent : theme.muted,
      ),
    };
  }
}

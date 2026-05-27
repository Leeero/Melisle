import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: BlocBuilder<PlayerCubit, PlayerViewState>(
          builder: (context, state) {
            final cubit = context.read<PlayerCubit>();
            final remaining = state.sleepRemaining;
            final active = remaining != null || state.sleepEndOfTrack;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '睡眠定时',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  active
                      ? (state.sleepEndOfTrack
                            ? '将在本曲结束后自动暂停'
                            : '剩余 ${_formatRemaining(remaining!)}')
                      : '时间到后将自动暂停播放',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final preset in _presets)
                      FilledButton.tonal(
                        onPressed: () async {
                          await cubit.startSleepTimer(preset);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Text('${preset.inMinutes} 分钟'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await cubit.startSleepTimerEndOfTrack();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('本曲结束后'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (active)
                  TextButton.icon(
                    onPressed: () async {
                      await cubit.cancelSleepTimer();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.alarm_off_rounded),
                    label: const Text('取消睡眠定时'),
                  ),
              ],
            );
          },
        ),
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

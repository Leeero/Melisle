import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
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
            description: active
                ? (state.sleepEndOfTrack
                      ? '将在本曲结束后自动暂停'
                      : '剩余 ${_formatRemaining(remaining!)}')
                : '时间到后将自动暂停播放。',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final preset in _presets)
                      AppActionButton(
                        icon: Icons.timer_rounded,
                        label: '${preset.inMinutes} 分钟',
                        tone: AppActionButtonTone.primary,
                        dense: false,
                        onPressed: () async {
                          await cubit.startSleepTimer(preset);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    AppActionButton(
                      icon: Icons.skip_next_rounded,
                      label: '本曲结束后',
                      dense: false,
                      onPressed: () async {
                        await cubit.startSleepTimerEndOfTrack();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                if (active) ...[
                  const SizedBox(height: 14),
                  AppActionButton(
                    icon: Icons.alarm_off_rounded,
                    label: '取消睡眠定时',
                    tone: AppActionButtonTone.danger,
                    dense: false,
                    onPressed: () async {
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

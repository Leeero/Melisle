import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 音质选择底部表。
class QualityPickerSheet extends StatelessWidget {
  const QualityPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PlayerCubit>(),
        child: const QualityPickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      builder: (context, state) {
        final cubit = context.read<PlayerCubit>();
        return AppSheetScaffold(
          title: '播放音质',
          description: '下一首起生效；无损仅在源文件为无损时生效。',
          trailing: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
          child: RadioGroup<AudioQuality>(
            groupValue: state.quality,
            onChanged: (value) async {
              if (value == null) return;
              await cubit.setQuality(value);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final q in AudioQuality.values)
                  AppOptionTile<AudioQuality>(
                    title: q.label,
                    subtitle: _qualityDescription(q),
                    icon: Icons.high_quality_rounded,
                    value: q,
                    groupValue: state.quality,
                    onSelected: (value) async {
                      await cubit.setQuality(value);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _qualityDescription(AudioQuality quality) {
  return switch (quality) {
    AudioQuality.auto => '直接播放源文件，不转码。',
    AudioQuality.lossless => '尽量保留源文件质量。',
    AudioQuality.high => '优先使用较高码率。',
    AudioQuality.medium => '平衡流量与听感。',
    AudioQuality.low => '较低带宽占用，适合移动网络。',
  };
}

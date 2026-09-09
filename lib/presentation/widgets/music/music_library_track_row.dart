import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/mobile_track_row.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class MusicLibraryTrackRow extends StatelessWidget {
  const MusicLibraryTrackRow({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onMore,
    this.onLongPress,
  });

  final MusicTrack track;
  final int index;
  final bool isCurrent;
  final Future<void> Function() onTap;
  final VoidCallback onMore;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      MediaDisplayText.artistName(track.artistName),
      MediaDisplayText.albumTitle(track.albumTitle),
    ].where((item) => item.isNotEmpty).join(' · ');

    return MobileTrackRow(
      title: MediaDisplayText.trackTitle(track.title),
      subtitle: subtitle,
      selected: isCurrent,
      onTap: onTap,
      onLongPress: onLongPress,
      artworkUrl: track.artworkUrl,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(track.duration),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.mobileTheme.onSurfaceVariant,
              fontSize: AppTypographyTokens.mobileTime,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox.square(
            dimension: 48,
            child: IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              tooltip: '更多操作',
              padding: EdgeInsets.zero,
              style: AppActionButtonStyle.icon(context),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  if (duration <= Duration.zero) return '--:--';
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

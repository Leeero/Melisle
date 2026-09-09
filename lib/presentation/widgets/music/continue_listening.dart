import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class ContinueListening extends StatelessWidget {
  const ContinueListening({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.progress,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onOpen,
    required this.onTogglePlayback,
    this.artwork,
  });

  final String title;
  final String subtitle;
  final String artworkUrl;
  final double progress;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onOpen;
  final VoidCallback onTogglePlayback;
  final Widget? artwork;

  @override
  Widget build(BuildContext context) {
    final colors = context.mobileTheme;
    final normalizedProgress = progress.clamp(0.0, 1.0);

    return Semantics(
      container: true,
      label: '继续聆听：$title，$subtitle',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadiusTokens.mobileLg),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                artwork ??
                    CachedArtwork(
                      imageUrl: artworkUrl,
                      size: 72,
                      borderRadius: AppRadiusTokens.mobileMd,
                      semanticLabel: '《$title》封面',
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '继续聆听',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.brass,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          value: normalizedProgress,
                          color: colors.primary,
                          backgroundColor: colors.outlineVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDuration(position),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _formatDuration(duration),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: isPlaying ? '暂停' : '继续播放',
                  child: SizedBox.square(
                    dimension: 48,
                    child: IconButton.filled(
                      onPressed: onTogglePlayback,
                      color: colors.surface,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.primary,
                      ),
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final safeSeconds = value.inSeconds.clamp(0, 359999);
  final minutes = safeSeconds ~/ 60;
  final seconds = safeSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

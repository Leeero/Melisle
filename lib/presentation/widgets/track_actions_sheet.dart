import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/utils/media_display_text.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// 弹出一个通用的曲目操作底部表。菜单项：
///   - 查看专辑（若有 albumId）
///   - 查看艺术家（若有 artistId）
///   - 添加到当前队列
///   - 收藏 / 取消收藏
Future<void> showTrackActionsSheet(BuildContext context, MusicTrack track) {
  if (AppBreakpoints.usesDesktopShell(context)) {
    return _showTrackActionsPopover(context, track);
  }

  final title = MediaDisplayText.trackTitle(track.title);
  final artist = MediaDisplayText.artistName(track.artistName);
  final album = MediaDisplayText.albumTitle(track.albumTitle);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return AppSheetScaffold(
        title: title,
        description: '$artist · $album',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (track.albumId != null && track.albumId!.isNotEmpty)
              AppOptionTile<_TrackAction>(
                title: '查看专辑',
                icon: Icons.album_rounded,
                value: _TrackAction.album,
                groupValue: _TrackAction.none,
                showRadio: false,
                onSelected: (_) {
                  Navigator.of(sheetCtx).pop();
                  context.push('/album/${track.albumId}');
                },
              ),
            if (track.artistId != null && track.artistId!.isNotEmpty)
              AppOptionTile<_TrackAction>(
                title: '查看艺术家',
                icon: Icons.person_rounded,
                value: _TrackAction.artist,
                groupValue: _TrackAction.none,
                showRadio: false,
                onSelected: (_) {
                  Navigator.of(sheetCtx).pop();
                  context.push('/artist/${track.artistId}');
                },
              ),
            AppOptionTile<_TrackAction>(
              title: '添加到当前队列',
              icon: Icons.playlist_add_rounded,
              value: _TrackAction.queue,
              groupValue: _TrackAction.none,
              showRadio: false,
              onSelected: (_) async {
                Navigator.of(sheetCtx).pop();
                await context.read<PlayerCubit>().addToQueue(track);
                if (context.mounted) {
                  AppSnackBar.show(context, '已加入队列：$title');
                }
              },
            ),
            BlocBuilder<FavoritesCubit, FavoritesState>(
              buildWhen: (a, b) => a.entries[track.id] != b.entries[track.id],
              builder: (ctx, favState) {
                final isFav = favState.entries[track.id] ?? track.isFavorite;
                return AppOptionTile<_TrackAction>(
                  title: isFav ? '取消收藏' : '收藏',
                  icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  value: _TrackAction.favorite,
                  groupValue: _TrackAction.none,
                  showRadio: false,
                  onSelected: (_) {
                    Navigator.of(sheetCtx).pop();
                    context.read<FavoritesCubit>().toggle(
                      track.id,
                      currentValue: isFav,
                    );
                    if (context.mounted) {
                      AppSnackBar.show(context, isFav ? '已取消收藏' : '已收藏');
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> _showTrackActionsPopover(
  BuildContext context,
  MusicTrack track,
) async {
  final title = MediaDisplayText.trackTitle(track.title);
  final isFavorite = context.read<FavoritesCubit>().isFavorite(
    track.id,
    fallback: track.isFavorite,
  );
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final trigger = context.findRenderObject() as RenderBox?;
  final triggerPosition = trigger?.localToGlobal(
    Offset(trigger.size.width, trigger.size.height / 2),
    ancestor: overlay,
  );
  final selected = await showMenu<_TrackAction>(
    context: context,
    position: RelativeRect.fromRect(
      triggerPosition == null
          ? Rect.fromCenter(
              center: overlay.size.center(Offset.zero),
              width: 1,
              height: 1,
            )
          : Rect.fromCenter(center: triggerPosition, width: 1, height: 1),
      Offset.zero & overlay.size,
    ),
    items: [
      const PopupMenuItem(
        value: _TrackAction.queue,
        child: _TrackActionMenuItem(
          icon: Icons.playlist_add_rounded,
          label: '添加到当前队列',
        ),
      ),
      if (track.albumId?.isNotEmpty ?? false)
        const PopupMenuItem(
          value: _TrackAction.album,
          child: _TrackActionMenuItem(icon: Icons.album_rounded, label: '查看专辑'),
        ),
      if (track.artistId?.isNotEmpty ?? false)
        const PopupMenuItem(
          value: _TrackAction.artist,
          child: _TrackActionMenuItem(
            icon: Icons.person_rounded,
            label: '查看艺术家',
          ),
        ),
      PopupMenuItem(
        value: _TrackAction.favorite,
        child: _TrackActionMenuItem(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: isFavorite ? '取消收藏' : '收藏',
        ),
      ),
    ],
  );
  if (!context.mounted || selected == null) return;

  switch (selected) {
    case _TrackAction.album:
      context.push('/album/${track.albumId}');
    case _TrackAction.artist:
      context.push('/artist/${track.artistId}');
    case _TrackAction.queue:
      await context.read<PlayerCubit>().addToQueue(track);
      if (context.mounted) AppSnackBar.show(context, '已加入队列：$title');
    case _TrackAction.favorite:
      context.read<FavoritesCubit>().toggle(track.id, currentValue: isFavorite);
      AppSnackBar.show(context, isFavorite ? '已取消收藏' : '已收藏');
    case _TrackAction.none:
      break;
  }
}

class _TrackActionMenuItem extends StatelessWidget {
  const _TrackActionMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
    );
  }
}

enum _TrackAction { none, album, artist, queue, favorite }

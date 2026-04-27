import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// 弹出一个通用的曲目操作底部表。菜单项：
///   - 查看专辑（若有 albumId）
///   - 查看艺术家（若有 artistId）
///   - 添加到当前队列
///   - 收藏 / 取消收藏
Future<void> showTrackActionsSheet(BuildContext context, MusicTrack track) {
  final colorScheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colorScheme.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title.isEmpty ? '未知歌曲' : track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(sheetCtx).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${track.artistName} · ${track.albumTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(sheetCtx).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (track.albumId != null && track.albumId!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.album_rounded),
                title: const Text('查看专辑'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/album/${track.albumId}');
                },
              ),
            if (track.artistId != null && track.artistId!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: const Text('查看艺术家'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/artist/${track.artistId}');
                },
              ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('添加到当前队列'),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                await context.read<PlayerCubit>().addToQueue(track);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已加入队列：${track.title}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            BlocBuilder<FavoritesCubit, FavoritesState>(
              buildWhen: (a, b) => a.entries[track.id] != b.entries[track.id],
              builder: (ctx, favState) {
                final isFav = favState.entries[track.id] ?? track.isFavorite;
                return ListTile(
                  leading: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? colorScheme.primary : null,
                  ),
                  title: Text(isFav ? '取消收藏' : '收藏'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    context.read<FavoritesCubit>().toggle(
                      track.id,
                      currentValue: isFav,
                    );
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

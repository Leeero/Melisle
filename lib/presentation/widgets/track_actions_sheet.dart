import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// 弹出一个通用的曲目操作底部表。菜单项：
///   - 查看专辑（若有 albumId）
///   - 查看艺术家（若有 artistId）
///   - 添加到当前队列
///   - 收藏 / 取消收藏
Future<void> showTrackActionsSheet(BuildContext context, MusicTrack track) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return AppSheetScaffold(
        title: track.title.isEmpty ? '未知歌曲' : track.title,
        description: [
          track.artistName,
          track.albumTitle,
        ].where((value) => value.isNotEmpty).join(' · '),
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

enum _TrackAction { none, album, artist, queue, favorite }

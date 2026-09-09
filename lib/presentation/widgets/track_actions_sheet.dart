import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
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
///   - 查看歌手（若有 artistId）
///   - 添加到当前队列
///   - 下载 / 显示下载状态
///   - 收藏 / 取消收藏
enum TrackActionsPopoverStyle { standard, recentPlayback }

enum TrackActionsContext { generic, album, artist, playlist }

Future<void> showTrackActionsSheet(
  BuildContext context,
  MusicTrack track, {
  TrackActionsPopoverStyle popoverStyle = TrackActionsPopoverStyle.standard,
  TrackActionsContext source = TrackActionsContext.generic,
}) async {
  if (AppBreakpoints.usesDesktopShell(context)) {
    return _showTrackActionsPopover(context, track, popoverStyle, source);
  }

  final title = MediaDisplayText.trackTitle(track.title);
  final artist = MediaDisplayText.artistName(track.artistName);
  final album = MediaDisplayText.albumTitle(track.albumTitle);
  final selected = await showModalBottomSheet<_TrackAction>(
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
            if (source != TrackActionsContext.album &&
                source != TrackActionsContext.playlist &&
                track.albumId != null &&
                track.albumId!.isNotEmpty)
              AppOptionTile<_TrackAction>(
                title: '查看专辑',
                icon: Icons.album_rounded,
                value: _TrackAction.album,
                groupValue: _TrackAction.none,
                showRadio: false,
                onSelected: (_) {
                  Navigator.of(sheetCtx).pop(_TrackAction.album);
                },
              ),
            if (source != TrackActionsContext.artist &&
                track.artistId != null &&
                track.artistId!.isNotEmpty)
              AppOptionTile<_TrackAction>(
                title: '查看歌手',
                icon: Icons.person_rounded,
                value: _TrackAction.artist,
                groupValue: _TrackAction.none,
                showRadio: false,
                onSelected: (_) {
                  Navigator.of(sheetCtx).pop(_TrackAction.artist);
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
            BlocBuilder<DownloadsCubit, DownloadsState>(
              buildWhen: (previous, current) =>
                  previous.completedTrackIds.contains(track.id) !=
                      current.completedTrackIds.contains(track.id) ||
                  previous.jobs[track.id]?.status !=
                      current.jobs[track.id]?.status,
              builder: (ctx, downloadsState) {
                final isDownloaded = downloadsState.completedTrackIds.contains(
                  track.id,
                );
                final isDownloading = downloadsState.jobs.containsKey(track.id);
                return AppOptionTile<_TrackAction>(
                  title: isDownloaded
                      ? '已下载'
                      : isDownloading
                      ? '下载中'
                      : '下载',
                  icon: isDownloaded
                      ? Icons.download_done_rounded
                      : isDownloading
                      ? Icons.downloading_rounded
                      : Icons.download_rounded,
                  value: _TrackAction.download,
                  groupValue: _TrackAction.none,
                  showRadio: false,
                  enabled: !isDownloaded && !isDownloading,
                  onSelected: (_) async {
                    Navigator.of(sheetCtx).pop();
                    await context.read<DownloadsCubit>().enqueue(track);
                    if (context.mounted) {
                      AppSnackBar.show(context, '已加入下载队列：$title');
                    }
                  },
                );
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

  if (!context.mounted || selected == null) return;
  switch (selected) {
    case _TrackAction.album:
      context.push('/album/${track.albumId}');
    case _TrackAction.artist:
      context.push('/artist/${track.artistId}');
    case _TrackAction.none:
    case _TrackAction.queue:
    case _TrackAction.download:
    case _TrackAction.favorite:
      break;
  }
}

Future<void> _showTrackActionsPopover(
  BuildContext context,
  MusicTrack track,
  TrackActionsPopoverStyle style,
  TrackActionsContext source,
) async {
  final title = MediaDisplayText.trackTitle(track.title);
  final isFavorite = context.read<FavoritesCubit>().isFavorite(
    track.id,
    fallback: track.isFavorite,
  );
  final downloadsState = context.read<DownloadsCubit>().state;
  final isDownloaded = downloadsState.completedTrackIds.contains(track.id);
  final isDownloading = downloadsState.jobs.containsKey(track.id);
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final trigger = context.findRenderObject() as RenderBox?;
  final triggerRect = trigger == null
      ? null
      : trigger.localToGlobal(Offset.zero, ancestor: overlay) & trigger.size;
  final usesRecentPlaybackStyle =
      style == TrackActionsPopoverStyle.recentPlayback;
  final itemSpacing = usesRecentPlaybackStyle ? 12.0 : 8.0;
  final fallbackAnchor = Rect.fromCenter(
    center: overlay.size.center(Offset.zero),
    width: 1,
    height: 1,
  );
  final menuAnchor = triggerRect == null
      ? fallbackAnchor
      : usesRecentPlaybackStyle
      ? Rect.fromLTRB(
          triggerRect.left,
          triggerRect.bottom + 4,
          triggerRect.right,
          triggerRect.bottom + 4,
        )
      : Rect.fromCenter(
          center: Offset(triggerRect.right, triggerRect.center.dy),
          width: 1,
          height: 1,
        );
  final selected = await showMenu<_TrackAction>(
    context: context,
    position: RelativeRect.fromRect(menuAnchor, Offset.zero & overlay.size),
    color: usesRecentPlaybackStyle
        ? Theme.of(context).colorScheme.surface
        : null,
    surfaceTintColor: Colors.transparent,
    elevation: usesRecentPlaybackStyle ? 3 : null,
    shadowColor: usesRecentPlaybackStyle
        ? Colors.black.withValues(alpha: 0.12)
        : null,
    shape: usesRecentPlaybackStyle
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.md),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          )
        : null,
    constraints: usesRecentPlaybackStyle
        ? const BoxConstraints.tightFor(width: 160)
        : null,
    menuPadding: usesRecentPlaybackStyle
        ? const EdgeInsets.symmetric(vertical: 8)
        : null,
    items: [
      PopupMenuItem(
        value: _TrackAction.queue,
        mouseCursor: SystemMouseCursors.click,
        height: usesRecentPlaybackStyle ? 42 : kMinInteractiveDimension,
        padding: usesRecentPlaybackStyle
            ? const EdgeInsets.symmetric(horizontal: 8)
            : null,
        child: _TrackActionMenuItem(
          icon: Icons.playlist_add_rounded,
          label: '添加到当前队列',
          spacing: itemSpacing,
        ),
      ),
      PopupMenuItem(
        value: _TrackAction.download,
        enabled: !isDownloaded && !isDownloading,
        mouseCursor: SystemMouseCursors.click,
        height: usesRecentPlaybackStyle ? 42 : kMinInteractiveDimension,
        padding: usesRecentPlaybackStyle
            ? const EdgeInsets.symmetric(horizontal: 8)
            : null,
        child: _TrackActionMenuItem(
          icon: isDownloaded
              ? Icons.download_done_rounded
              : isDownloading
              ? Icons.downloading_rounded
              : Icons.download_rounded,
          label: isDownloaded
              ? '已下载'
              : isDownloading
              ? '下载中'
              : '下载',
          spacing: itemSpacing,
        ),
      ),
      if (source != TrackActionsContext.album &&
          source != TrackActionsContext.playlist &&
          (track.albumId?.isNotEmpty ?? false))
        PopupMenuItem(
          value: _TrackAction.album,
          mouseCursor: SystemMouseCursors.click,
          height: usesRecentPlaybackStyle ? 42 : kMinInteractiveDimension,
          padding: usesRecentPlaybackStyle
              ? const EdgeInsets.symmetric(horizontal: 8)
              : null,
          child: _TrackActionMenuItem(
            icon: Icons.album_rounded,
            label: '查看专辑',
            spacing: itemSpacing,
          ),
        ),
      if (source != TrackActionsContext.artist &&
          (track.artistId?.isNotEmpty ?? false))
        PopupMenuItem(
          value: _TrackAction.artist,
          mouseCursor: SystemMouseCursors.click,
          height: usesRecentPlaybackStyle ? 42 : kMinInteractiveDimension,
          padding: usesRecentPlaybackStyle
              ? const EdgeInsets.symmetric(horizontal: 8)
              : null,
          child: _TrackActionMenuItem(
            icon: Icons.person_rounded,
            label: '查看歌手',
            spacing: itemSpacing,
          ),
        ),
      PopupMenuItem(
        value: _TrackAction.favorite,
        mouseCursor: SystemMouseCursors.click,
        height: usesRecentPlaybackStyle ? 42 : kMinInteractiveDimension,
        padding: usesRecentPlaybackStyle
            ? const EdgeInsets.symmetric(horizontal: 8)
            : null,
        child: _TrackActionMenuItem(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: isFavorite ? '取消收藏' : '收藏',
          spacing: itemSpacing,
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
    case _TrackAction.download:
      await context.read<DownloadsCubit>().enqueue(track);
      if (context.mounted) AppSnackBar.show(context, '已加入下载队列：$title');
    case _TrackAction.favorite:
      context.read<FavoritesCubit>().toggle(track.id, currentValue: isFavorite);
      AppSnackBar.show(context, isFavorite ? '已取消收藏' : '已收藏');
    case _TrackAction.none:
      break;
  }
}

class _TrackActionMenuItem extends StatelessWidget {
  const _TrackActionMenuItem({
    required this.icon,
    required this.label,
    this.spacing = 8,
  });

  final IconData icon;
  final String label;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 20, child: Center(child: Icon(icon, size: 20))),
        SizedBox(width: spacing),
        Text(label),
      ],
    );
  }
}

enum _TrackAction { none, album, artist, queue, download, favorite }

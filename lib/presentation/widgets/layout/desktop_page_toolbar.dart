import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesktopPageToolbar extends StatelessWidget {
  const DesktopPageToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = GoRouterState.of(context);
    final path = state.uri.path;
    final showsBack = _showsBackButton(path);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
      ),
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (showsBack) ...[
                IconButton(
                  onPressed: () => _goBack(context, path),
                  tooltip: '返回',
                  style: AppActionButtonStyle.icon(context, size: 34),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _pageTitle(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: path == '/search'
                      ? theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        )
                      : theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
              if (path != '/search')
                IconButton(
                  onPressed: () => context.go('/search'),
                  tooltip: '搜索音乐',
                  style: AppActionButtonStyle.icon(
                    context,
                    size: 36,
                    iconSize: 19,
                  ),
                  icon: const Icon(Icons.search_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _pageTitle(String path) {
  if (path == '/home') return '首页';
  if (path == '/search') return '搜索';
  if (path == '/library') return '媒体库';
  if (path == '/favorites') return '收藏';
  if (path == '/history') return '历史';
  if (path.startsWith('/playlists/')) return '播放列表详情';
  if (path == '/playlists') return '播放列表';
  if (path.startsWith('/album/')) return '专辑';
  if (path.startsWith('/artist/')) return '艺术家';
  if (path == '/downloads') return '下载';
  if (path == '/settings/media-sources') return '歌词与封面';
  if (path == '/settings') return '设置';
  return '乐岛';
}

bool _showsBackButton(String path) {
  return path.startsWith('/album/') ||
      path.startsWith('/artist/') ||
      (path.startsWith('/playlists/') && path != '/playlists') ||
      path == '/settings/media-sources';
}

void _goBack(BuildContext context, String path) {
  if (Navigator.of(context).canPop()) {
    context.pop();
    return;
  }

  if (path.startsWith('/playlists/')) {
    context.go('/playlists');
    return;
  }
  if (path == '/settings/media-sources') {
    context.go('/settings');
    return;
  }
  context.go('/library');
}

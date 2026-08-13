import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
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

    if (!showsBack) return const SizedBox.shrink();

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
        key: const ValueKey('shell-toolbar'),
        height: AppSpacingTokens.desktopToolbarHeight,
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
              const Spacer(),
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

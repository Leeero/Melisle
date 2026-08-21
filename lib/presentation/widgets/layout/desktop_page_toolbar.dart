import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesktopPageToolbar extends StatefulWidget {
  const DesktopPageToolbar({super.key});

  @override
  State<DesktopPageToolbar> createState() => _DesktopPageToolbarState();
}

class _DesktopPageToolbarState extends State<DesktopPageToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    final normalized = query.trim();
    final destination = normalized.isEmpty
        ? '/search'
        : Uri(path: '/search', queryParameters: {'q': normalized}).toString();
    if (GoRouterState.of(context).uri.path == '/search') {
      context.go(destination);
      return;
    }
    context.push(destination);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = GoRouter.of(context).canPop();
    final isSettingsPage = GoRouterState.of(context).uri.path == '/settings';

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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacingTokens.buttonPaddingH,
            vertical: 13,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: canGoBack ? () => context.pop() : null,
                mouseCursor: canGoBack
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                tooltip: canGoBack ? '返回上一页' : '没有可返回的页面',
                style: _toolbarBackButtonStyle(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 420,
                child: AppSearchField(
                  controller: _searchController,
                  hintText: '搜索音乐、歌手、专辑、文件夹',
                  semanticLabel: '搜索音乐',
                  dense: true,
                  showCancelAction: false,
                  onSubmitted: _submitSearch,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const ValueKey('shell-toolbar-settings'),
                onPressed: isSettingsPage
                    ? null
                    : () => context.go('/settings'),
                mouseCursor: isSettingsPage
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                tooltip: isSettingsPage ? '当前页面：设置' : '设置',
                style: AppActionButtonStyle.icon(
                  context,
                  selected: isSettingsPage,
                  size: 46,
                  iconSize: 22,
                  radius: AppRadiusTokens.md,
                ),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle _toolbarBackButtonStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return AppActionButtonStyle.icon(
    context,
    size: 46,
    iconSize: 22,
    radius: AppRadiusTokens.md,
  ).copyWith(
    backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
    side: WidgetStatePropertyAll(
      BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.90)),
    ),
  );
}

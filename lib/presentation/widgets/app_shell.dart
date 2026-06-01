import 'dart:io';

import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/widgets/mini_player_bar.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;

    if (AppBreakpoints.usesWideContent(context)) {
      return _DesktopShellScaffold(
        navigationShell: navigationShell,
        selectedIndex: selectedIndex,
        onSelected: _go,
      );
    }

    return _CompactShellScaffold(
      navigationShell: navigationShell,
      selectedIndex: selectedIndex,
      onSelected: _go,
    );
  }

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _DesktopShellScaffold extends StatelessWidget {
  const _DesktopShellScaffold({
    required this.navigationShell,
    required this.selectedIndex,
    required this.onSelected,
  });

  final StatefulNavigationShell navigationShell;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _ShellSidebar(selectedIndex: selectedIndex, onSelected: onSelected),
          Expanded(
            child: _ShellContentSurface(
              body: navigationShell,
              footer: const MiniPlayerBar(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactShellScaffold extends StatelessWidget {
  const _CompactShellScaffold({
    required this.navigationShell,
    required this.selectedIndex,
    required this.onSelected,
  });

  final StatefulNavigationShell navigationShell;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMiniPlayer = context.select<PlayerCubit, bool>(
      (cubit) => cubit.state.currentTrack != null,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: navigationShell,
      bottomNavigationBar: _ShellBottomDock(
        hasMiniPlayer: hasMiniPlayer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: MiniPlayerBar(),
            ),
            SizedBox(height: hasMiniPlayer ? 2 : 0),
            _ShellBottomBar(
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellBottomDock extends StatelessWidget {
  const _ShellBottomDock({required this.child, required this.hasMiniPlayer});

  final Widget child;
  final bool hasMiniPlayer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(top: hasMiniPlayer ? 0 : 5),
        child: child,
      ),
    );
  }
}

class _ShellContentSurface extends StatelessWidget {
  const _ShellContentSurface({required this.body, this.footer});

  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[Expanded(child: body)];
    final footer = this.footer;
    if (footer != null) {
      children.add(footer);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              Theme.of(context).musicTealSoft.withValues(alpha: 0.18),
              Theme.of(context).scaffoldBackgroundColor,
            ),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          stops: const [0, 0.46],
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _ShellSidebar extends StatelessWidget {
  const _ShellSidebar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surfaceSidebar,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.82),
          ),
        ),
      ),
      child: SizedBox(
        width: AppSpacingTokens.desktopSidebarWidth,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, Platform.isMacOS ? 20 : 16, 10, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 10,
                  top: Platform.isMacOS
                      ? AppSpacingTokens.macOsTrafficLightInset
                      : 4,
                  right: 10,
                  bottom: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(
                          AppRadiusTokens.iconButton - 4,
                        ),
                      ),
                      child: Image.asset(
                        'assets/icons/logo.png',
                        fit: BoxFit.contain,
                        semanticLabel: '乐岛图标',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _ShellNavButton(
                icon: Icons.home_rounded,
                label: '首页',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.search_rounded,
                label: '搜索',
                selected: false,
                onTap: () => context.push('/search'),
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.library_music_rounded,
                label: '媒体库',
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              const SizedBox(height: 10),
              const _ShellSectionDivider(),
              const _ShellSectionLabel('资料库'),
              _ShellNavButton(
                icon: Icons.favorite_border_rounded,
                label: '收藏',
                selected: false,
                onTap: () {
                  onSelected(1);
                  context.go('/library');
                },
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.history_rounded,
                label: '最近播放',
                selected: false,
                onTap: () {
                  onSelected(0);
                  context.go('/history');
                },
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.queue_music_rounded,
                label: '歌单',
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              const SizedBox(height: 10),
              const _ShellSectionDivider(),
              const _ShellSectionLabel('管理'),
              _ShellNavButton(
                icon: Icons.download_rounded,
                label: '下载管理',
                selected: false,
                onTap: () {
                  onSelected(3);
                  context.go('/downloads');
                },
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.settings_rounded,
                label: '设置',
                selected: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellSectionLabel extends StatelessWidget {
  const _ShellSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShellSectionDivider extends StatelessWidget {
  const _ShellSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.outlineVariant,
        child: const SizedBox(height: 1),
      ),
    );
  }
}

class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: AppSpacingTokens.mobileTabContentHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _ShellBottomButton(
                  icon: Icons.home_rounded,
                  label: '首页',
                  selected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
              ),
              Expanded(
                child: _ShellBottomButton(
                  icon: Icons.library_music_rounded,
                  label: '媒体库',
                  selected: selectedIndex == 1,
                  onTap: () => onSelected(1),
                ),
              ),
              Expanded(
                child: _ShellBottomButton(
                  icon: Icons.queue_music_rounded,
                  label: '歌单',
                  selected: selectedIndex == 2,
                  onTap: () => onSelected(2),
                ),
              ),
              Expanded(
                child: _ShellBottomButton(
                  icon: Icons.settings_rounded,
                  label: '设置',
                  selected: selectedIndex == 3,
                  onTap: () => onSelected(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellBottomButton extends StatelessWidget {
  const _ShellBottomButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: AppSpacingTokens.mobileTabContentHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

class _ShellNavButton extends StatefulWidget {
  const _ShellNavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ShellNavButton> createState() => _ShellNavButtonState();
}

class _ShellNavButtonState extends State<_ShellNavButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlighted = _hovered || _focused;

    return Semantics(
      label: widget.label,
      button: true,
      selected: widget.selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) => setState(() => _hovered = value),
          onFocusChange: (value) => setState(() => _focused = value),
          borderRadius: BorderRadius.circular(AppRadiusTokens.iconButton - 6),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: AppMotion.micro,
            curve: AppMotion.enter,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected
                  ? colorScheme.primaryContainer
                  : (highlighted
                        ? colorScheme.outlineVariant.withValues(alpha: 0.74)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(
                AppRadiusTokens.iconButton - 6,
              ),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.selected
                        ? colorScheme.primary
                        : highlighted
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
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

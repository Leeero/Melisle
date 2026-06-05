import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/presentation/widgets/mini_player_bar.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: navigationShell,
      bottomNavigationBar: _ShellBottomDock(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.mobilePageX,
              ),
              child: MiniPlayerBar(),
            ),
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
  const _ShellBottomDock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
    final path = GoRouterState.of(context).uri.path;

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
                selected: path == '/home',
                onTap: () => onSelected(0),
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.search_rounded,
                label: '搜索',
                selected: path == '/search',
                onTap: () => onSelected(1),
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.library_music_rounded,
                label: '媒体库',
                selected:
                    path == '/library' ||
                    path.startsWith('/album/') ||
                    path.startsWith('/artist/'),
                onTap: () => onSelected(2),
              ),
              const SizedBox(height: 10),
              const _ShellSectionDivider(),
              const _ShellSectionLabel('资料库'),
              _ShellNavButton(
                icon: Icons.favorite_border_rounded,
                label: '收藏',
                selected: path == '/favorites',
                onTap: () => onSelected(3),
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.history_rounded,
                label: '最近播放',
                selected: path == '/history',
                onTap: () {
                  onSelected(0);
                  context.go('/history');
                },
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.queue_music_rounded,
                label: '歌单',
                selected: path.startsWith('/playlists'),
                onTap: () {
                  onSelected(2);
                  context.go('/playlists');
                },
              ),
              const SizedBox(height: 10),
              const _ShellSectionDivider(),
              const _ShellSectionLabel('管理'),
              _ShellNavButton(
                icon: Icons.download_rounded,
                label: '下载管理',
                selected: path == '/downloads',
                onTap: () {
                  onSelected(4);
                  context.go('/downloads');
                },
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.settings_rounded,
                label: '设置',
                selected: path == '/settings',
                onTap: () => onSelected(4),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = Color.lerp(
      colorScheme.primary,
      theme.musicTeal,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.86),
        border: Border(
          top: BorderSide(
            color: Color.alphaBlend(
              theme.musicTeal.withValues(alpha: 0.14),
              colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: SizedBox(
            height: AppSpacingTokens.mobileTabContentHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.mobilePageX,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ShellBottomButton(
                      icon: Icons.home_rounded,
                      label: '首页',
                      selected: selectedIndex == 0,
                      selectedColor: selectedColor,
                      onTap: () => onSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _ShellBottomButton(
                      icon: Icons.search_rounded,
                      label: '搜索',
                      selected: selectedIndex == 1,
                      selectedColor: selectedColor,
                      onTap: () => onSelected(1),
                    ),
                  ),
                  Expanded(
                    child: _ShellBottomButton(
                      icon: Icons.library_music_rounded,
                      label: '媒体库',
                      selected: selectedIndex == 2,
                      selectedColor: selectedColor,
                      onTap: () => onSelected(2),
                    ),
                  ),
                  Expanded(
                    child: _ShellBottomButton(
                      icon: Icons.favorite_border_rounded,
                      label: '收藏',
                      selected: selectedIndex == 3,
                      selectedColor: selectedColor,
                      onTap: () => onSelected(3),
                    ),
                  ),
                  Expanded(
                    child: _ShellBottomButton(
                      icon: Icons.settings_rounded,
                      label: '设置',
                      selected: selectedIndex == 4,
                      selectedColor: selectedColor,
                      onTap: () => onSelected(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellBottomButton extends StatefulWidget {
  const _ShellBottomButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  State<_ShellBottomButton> createState() => _ShellBottomButtonState();
}

class _ShellBottomButtonState extends State<_ShellBottomButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.selected ? widget.selectedColor : theme.muted;

    return Semantics(
      label: widget.label,
      button: true,
      selected: widget.selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedOpacity(
            duration: AppMotion.micro,
            curve: AppMotion.standard,
            opacity: _pressed ? 0.62 : 1,
            child: SizedBox(
              height: AppSpacingTokens.mobileTabContentHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 22, color: color),
                  const SizedBox(height: 3),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 10,
                      height: 1,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
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

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlighted = _hovered || _focused;
    final radius = BorderRadius.circular(AppRadiusTokens.iconButton - 6);
    final hoverBackground = Color.alphaBlend(
      theme.musicTealSoft.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.64 : 0.54,
      ),
      theme.surfaceSidebar,
    );
    final idleBackground = hoverBackground.withValues(alpha: 0);

    return Semantics(
      label: widget.label,
      button: true,
      selected: widget.selected,
      onTap: widget.onTap,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: Focus(
            onFocusChange: _setFocused,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => _setHovered(true),
              onExit: (_) => _setHovered(false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: AppMotion.micro,
                  curve: AppMotion.enter,
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 34),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? colorScheme.primaryContainer
                        : (highlighted ? hoverBackground : idleBackground),
                    borderRadius: radius,
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
                        style: theme.textTheme.bodyMedium?.copyWith(
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
          ),
        ),
      ),
    );
  }
}

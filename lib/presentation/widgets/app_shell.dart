import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/presentation/navigation/popup_route_coordinator.dart';
import 'package:cross_platform_music_player/presentation/widgets/mini_player_bar.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.popupRouteCoordinator,
  });

  final StatefulNavigationShell navigationShell;
  final PopupRouteCoordinator popupRouteCoordinator;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;
    final layout = AppBreakpoints.of(context);

    return switch (layout) {
      AppLayoutSize.largeDesktop ||
      AppLayoutSize.desktop => _ExpandedShellScaffold(
        navigationShell: navigationShell,
        onSelected: (index) => _go(context, index),
      ),
      AppLayoutSize.medium => _MediumShellScaffold(
        navigationShell: navigationShell,
        onSelected: (index) => _go(context, index),
      ),
      AppLayoutSize.compact => _CompactShellScaffold(
        navigationShell: navigationShell,
        selectedIndex: selectedIndex,
        onSelected: (index) => _go(context, index),
      ),
    };
  }

  void _go(BuildContext context, int index) {
    popupRouteCoordinator.dismissPopups();
    navigationShell.goBranch(index, initialLocation: true);
  }
}

class _ExpandedShellScaffold extends StatelessWidget {
  const _ExpandedShellScaffold({
    required this.navigationShell,
    required this.onSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('shell-desktop'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _ShellSidebar(onSelected: onSelected, compact: false),
                Expanded(child: _ShellContentSurface(body: navigationShell)),
              ],
            ),
          ),
          const MiniPlayerBar(),
        ],
      ),
    );
  }
}

/// Medium 布局（768-1079px）：紧凑侧边栏 + 内容区 + 浮动迷你播放栏。
class _MediumShellScaffold extends StatelessWidget {
  const _MediumShellScaffold({
    required this.navigationShell,
    required this.onSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('shell-medium'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _ShellSidebar(onSelected: onSelected, compact: true),
                Expanded(child: _ShellContentSurface(body: navigationShell)),
              ],
            ),
          ),
          const MiniPlayerBar(),
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
      key: const ValueKey('shell-compact'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: navigationShell,
      bottomNavigationBar: _ShellBottomDock(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayerBar(),
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
  const _ShellContentSurface({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(children: [Expanded(child: body)]),
    );
  }
}

class _ShellSidebar extends StatefulWidget {
  const _ShellSidebar({required this.onSelected, this.compact = false});

  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  State<_ShellSidebar> createState() => _ShellSidebarState();
}

class _ShellSidebarState extends State<_ShellSidebar> {
  bool _libraryExpanded = true;

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final onSelected = widget.onSelected;
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final routeState = GoRouterState.of(context);
    final path = routeState.uri.path;
    final libraryTab = routeState.uri.queryParameters['tab'];

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
        key: ValueKey(compact ? 'shell-sidebar-compact' : 'shell-sidebar-wide'),
        width: compact ? 72 : AppSpacingTokens.desktopSidebarWidth,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 10,
            Platform.isMacOS ? 20 : 16,
            compact ? 8 : 10,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: compact ? 0 : 10,
                  top: Platform.isMacOS
                      ? AppSpacingTokens.macOsTrafficLightInset
                      : 4,
                  right: compact ? 0 : 10,
                  bottom: 20,
                ),
                child: compact
                    ? _ShellLogo(colorScheme: colorScheme)
                    : const _ShellBrandLockup(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!compact) const _SidebarGroupLabel('聆听'),
                      _ShellNavButton(
                        icon: Icons.home_rounded,
                        label: '首页',
                        compact: compact,
                        selected: path == '/home',
                        onTap: () => onSelected(0),
                      ),
                      const SizedBox(height: 2),
                      _ShellNavButton(
                        icon: Icons.search_rounded,
                        label: '搜索',
                        compact: compact,
                        selected: path == '/search',
                        onTap: () => onSelected(1),
                      ),
                      if (!compact) const _SidebarGroupLabel('音乐库'),
                      _ShellNavButton(
                        icon: Icons.library_music_rounded,
                        label: '媒体库',
                        compact: compact,
                        selected:
                            path == '/library' ||
                            path.startsWith('/album/') ||
                            path.startsWith('/artist/'),
                        trailing: compact
                            ? null
                            : Icon(
                                _libraryExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              ),
                        onTap: () => setState(
                          () => _libraryExpanded = !_libraryExpanded,
                        ),
                      ),
                      if (!compact && _libraryExpanded) ...[
                        const SizedBox(height: 2),
                        _SidebarSubNavButton(
                          label: '歌曲',
                          selected: path == '/library' && libraryTab == null,
                          onTap: () {
                            onSelected(2);
                            context.go('/library');
                          },
                        ),
                        _SidebarSubNavButton(
                          label: '专辑',
                          selected:
                              path.startsWith('/album/') ||
                              libraryTab == 'albums',
                          onTap: () {
                            onSelected(2);
                            context.go('/library?tab=albums');
                          },
                        ),
                        _SidebarSubNavButton(
                          label: '艺术家',
                          selected:
                              path.startsWith('/artist/') ||
                              libraryTab == 'artists',
                          onTap: () {
                            onSelected(2);
                            context.go('/library?tab=artists');
                          },
                        ),
                      ],
                      _ShellNavButton(
                        icon: Icons.favorite_border_rounded,
                        label: '收藏',
                        compact: compact,
                        selected: path == '/favorites',
                        onTap: () => onSelected(3),
                      ),
                      const SizedBox(height: 2),
                      _ShellNavButton(
                        icon: Icons.queue_music_rounded,
                        label: '歌单',
                        compact: compact,
                        selected: path.startsWith('/playlists'),
                        onTap: () {
                          onSelected(2);
                          context.go('/playlists');
                        },
                      ),
                      if (!compact) const _SidebarGroupLabel('系统'),
                      _ShellNavButton(
                        icon: Icons.download_rounded,
                        label: '下载',
                        compact: compact,
                        selected: path == '/downloads',
                        onTap: () => context.go('/downloads'),
                      ),
                      const SizedBox(height: 2),
                      _ShellNavButton(
                        icon: Icons.history_rounded,
                        label: '历史',
                        compact: compact,
                        selected: path == '/home/history',
                        onTap: () => context.go('/home/history'),
                      ),
                      const SizedBox(height: 2),
                      _ShellNavButton(
                        icon: Icons.settings_rounded,
                        label: '设置',
                        compact: compact,
                        selected: path == '/settings',
                        onTap: () => onSelected(4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellBrandLockup extends StatelessWidget {
  const _ShellBrandLockup();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppConstants.appEnglishName,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontFamily: 'Righteous',
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                AppConstants.appName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarGroupLabel extends StatelessWidget {
  const _SidebarGroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 7),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).muted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ShellLogo extends StatelessWidget {
  const _ShellLogo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadiusTokens.iconButton - 4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
        child: Image.asset(
          'assets/icons/logo.png',
          fit: BoxFit.contain,
          semanticLabel: '乐岛图标',
        ),
      ),
    );
  }
}

class _SidebarSubNavButton extends StatelessWidget {
  const _SidebarSubNavButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
      child: Padding(
        padding: const EdgeInsets.only(left: 42),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            key: ValueKey('shell-sub-nav-$label'),
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(AppRadiusTokens.sm),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
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
    final selectedColor = colorScheme.primary;

    return DecoratedBox(
      key: const ValueKey('shell-bottom-bar'),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.86),
        border: Border(
          top: BorderSide(
            color: Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.14),
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
                      fontSize: 12,
                      height: 1.1,
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
    this.compact = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final Widget? trailing;

  @override
  State<_ShellNavButton> createState() => _ShellNavButtonState();
}

class _ShellNavButtonState extends State<_ShellNavButton> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'shell-nav-${widget.label}',
  );
  bool _hovered = false;
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
    final radius = BorderRadius.circular(AppRadiusTokens.sm);
    final hoverBackground = Color.alphaBlend(
      colorScheme.primaryContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.64 : 0.54,
      ),
      theme.surfaceSidebar,
    );
    final idleBackground = hoverBackground.withValues(alpha: 0);
    final selectedForeground = colorScheme.primary;

    final button = Semantics(
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
            key: ValueKey('shell-nav-focus-${widget.label}'),
            focusNode: _focusNode,
            onFocusChange: _setFocused,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => _setHovered(true),
              onExit: (_) => _setHovered(false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: AnimatedContainer(
                  key: ValueKey('shell-nav-surface-${widget.label}'),
                  duration: AppMotion.micro,
                  curve: AppMotion.enter,
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 8 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? colorScheme.primaryContainer
                        : (highlighted ? hoverBackground : idleBackground),
                    borderRadius: radius,
                    border: Border.all(
                      color: _focused
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: AppBorderTokens.focus,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: widget.compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.selected
                            ? selectedForeground
                            : colorScheme.onSurfaceVariant,
                      ),
                      if (!widget.compact) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: widget.selected
                                  ? selectedForeground
                                  : highlighted
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: widget.selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (widget.trailing != null)
                          IconTheme(
                            data: IconThemeData(
                              color: widget.selected
                                  ? selectedForeground
                                  : colorScheme.onSurfaceVariant,
                            ),
                            child: widget.trailing!,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.compact) return button;
    return Tooltip(message: widget.label, child: button);
  }
}

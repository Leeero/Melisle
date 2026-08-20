import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/mini_player_bar.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/desktop_page_toolbar.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navigationShell.currentIndex;
    final layout = AppBreakpoints.of(context);

    return switch (layout) {
      AppLayoutSize.largeDesktop ||
      AppLayoutSize.desktop => _ExpandedShellScaffold(
        navigationShell: widget.navigationShell,
        selectedIndex: selectedIndex,
        onSelected: _go,
        sidebarCollapsed: _sidebarCollapsed,
        onToggleSidebar: () =>
            setState(() => _sidebarCollapsed = !_sidebarCollapsed),
      ),
      AppLayoutSize.medium => _MediumShellScaffold(
        navigationShell: widget.navigationShell,
        selectedIndex: selectedIndex,
        onSelected: _go,
      ),
      AppLayoutSize.compact => _CompactShellScaffold(
        navigationShell: widget.navigationShell,
        selectedIndex: selectedIndex,
        onSelected: _go,
      ),
    };
  }

  void _go(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _ExpandedShellScaffold extends StatelessWidget {
  const _ExpandedShellScaffold({
    required this.navigationShell,
    required this.selectedIndex,
    required this.onSelected,
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
  });

  final StatefulNavigationShell navigationShell;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('shell-desktop'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _ShellSidebar(
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            compact: sidebarCollapsed,
            onToggleCompact: onToggleSidebar,
          ),
          Expanded(
            child: _ShellContentSurface(
              body: Column(
                children: [
                  const DesktopPageToolbar(),
                  Expanded(child: navigationShell),
                ],
              ),
              footer: const MiniPlayerBar(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Medium 布局（768-1079px）：紧凑侧边栏 + 内容区 + 浮动迷你播放栏。
class _MediumShellScaffold extends StatelessWidget {
  const _MediumShellScaffold({
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
      key: const ValueKey('shell-medium'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _ShellSidebar(
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            compact: true,
          ),
          Expanded(
            child: _ShellContentSurface(
              body: Column(
                children: [
                  const DesktopPageToolbar(),
                  Expanded(child: navigationShell),
                ],
              ),
              footer: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacingTokens.cardPadding),
                child: MiniPlayerBar(),
              ),
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
      key: const ValueKey('shell-compact'),
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
              Theme.of(context).ambientGradientStart,
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
  const _ShellSidebar({
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
    this.onToggleCompact,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;
  final VoidCallback? onToggleCompact;

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
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ShellLogo(colorScheme: colorScheme),
                          if (onToggleCompact != null) ...[
                            const SizedBox(height: 8),
                            _SidebarToggleButton(
                              compact: true,
                              onPressed: onToggleCompact!,
                            ),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          _ShellLogo(colorScheme: colorScheme),
                          const SizedBox(width: 10),
                          Text(
                            AppConstants.appName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (onToggleCompact != null) ...[
                            const Spacer(),
                            _SidebarToggleButton(
                              compact: false,
                              onPressed: onToggleCompact!,
                            ),
                          ],
                        ],
                      ),
              ),
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
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.library_music_rounded,
                label: '媒体库',
                compact: compact,
                selected:
                    path == '/library' ||
                    path.startsWith('/album/') ||
                    path.startsWith('/artist/'),
                onTap: () => onSelected(2),
              ),
              const SizedBox(height: 2),
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
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.download_rounded,
                label: '下载',
                compact: compact,
                selected: path == '/downloads',
                onTap: () {
                  onSelected(4);
                  context.go('/downloads');
                },
              ),
              const SizedBox(height: 2),
              _ShellNavButton(
                icon: Icons.history_rounded,
                label: '历史',
                compact: compact,
                selected: path == '/history',
                onTap: () {
                  onSelected(0);
                  context.go('/history');
                },
              ),
              const Spacer(),
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
      child: Image.asset(
        'assets/icons/logo.png',
        fit: BoxFit.contain,
        semanticLabel: '乐岛图标',
      ),
    );
  }
}

class _SidebarToggleButton extends StatelessWidget {
  const _SidebarToggleButton({required this.compact, required this.onPressed});

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: compact ? '展开侧边栏' : '收起侧边栏',
      style: AppActionButtonStyle.icon(context, iconSize: 18),
      icon: Icon(
        compact
            ? Icons.keyboard_double_arrow_right_rounded
            : Icons.keyboard_double_arrow_left_rounded,
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
      key: const ValueKey('shell-bottom-bar'),
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
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

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
      theme.musicTealSoft.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.64 : 0.54,
      ),
      theme.surfaceSidebar,
    );
    final idleBackground = hoverBackground.withValues(alpha: 0);
    final selectedForeground = colorScheme.onPrimaryContainer;

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
                          ? widget.selected
                                ? selectedForeground
                                : colorScheme.primary
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
                        Text(
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

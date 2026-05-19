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
    final macOsTrafficLightPadding = Platform.isMacOS
        ? AppSpacingTokens.macOsTrafficLightInset
        : 0.0;

    return Scaffold(
      body: SafeArea(
        top: !Platform.isMacOS,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacingTokens.shellOuterPadding,
            Platform.isMacOS
                ? macOsTrafficLightPadding
                : AppSpacingTokens.shellOuterPadding,
            AppSpacingTokens.shellOuterPadding,
            AppSpacingTokens.shellBottomInset,
          ),
          child: Row(
            children: [
              _ShellSidebar(
                selectedIndex: selectedIndex,
                onSelected: onSelected,
              ),
              const SizedBox(width: AppSpacingTokens.shellGap),
              Expanded(
                child: _ShellContentSurface(
                  body: navigationShell,
                  footer: const MiniPlayerBar(),
                ),
              ),
            ],
          ),
        ),
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
    final hasMiniPlayer = context.select<PlayerCubit, bool>(
      (cubit) => cubit.state.currentTrack != null,
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _ShellBottomDock(
        hasMiniPlayer: hasMiniPlayer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayerBar(),
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
        padding: EdgeInsets.fromLTRB(
          AppSpacingTokens.shellBottomInset,
          hasMiniPlayer ? 2 : 6,
          AppSpacingTokens.shellBottomInset,
          AppSpacingTokens.shellBottomInset,
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final children = <Widget>[Expanded(child: body)];
    final footer = this.footer;
    if (footer != null) {
      children.add(footer);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadiusTokens.shellContainer),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadiusTokens.shellContainer),
        child: Column(children: children),
      ),
    );
  }
}

class _ShellSidebar extends StatelessWidget {
  const _ShellSidebar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: SizedBox(
        width: AppSpacingTokens.desktopSidebarWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            10,
            AppSpacingTokens.desktopSidebarTopGap,
            10,
            AppSpacingTokens.desktopSidebarBottomGap,
          ),
          child: Column(
            children: [
              if (Platform.isMacOS) const SizedBox(height: 8),
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Image.asset(
                  'assets/icons/logo.png',
                  fit: BoxFit.contain,
                  semanticLabel: '乐岛图标',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 28),
              _ShellNavButton(
                icon: Icons.home_rounded,
                label: '首页',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              const SizedBox(height: 6),
              _ShellNavButton(
                icon: Icons.library_music_rounded,
                label: '媒体库',
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              const SizedBox(height: 6),
              _ShellNavButton(
                icon: Icons.queue_music_rounded,
                label: '歌单',
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              const SizedBox(height: 6),
              _ShellNavButton(
                icon: Icons.favorite_rounded,
                label: '收藏',
                selected: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
              const Spacer(),
              _ShellNavButton(
                icon: Icons.settings_rounded,
                label: '设置',
                selected: selectedIndex == 4,
                onTap: () => onSelected(4),
              ),
            ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
              icon: Icons.favorite_rounded,
              label: '收藏',
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
            ),
          ),
          Expanded(
            child: _ShellBottomButton(
              icon: Icons.settings_rounded,
              label: '设置',
              selected: selectedIndex == 4,
              onTap: () => onSelected(4),
            ),
          ),
        ],
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.card),
          child: AnimatedContainer(
            duration: AppMotion.short,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadiusTokens.card),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
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
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.enter,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? colorScheme.primary.withValues(alpha: 0.10)
                  : (highlighted
                        ? colorScheme.onSurface.withValues(alpha: 0.05)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.selected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : (_focused
                          ? colorScheme.primary.withValues(alpha: 0.42)
                          : Colors.transparent),
              ),
              boxShadow: widget.selected || _focused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(
                          alpha: _focused ? 0.12 : 0.08,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: widget.selected || _focused
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.selected || _focused
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
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

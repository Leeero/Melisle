import 'dart:io';

import 'package:cross_platform_music_player/presentation/widgets/mini_player_bar.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = AppBreakpoints.usesWideContent(context);

    if (isDesktop) {
      // macOS 隐藏标题栏后，交通灯按钮会叠在左上角，
      // 需要为侧边栏/内容区顶部留出额外 padding。
      final macOsTrafficLightPadding = Platform.isMacOS
          ? AppSpacingTokens.macOsTrafficLightInset
          : 0.0;

      return Scaffold(
        body: SafeArea(
          // macOS 隐藏标题栏后 SafeArea.top 已失效，我们手动管理。
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
                _ShellSidebar(selectedIndex: selectedIndex, onSelected: _go),
                const SizedBox(width: AppSpacingTokens.shellGap),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(
                        AppRadiusTokens.shellContainer,
                      ),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppRadiusTokens.shellContainer,
                      ),
                      child: Column(
                        children: [
                          Expanded(child: navigationShell),
                          const MiniPlayerBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacingTokens.shellBottomInset,
            6,
            AppSpacingTokens.shellBottomInset,
            AppSpacingTokens.shellBottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayerBar(),
              const SizedBox(height: AppSpacingTokens.miniPlayerOuterTop),
              _ShellBottomBar(selectedIndex: selectedIndex, onSelected: _go),
            ],
          ),
        ),
      ),
    );
  }

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
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

    return SizedBox(
      width: AppSpacingTokens.desktopSidebarWidth,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          0,
          AppSpacingTokens.desktopSidebarTopGap,
          0,
          AppSpacingTokens.desktopSidebarBottomGap,
        ),
        child: Column(
          children: [
            // macOS：交通灯按钮区域（关闭/最小化/最大化）在左上角，
            // 预留额外空间避免 logo 被遮挡。
            if (Platform.isMacOS) const SizedBox(height: 8),
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                'assets/icons/logo.png',
                fit: BoxFit.contain,
                semanticLabel: '乐岛图标',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            _ShellNavButton(
              icon: Icons.home_rounded,
              label: '首页',
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            const SizedBox(height: 4),
            _ShellNavButton(
              icon: Icons.library_music_rounded,
              label: '媒体库',
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
            const SizedBox(height: 4),
            _ShellNavButton(
              icon: Icons.queue_music_rounded,
              label: '歌单',
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
            const Spacer(),
            _ShellNavButton(
              icon: Icons.settings_rounded,
              label: '设置',
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
            ),
          ],
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
              icon: Icons.settings_rounded,
              label: '设置',
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadiusTokens.card),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimaryContainer
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: widget.label,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.enter,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? colorScheme.primary.withValues(alpha: 0.10)
                  : (_hovered
                        ? colorScheme.onSurface.withValues(alpha: 0.05)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: widget.selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.selected
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

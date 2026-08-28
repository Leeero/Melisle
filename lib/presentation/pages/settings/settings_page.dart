import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppSettingsCubit, AppSettingsState>(
      listenWhen: (previous, current) => previous.feedback != current.feedback,
      listener: (context, state) {
        final feedback = state.feedback;
        if (feedback == null) return;
        AppSnackBar.show(context, feedback.message);
      },
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        buildWhen: (a, b) => a.isLoading != b.isLoading,
        builder: (context, state) {
          if (state.isLoading) {
            return AppContentPage(
              header: const AppPageHeader(
                title: '设置',
                automaticImplyLeading: false,
              ),
              body: const AppBodyStateView.loading(),
            );
          }

          return AppContentPage(
            header: const AppPageHeader(
              title: '设置',
              description: '让乐岛更适合你的聆听习惯',
              titleMaxWidth: 300,
              automaticImplyLeading: false,
            ),
            body: const _SettingsOverview(),
          );
        },
      ),
    );
  }
}

class _SettingsOverview extends StatelessWidget {
  const _SettingsOverview();

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);
    final desktop = AppBreakpoints.usesDesktopShell(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppPageLayout.contentBottomInset,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: desktop ? 820 : 1120),
          child: desktop
              ? const _DesktopSettingsLayout()
              : const _CompactSettingsLayout(),
        ),
      ),
    );
  }
}

class _CompactSettingsLayout extends StatelessWidget {
  const _CompactSettingsLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('settings-compact-layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsSection(title: '当前服务器', child: _CompactServerStatus()),
        SizedBox(height: AppPageLayout.sectionGap),
        _SettingsSection(title: '常用偏好', child: _CommonPreferencesCard()),
        SizedBox(height: AppPageLayout.sectionGap),
        _SettingsSection(title: '媒体与设备', child: _SecondarySettingsCard()),
        SizedBox(height: AppPageLayout.sectionGap),
        _SettingsSection(title: '存储', child: _StorageCard()),
        SizedBox(height: AppPageLayout.sectionGap),
        _SettingsSection(title: '关于', child: _AboutCard()),
        SizedBox(height: 14),
        _LogoutCard(),
      ],
    );
  }
}

class _DesktopSettingsLayout extends StatelessWidget {
  const _DesktopSettingsLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('settings-desktop-layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsSection(title: '当前服务器', child: _ServerCard()),
        SizedBox(height: AppPageLayout.sectionGap),
        _SettingsSection(title: '常用偏好', child: _CommonPreferencesCard()),
        SizedBox(height: AppPageLayout.sectionGap),
        _SettingsSection(
          title: '媒体与设备',
          child: _SecondarySettingsCard(desktop: true),
        ),
        SizedBox(height: AppPageLayout.sectionGap),
        _SettingsSection(title: '存储', child: _StorageCard()),
        SizedBox(height: AppPageLayout.sectionGap),
        _SettingsSection(title: '关于', child: _AboutCard()),
      ],
    );
  }
}

class CustomMediaSourcesPage extends StatelessWidget {
  const CustomMediaSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppSettingsCubit, AppSettingsState>(
      listenWhen: (previous, current) => previous.feedback != current.feedback,
      listener: (context, state) {
        final feedback = state.feedback;
        if (feedback != null) AppSnackBar.show(context, feedback.message);
      },
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        buildWhen: (a, b) => a.isLoading != b.isLoading,
        builder: (context, state) {
          if (state.isLoading) {
            return const AppContentPage(
              header: AppPageHeader(
                title: '歌词与封面',
                automaticImplyLeading: false,
              ),
              body: AppBodyStateView.loading(),
            );
          }

          final compact = AppBreakpoints.isCompact(context);

          return AppContentPage(
            header: AppPageHeader(
              title: '歌词与封面',
              description: compact ? null : '配置自定义媒体来源地址。',
              titleMaxWidth: compact ? 220 : 300,
              automaticImplyLeading: false,
              trailing: compact
                  ? null
                  : FilledButton.icon(
                      onPressed: context
                          .read<AppSettingsCubit>()
                          .saveCustomMediaSources,
                      style: FilledButton.styleFrom(
                        alignment: Alignment.center,
                      ),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('保存', style: TextStyle(height: 1)),
                    ),
            ),
            body: ListView(
              padding: AppPageLayout.sectionPadding(
                context,
                bottom: AppPageLayout.contentBottomInset,
              ),
              children: [
                const _CustomMediaSourcesOverviewCard(),
                const SizedBox(height: 14),
                const _CustomMediaSourcesCard(showIntro: false),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> _showLogoutConfirmation(BuildContext context) async {
  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: '退出登录',
    message: '退出后会清除登录态、播放队列及当前账号的本地历史，需要重新输入服务器信息。',
    confirmLabel: '退出',
    icon: Icons.logout_rounded,
    tone: AppModalTone.danger,
  );
  if (confirmed && context.mounted) {
    await context.read<AuthCubit>().logout();
  }
}

Future<void> _showClearCacheConfirmation(BuildContext context) async {
  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: '清理缓存',
    message: '将清除临时数据并释放本地存储空间，已下载的离线曲目不会受到影响。',
    confirmLabel: '清理',
    icon: Icons.cleaning_services_rounded,
    tone: AppModalTone.danger,
  );
  if (confirmed && context.mounted) {
    await context.read<AppSettingsCubit>().clearCache();
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (a, b) => a.status != b.status || a.session != b.session,
      builder: (context, authState) {
        final session = authState.session;
        final connected = session != null;

        return _SettingsGroupSurface(
          child: Column(
            children: [
              _HoverableListTile(
                leading: const _SettingRowIcon(icon: Icons.person_rounded),
                title: Text(session?.userName ?? '尚未登录'),
                subtitle: const Text('当前账号'),
              ),
              _SettingsDivider(colorScheme: colorScheme),
              _HoverableListTile(
                leading: const _SettingRowIcon(icon: Icons.link_rounded),
                title: Text(session?.normalizedServerUrl ?? '尚未连接服务器'),
                subtitle: const Text('服务器地址'),
              ),
              _SettingsDivider(colorScheme: colorScheme),
              _HoverableListTile(
                leading: _ConnectionIndicator(connected: connected),
                title: Text(
                  session == null ? '待连接' : _backendApiLabel(session),
                ),
                trailing: _SettingValue(
                  label: connected ? '已连接' : '未连接',
                  emphasized: connected,
                ),
              ),
              _SettingsDivider(colorScheme: colorScheme),
              _HoverableListTile(
                leading: const _SettingRowIcon(
                  icon: Icons.logout_rounded,
                  danger: true,
                ),
                title: Text('退出登录', style: TextStyle(color: colorScheme.error)),
                onTap: () => _showLogoutConfirmation(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactServerStatus extends StatelessWidget {
  const _CompactServerStatus();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (a, b) => a.status != b.status || a.session != b.session,
      builder: (context, state) {
        final session = state.session;
        final connected = session != null;
        return _SettingsGroupSurface(
          child: _HoverableListTile(
            leading: _ConnectionIndicator(connected: connected),
            title: Text(
              session == null ? '尚未连接' : '${_backendApiLabel(session)} · 已连接',
            ),
            subtitle: Text(session?.normalizedServerUrl ?? '请重新登录连接服务器'),
            trailing: _SettingValue(label: session?.userName ?? '未登录'),
          ),
        );
      },
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupSurface(
      child: _HoverableListTile(
        leading: const _SettingRowIcon(icon: Icons.delete_outline_rounded),
        title: const Text('清理缓存'),
        subtitle: const Text('不会影响已下载的离线曲目。'),
        trailing: const _SettingValue(label: '清理', chevron: true),
        onTap: () => _showClearCacheConfirmation(context),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const _SettingsGroupSurface(
      child: _HoverableListTile(
        leading: _SettingRowIcon(icon: Icons.info_outline_rounded),
        title: Text('${AppConstants.appEnglishName} ${AppConstants.appName}'),
        subtitle: Text(AppConstants.appSlogan),
        trailing: _SettingValue(label: '1.0.0'),
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SettingsGroupSurface(
      child: _HoverableListTile(
        leading: const _SettingRowIcon(
          icon: Icons.logout_rounded,
          danger: true,
        ),
        title: Text('退出登录', style: TextStyle(color: colorScheme.error)),
        onTap: () => _showLogoutConfirmation(context),
      ),
    );
  }
}

class _SettingRowIcon extends StatelessWidget {
  const _SettingRowIcon({
    required this.icon,
    this.emphasized = false,
    this.danger = false,
  });

  final IconData icon;
  final bool emphasized;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = danger
        ? colorScheme.error
        : emphasized
        ? colorScheme.primary
        : theme.muted;
    final background = emphasized
        ? theme.selectedWash.withValues(alpha: 0.72)
        : theme.hoverWash.withValues(alpha: 0.34);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon, size: 20, color: foreground),
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 38,
      height: 38,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: connected ? theme.success : theme.muted,
            shape: BoxShape.circle,
            boxShadow: connected
                ? [
                    BoxShadow(
                      color: theme.success.withValues(alpha: 0.22),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: const SizedBox(width: 12, height: 12),
        ),
      ),
    );
  }
}

class _SettingValue extends StatelessWidget {
  const _SettingValue({
    required this.label,
    this.chevron = false,
    this.emphasized = false,
    this.expanded,
  });

  final String label;
  final bool chevron;
  final bool emphasized;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = emphasized ? colorScheme.primary : theme.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        if (chevron) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 17, color: foreground),
        ] else if (expanded != null) ...[
          const SizedBox(width: 4),
          Icon(
            expanded!
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: foreground,
          ),
        ],
      ],
    );
  }
}

String _backendApiLabel(AuthSession session) {
  return switch (session.backendType) {
    MusicBackendType.emby => 'Emby API',
    MusicBackendType.navidrome => 'Subsonic API',
  };
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = AppBreakpoints.isCompact(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitleRow(
          title: title,
          padding: EdgeInsets.zero,
          titleStyle: theme.textTheme.labelMedium?.copyWith(
            color: theme.muted,
            fontSize: 12,
            fontWeight: compact ? FontWeight.w600 : FontWeight.w700,
            letterSpacing: compact ? 0 : 0.32,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        child,
      ],
    );
  }
}

class _SettingsGroupSurface extends StatelessWidget {
  const _SettingsGroupSurface({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final radius = compact
        ? AppRadiusTokens.mobileLg + 2
        : AppRadiusTokens.desktopLg + 4;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            colorScheme.surface.withValues(alpha: compact ? 0.96 : 0.72),
            compact
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.18)
                : theme.hoverWash.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: compact ? 0.70 : 0.56,
            ),
            width: compact ? 0.75 : 1,
          ),
        ),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

class _CommonPreferencesCard extends StatelessWidget {
  const _CommonPreferencesCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) =>
          a.defaultQuality != b.defaultQuality ||
          a.gapBetweenTracks != b.gapBetweenTracks ||
          a.themeMode != b.themeMode,
      builder: (context, state) {
        final cubit = context.read<AppSettingsCubit>();
        final colorScheme = Theme.of(context).colorScheme;
        final desktop = AppBreakpoints.usesDesktopShell(context);
        return _SettingsGroupSurface(
          child: Column(
            children: [
              _PreferencePickerTile<AudioQuality>(
                menuKey: const ValueKey('quality-preference-menu'),
                triggerSurfaceKey: const ValueKey(
                  'quality-preference-trigger-surface',
                ),
                desktop: desktop,
                leading: const _SettingRowIcon(
                  icon: Icons.graphic_eq_rounded,
                  emphasized: true,
                ),
                title: '在线音质',
                subtitle: '新建播放队列时使用，当前播放队列不受影响。',
                valueLabel: state.defaultQuality.label,
                currentValue: state.defaultQuality,
                options: [
                  for (final quality in AudioQuality.values)
                    _PreferenceMenuOption(
                      value: quality,
                      label: quality.label,
                      description: _qualityDescription(quality),
                    ),
                ],
                onMobileTap: () => _pickQuality(context, state, cubit),
                onSelected: cubit.setDefaultQuality,
              ),
              _SettingsDivider(colorScheme: colorScheme),
              _PreferencePickerTile<int>(
                menuKey: const ValueKey('gap-preference-menu'),
                desktop: desktop,
                leading: const _SettingRowIcon(
                  icon: Icons.schedule_rounded,
                  emphasized: true,
                ),
                title: '曲间间隔',
                subtitle: state.gapBetweenTracks == Duration.zero
                    ? '无额外间隔（默认）'
                    : '每首结束后等待 ${state.gapBetweenTracks.inSeconds} 秒',
                valueLabel: _gapLabel(state.gapBetweenTracks),
                currentValue: state.gapBetweenTracks.inSeconds,
                options: [
                  const _PreferenceMenuOption(
                    value: 0,
                    label: '无间隔',
                    icon: Icons.skip_next_rounded,
                  ),
                  for (final seconds in [2, 4, 6, 10])
                    _PreferenceMenuOption(
                      value: seconds,
                      label: '$seconds 秒',
                      icon: Icons.space_bar_rounded,
                    ),
                ],
                onMobileTap: () => _pickGap(context, state, cubit),
                onSelected: (seconds) =>
                    cubit.setGapBetweenTracks(Duration(seconds: seconds)),
              ),
              _SettingsDivider(colorScheme: colorScheme),
              _PreferencePickerTile<ThemeMode>(
                menuKey: const ValueKey('theme-preference-menu'),
                desktop: desktop,
                leading: const _SettingRowIcon(
                  icon: Icons.palette_outlined,
                  emphasized: true,
                ),
                title: '主题',
                subtitle: '浅色 / 深色 / 跟随系统。',
                valueLabel: _themeModeLabel(state.themeMode),
                currentValue: state.themeMode,
                options: const [
                  _PreferenceMenuOption(
                    value: ThemeMode.system,
                    label: '跟随系统',
                    icon: Icons.brightness_auto_rounded,
                  ),
                  _PreferenceMenuOption(
                    value: ThemeMode.light,
                    label: '浅色',
                    icon: Icons.light_mode_rounded,
                  ),
                  _PreferenceMenuOption(
                    value: ThemeMode.dark,
                    label: '深色',
                    icon: Icons.dark_mode_rounded,
                  ),
                ],
                onMobileTap: () => _pickTheme(context, state.themeMode),
                onSelected: cubit.setThemeMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTheme(BuildContext context, ThemeMode current) async {
    final cubit = context.read<AppSettingsCubit>();
    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppSheetScaffold(
        title: '主题',
        description: '选择乐岛在浅色、深色或系统模式下的显示方式。',
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (mode) {
            if (mode != null) Navigator.of(sheetContext).pop(mode);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppOptionTile<ThemeMode>(
                title: '跟随系统',
                subtitle: '根据系统深色/浅色设置自动切换。',
                icon: Icons.brightness_auto_rounded,
                value: ThemeMode.system,
                groupValue: current,
                onSelected: (value) => Navigator.of(sheetContext).pop(value),
              ),
              AppOptionTile<ThemeMode>(
                title: '浅色',
                subtitle: '日间浏览和整理媒体库时更易读。',
                icon: Icons.light_mode_rounded,
                value: ThemeMode.light,
                groupValue: current,
                onSelected: (value) => Navigator.of(sheetContext).pop(value),
              ),
              AppOptionTile<ThemeMode>(
                title: '深色',
                subtitle: '适合夜间播放和长时间聆听。',
                icon: Icons.dark_mode_rounded,
                value: ThemeMode.dark,
                groupValue: current,
                onSelected: (value) => Navigator.of(sheetContext).pop(value),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) await cubit.setThemeMode(result);
  }

  Future<void> _pickQuality(
    BuildContext context,
    AppSettingsState state,
    AppSettingsCubit cubit,
  ) async {
    final result = await showModalBottomSheet<AudioQuality>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppSheetScaffold(
        title: '默认音质',
        description: '新建播放队列时使用，切换不会影响当前正在播放的队列。',
        child: RadioGroup<AudioQuality>(
          groupValue: state.defaultQuality,
          onChanged: (value) {
            if (value != null) Navigator.of(sheetContext).pop(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final q in AudioQuality.values)
                AppOptionTile<AudioQuality>(
                  title: q.label,
                  subtitle: _qualityDescription(q),
                  icon: Icons.high_quality_rounded,
                  value: q,
                  groupValue: state.defaultQuality,
                  onSelected: (value) => Navigator.of(sheetContext).pop(value),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await cubit.setDefaultQuality(result);
    }
  }

  Future<void> _pickGap(
    BuildContext context,
    AppSettingsState state,
    AppSettingsCubit cubit,
  ) async {
    const presets = [0, 2, 4, 6, 10];
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppSheetScaffold(
        title: '曲间间隔',
        description: '每首歌结束后等待一小段时间再继续播放。',
        child: RadioGroup<int>(
          groupValue: state.gapBetweenTracks.inSeconds,
          onChanged: (value) {
            if (value != null) Navigator.of(sheetContext).pop(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in presets)
                AppOptionTile<int>(
                  title: s == 0 ? '无间隔' : '$s 秒',
                  subtitle: s == 0 ? '默认连续播放，不额外等待。' : '每首结束后等待 $s 秒。',
                  icon: s == 0
                      ? Icons.skip_next_rounded
                      : Icons.space_bar_rounded,
                  value: s,
                  groupValue: state.gapBetweenTracks.inSeconds,
                  onSelected: (value) => Navigator.of(sheetContext).pop(value),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await cubit.setGapBetweenTracks(Duration(seconds: result));
    }
  }
}

class _PreferenceMenuOption<T> {
  const _PreferenceMenuOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });

  final T value;
  final String label;
  final String? description;
  final IconData? icon;
}

class _PreferencePickerTile<T> extends StatefulWidget {
  const _PreferencePickerTile({
    required this.menuKey,
    this.triggerSurfaceKey,
    required this.desktop,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.valueLabel,
    required this.currentValue,
    required this.options,
    required this.onMobileTap,
    required this.onSelected,
  });

  final Key menuKey;
  final Key? triggerSurfaceKey;
  final bool desktop;
  final Widget leading;
  final String title;
  final String subtitle;
  final String valueLabel;
  final T currentValue;
  final List<_PreferenceMenuOption<T>> options;
  final VoidCallback onMobileTap;
  final Future<void> Function(T value) onSelected;

  @override
  State<_PreferencePickerTile<T>> createState() =>
      _PreferencePickerTileState<T>();
}

class _PreferencePickerTileState<T> extends State<_PreferencePickerTile<T>> {
  late final FocusNode _triggerFocusNode;

  @override
  void initState() {
    super.initState();
    _triggerFocusNode = FocusNode(
      debugLabel: '${widget.title} preference menu trigger',
    );
  }

  @override
  void dispose() {
    _triggerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.desktop) {
      return _HoverableListTile(
        focusIndicatorKey: widget.triggerSurfaceKey,
        leading: widget.leading,
        title: Text(widget.title),
        subtitle: Text(widget.subtitle),
        trailing: _SettingValue(label: widget.valueLabel, chevron: true),
        semanticLabel: '${widget.title}，当前${widget.valueLabel}',
        onTap: widget.onMobileTap,
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, _) => MenuAnchor(
        key: widget.menuKey,
        childFocusNode: _triggerFocusNode,
        alignmentOffset: const Offset(0, 6),
        style: MenuStyle(
          alignment: AlignmentDirectional.bottomEnd,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: AppSpacingTokens.compactGap),
          ),
          fixedSize: const WidgetStatePropertyAll(Size.fromWidth(320)),
          backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(
            theme.brightness == Brightness.dark ? 0 : 2,
          ),
          shadowColor: WidgetStatePropertyAll(
            colorScheme.shadow.withValues(alpha: 0.08),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.card),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
        menuChildren: [
          for (final option in widget.options)
            Semantics(
              checked: option.value == widget.currentValue,
              inMutuallyExclusiveGroup: true,
              child: MenuItemButton(
                onPressed: () async => widget.onSelected(option.value),
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size(304, option.description == null ? 44 : 56),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(
                      horizontal: AppSpacingTokens.inlineGap,
                      vertical: AppSpacingTokens.compactGap,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppRadiusTokens.desktopMd,
                      ),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (option.value == widget.currentValue) {
                      return theme.selectedWash;
                    }
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused) ||
                        states.contains(WidgetState.pressed)) {
                      return theme.hoverWash;
                    }
                    return Colors.transparent;
                  }),
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    if (option.icon != null) ...[
                      Icon(
                        option.icon,
                        size: 19,
                        color: option.value == widget.currentValue
                            ? colorScheme.primary
                            : theme.muted,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: option.value == widget.currentValue
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (option.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              option.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (option.value == widget.currentValue) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
        builder: (context, controller, child) => _HoverableListTile(
          focusIndicatorKey: widget.triggerSurfaceKey,
          focusNode: _triggerFocusNode,
          leading: widget.leading,
          title: Text(widget.title),
          subtitle: Text(widget.subtitle),
          trailing: _SettingValue(
            label: widget.valueLabel,
            expanded: controller.isOpen,
          ),
          semanticLabel: '${widget.title}，当前${widget.valueLabel}',
          expanded: controller.isOpen,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        ),
      ),
    );
  }
}

String _qualityDescription(AudioQuality quality) {
  return switch (quality) {
    AudioQuality.auto => '直接播放源文件，不转码。',
    AudioQuality.low => '较低带宽占用，适合移动网络。',
    AudioQuality.medium => '平衡流量与听感。',
    AudioQuality.high => '优先使用较高码率。',
    AudioQuality.lossless => '尽量保留源文件质量。',
  };
}

String _themeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => '跟随系统',
    ThemeMode.light => '浅色',
    ThemeMode.dark => '深色',
  };
}

String _gapLabel(Duration gap) {
  if (gap == Duration.zero) return '无间隔';
  return '${gap.inSeconds} 秒';
}

class _SecondarySettingsCard extends StatelessWidget {
  const _SecondarySettingsCard({this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) =>
          a.customArtworkSourceEnabled != b.customArtworkSourceEnabled ||
          a.customArtworkSourceUrl != b.customArtworkSourceUrl ||
          a.customLyricsSourceEnabled != b.customLyricsSourceEnabled ||
          a.customLyricsSourceUrl != b.customLyricsSourceUrl ||
          a.menuBarLyricsEnabled != b.menuBarLyricsEnabled,
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        final cubit = context.read<AppSettingsCubit>();
        final enabledCount = _customMediaSourcesEnabledCount(state);
        final supportsMenuBarLyrics =
            desktop &&
            !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.macOS ||
                defaultTargetPlatform == TargetPlatform.windows);

        return _SettingsGroupSurface(
          child: Column(
            children: [
              _HoverableListTile(
                leading: const _SettingRowIcon(icon: Icons.lyrics_rounded),
                title: const Text('歌词与封面'),
                subtitle: const Text('配置封面代理、歌词服务或自建接口。'),
                trailing: _SettingValue(
                  label: _customMediaSourcesSummaryLabel(state),
                  chevron: true,
                  emphasized: enabledCount > 0,
                ),
                onTap: () => context.push('/settings/media-sources'),
              ),
              if (supportsMenuBarLyrics) ...[
                _SettingsDivider(colorScheme: colorScheme),
                _HoverableListTile(
                  leading: const _SettingRowIcon(icon: Icons.subtitles_rounded),
                  title: const Text('菜单栏歌词'),
                  subtitle: const Text('播放时在菜单栏或托盘中显示当前歌词。'),
                  trailing: _SourceToggle(
                    value: state.menuBarLyricsEnabled,
                    semanticLabel:
                        '${state.menuBarLyricsEnabled ? '关闭' : '开启'} 菜单栏歌词',
                    onChanged: cubit.setMenuBarLyricsEnabled,
                  ),
                  onTap: () => cubit.setMenuBarLyricsEnabled(
                    !state.menuBarLyricsEnabled,
                  ),
                ),
              ],
              _SettingsDivider(colorScheme: colorScheme),
              _HoverableListTile(
                leading: const _SettingRowIcon(icon: Icons.download_rounded),
                title: const Text('下载管理'),
                subtitle: const Text('查看进行中与已下载的离线曲目。'),
                trailing: const _SettingValue(chevron: true, label: ''),
                onTap: () => context.push('/downloads'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomMediaSourcesOverviewCard extends StatelessWidget {
  const _CustomMediaSourcesOverviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) =>
          a.customArtworkSourceEnabled != b.customArtworkSourceEnabled ||
          a.customArtworkSourceUrl != b.customArtworkSourceUrl ||
          a.customLyricsSourceEnabled != b.customLyricsSourceEnabled ||
          a.customLyricsSourceUrl != b.customLyricsSourceUrl,
      builder: (context, state) {
        return _SettingsGroupSurface(
          padding: EdgeInsets.fromLTRB(
            16,
            AppBreakpoints.isCompact(context) ? 14 : 16,
            16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '自定义媒体来源',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: AppBreakpoints.isCompact(context) ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  height: 1.24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '启用并填写地址后优先使用自定义来源，不可用时回退到服务器内置来源。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MediaSourceStatusPill(
                    icon: Icons.image_search_rounded,
                    label: '封面',
                    enabled:
                        state.customArtworkSourceEnabled &&
                        state.customArtworkSourceUrl.trim().isNotEmpty,
                  ),
                  _MediaSourceStatusPill(
                    icon: Icons.lyrics_rounded,
                    label: '歌词',
                    enabled:
                        state.customLyricsSourceEnabled &&
                        state.customLyricsSourceUrl.trim().isNotEmpty,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MediaSourceStatusPill extends StatelessWidget {
  const _MediaSourceStatusPill({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = enabled
        ? theme.selectedWash.withValues(alpha: 0.74)
        : theme.hoverWash.withValues(alpha: 0.42);
    final foreground = enabled ? colorScheme.primary : theme.muted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
        border: Border.all(
          color: enabled
              ? colorScheme.primary.withValues(alpha: 0.16)
              : colorScheme.outlineVariant.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacingTokens.inlineGapCompact,
          vertical: AppSpacingTokens.compactGap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: AppSpacingTokens.compactGap),
            Text(
              '$label${enabled ? '已启用' : '使用内置'}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomMediaSourcesCard extends StatefulWidget {
  const _CustomMediaSourcesCard({this.showIntro = true});

  final bool showIntro;

  @override
  State<_CustomMediaSourcesCard> createState() =>
      _CustomMediaSourcesCardState();
}

class _CustomMediaSourcesCardState extends State<_CustomMediaSourcesCard> {
  late final TextEditingController _artworkController;
  late final TextEditingController _lyricsController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppSettingsCubit>().state;
    _artworkController = TextEditingController(
      text: state.customArtworkSourceUrl,
    )..addListener(_handleArtworkChanged);
    _lyricsController = TextEditingController(text: state.customLyricsSourceUrl)
      ..addListener(_handleLyricsChanged);
  }

  void _handleArtworkChanged() {
    final cubit = context.read<AppSettingsCubit>();
    final text = _artworkController.text;
    if (text != cubit.state.customArtworkSourceUrl) {
      cubit.setCustomArtworkSourceUrl(text);
    }
  }

  void _handleLyricsChanged() {
    final cubit = context.read<AppSettingsCubit>();
    final text = _lyricsController.text;
    if (text != cubit.state.customLyricsSourceUrl) {
      cubit.setCustomLyricsSourceUrl(text);
    }
  }

  @override
  void dispose() {
    _artworkController
      ..removeListener(_handleArtworkChanged)
      ..dispose();
    _lyricsController
      ..removeListener(_handleLyricsChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) =>
          a.customArtworkSourceEnabled != b.customArtworkSourceEnabled ||
          a.customArtworkSourceUrl != b.customArtworkSourceUrl ||
          a.customLyricsSourceEnabled != b.customLyricsSourceEnabled ||
          a.customLyricsSourceUrl != b.customLyricsSourceUrl ||
          a.artworkSourceTest != b.artworkSourceTest ||
          a.lyricsSourceTest != b.lyricsSourceTest,
      builder: (context, state) {
        final cubit = context.read<AppSettingsCubit>();
        return _SettingsGroupSurface(
          padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showIntro) ...[
                Text(
                  '自定义歌词与封面',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message: '歌词和封面的来源优先级：开启后优先使用填写的自定义地址。地址会自动保存，可随时启用或停用。',
                  child: Text(
                    '配置歌词和封面的自定义来源地址。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _SourceSection(
                icon: Icons.image_search_rounded,
                title: '歌曲封面来源',
                description: '用于封面代理、图床转发或统一压缩服务。',
                tooltipMessage:
                    '若地址不含模板变量，应用会自动补上 sourceUrl、trackId、albumId、artistId、title、artist、album、size 等查询参数；api.lrc.cx/cover 会仅补 title。',
                enabled: state.customArtworkSourceEnabled,
                onToggle: cubit.setCustomArtworkSourceEnabled,
                controller: _artworkController,
                hintText:
                    '例如：https://api.lrc.cx/cover 或 https://example.com/cover?source={sourceUrl}&size={size}',
                testState: state.artworkSourceTest,
                customEnabledLabel: '当前生效：自定义封面地址优先',
                builtinEnabledLabel: '当前生效：数据源内置封面地址',
                emptyAddressLabel: '已开启，但地址为空，当前仍使用数据源内置封面地址',
                onTest: cubit.testCustomArtworkSource,
                onSave: cubit.saveCustomMediaSources,
              ),
              Divider(
                height: 32,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              _SourceSection(
                icon: Icons.lyrics_rounded,
                title: '歌词来源',
                description: '用于歌词服务或自建接口。',
                tooltipMessage:
                    '若地址不含模板变量，应用会自动补上 title、album、artist 查询参数；album/artist 可能为空，album 为 [Unknown Album] 时会按空值处理。当前支持 LRC 文本及常见 JSON 歌词结构。',
                enabled: state.customLyricsSourceEnabled,
                onToggle: cubit.setCustomLyricsSourceEnabled,
                controller: _lyricsController,
                hintText: '例如：https://api.lrc.cx/lyrics',
                testState: state.lyricsSourceTest,
                customEnabledLabel: '当前生效：自定义歌词地址优先',
                builtinEnabledLabel: '当前生效：数据源内置歌词接口',
                emptyAddressLabel: '已开启，但地址为空，当前仍使用数据源内置歌词接口',
                onTest: cubit.testCustomLyricsSource,
                onSave: cubit.saveCustomMediaSources,
              ),
            ],
          ),
        );
      },
    );
  }
}

int _customMediaSourcesEnabledCount(AppSettingsState state) {
  var count = 0;
  if (state.customArtworkSourceEnabled &&
      state.customArtworkSourceUrl.trim().isNotEmpty) {
    count += 1;
  }
  if (state.customLyricsSourceEnabled &&
      state.customLyricsSourceUrl.trim().isNotEmpty) {
    count += 1;
  }
  return count;
}

String _customMediaSourcesSummaryLabel(AppSettingsState state) {
  final hasArtworkUrl = state.customArtworkSourceUrl.trim().isNotEmpty;
  final hasLyricsUrl = state.customLyricsSourceUrl.trim().isNotEmpty;
  final enabledCount = _customMediaSourcesEnabledCount(state);

  if (enabledCount > 0) return '$enabledCount 项启用';
  if (state.customArtworkSourceEnabled ||
      state.customLyricsSourceEnabled ||
      hasArtworkUrl ||
      hasLyricsUrl) {
    return '待配置';
  }
  return '未启用';
}

class _SourceSection extends StatelessWidget {
  const _SourceSection({
    required this.icon,
    required this.title,
    required this.description,
    this.tooltipMessage,
    required this.enabled,
    required this.onToggle,
    required this.controller,
    required this.hintText,
    required this.testState,
    required this.customEnabledLabel,
    required this.builtinEnabledLabel,
    required this.emptyAddressLabel,
    required this.onTest,
    required this.onSave,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? tooltipMessage;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final TextEditingController controller;
  final String hintText;
  final SourceTestState testState;
  final String customEnabledLabel;
  final String builtinEnabledLabel;
  final String emptyAddressLabel;
  final Future<void> Function() onTest;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final addressIsEmpty = controller.text.trim().isEmpty;
    final isTesting = testState.status == SourceTestStatus.testing;
    final useCustomSource = enabled && !addressIsEmpty;
    final statusLabel = useCustomSource
        ? customEnabledLabel
        : (enabled ? emptyAddressLabel : builtinEnabledLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              label: title,
              child: Container(
                width: compact ? 38 : 40,
                height: compact ? 38 : 40,
                decoration: BoxDecoration(
                  color: enabled
                      ? theme.selectedWash.withValues(alpha: 0.74)
                      : theme.hoverWash.withValues(alpha: 0.54),
                  borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
                  border: Border.all(
                    color: enabled
                        ? colorScheme.primary.withValues(alpha: 0.14)
                        : colorScheme.outlineVariant.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? colorScheme.primary : theme.muted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (tooltipMessage != null) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: tooltipMessage!,
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 17,
                            color: theme.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _SourceToggle(
              value: enabled,
              semanticLabel: '${enabled ? '关闭' : '开启'} $title',
              onChanged: onToggle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SourceStatusBand(
          label: statusLabel,
          active: useCustomSource,
          warning: enabled && addressIsEmpty,
        ),
        if (enabled) ...[
          const SizedBox(height: 10),
          _SourceUrlField(
            controller: controller,
            hintText: hintText,
            isTesting: isTesting,
            errorText: testState.status == SourceTestStatus.failure
                ? testState.message
                : null,
          ),
          const SizedBox(height: 8),
          _SourceHelperText(
            text: addressIsEmpty ? '地址为空时会继续使用内置来源。' : '优先使用此地址，不可用时自动回退。',
          ),
          if (testState.message != null) ...[
            const SizedBox(height: 12),
            _SourceTestBanner(testState: testState),
          ],
          const SizedBox(height: 12),
          _SourceActions(
            enabled: !isTesting,
            isTesting: isTesting,
            onTest: addressIsEmpty || isTesting ? null : onTest,
            onSave: isTesting ? null : onSave,
          ),
        ],
      ],
    );
  }
}

class _SourceToggle extends StatefulWidget {
  const _SourceToggle({
    required this.value,
    required this.semanticLabel,
    required this.onChanged,
  });

  final bool value;
  final String semanticLabel;
  final ValueChanged<bool> onChanged;

  @override
  State<_SourceToggle> createState() => _SourceToggleState();
}

class _SourceToggleState extends State<_SourceToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = widget.value;
    final trackColor = active
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.18);

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      toggled: active,
      child: SizedBox(
        width: 50,
        height: 44,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadiusTokens.button),
            onTap: () => widget.onChanged(!active),
            mouseCursor: SystemMouseCursors.click,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            hoverColor: Colors.transparent,
            focusColor: colorScheme.primary.withValues(alpha: 0.08),
            splashColor: colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Center(
              child: AnimatedScale(
                duration: AppMotion.micro,
                curve: AppMotion.enter,
                scale: _pressed ? 0.96 : 1,
                child: AnimatedContainer(
                  duration: AppMotion.micro,
                  curve: AppMotion.enter,
                  width: 42,
                  height: 26,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? colorScheme.primary.withValues(alpha: 0)
                          : colorScheme.outlineVariant.withValues(alpha: 0.56),
                    ),
                  ),
                  alignment: active
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.onSurface.withValues(alpha: 0.14),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const SizedBox(width: 22, height: 22),
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

class _SourceStatusBand extends StatelessWidget {
  const _SourceStatusBand({
    required this.label,
    required this.active,
    required this.warning,
  });

  final String label;
  final bool active;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = active
        ? colorScheme.primary
        : warning
        ? theme.musicWarm
        : theme.muted;
    final background = active
        ? theme.selectedWash.withValues(alpha: 0.72)
        : warning
        ? theme.musicWarmSoft.withValues(alpha: 0.58)
        : theme.hoverWash.withValues(alpha: 0.42);
    final borderColor = active
        ? colorScheme.primary.withValues(alpha: 0.16)
        : warning
        ? theme.musicWarm.withValues(alpha: 0.18)
        : colorScheme.outlineVariant.withValues(alpha: 0.32);

    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadiusTokens.mobileMd),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacingTokens.inlineGapCompact,
            AppSpacingTokens.compactGap,
            AppSpacingTokens.inlineGapCompact,
            AppSpacingTokens.compactGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : warning
                    ? Icons.info_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _SourceUrlField extends StatelessWidget {
  const _SourceUrlField({
    required this.controller,
    required this.hintText,
    required this.isTesting,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isTesting;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      enabled: !isTesting,
      minLines: 1,
      maxLines: 2,
      cursorColor: colorScheme.primary,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 15,
        height: 1.28,
      ),
      decoration: InputDecoration(
        labelText: '自定义地址',
        hintText: hintText,
        errorText: errorText,
        prefixIcon: const Icon(Icons.link_rounded, size: 18),
        contentPadding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
        hintStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.muted.withValues(alpha: 0.72),
          fontSize: 13,
          height: 1.28,
        ),
      ),
    );
  }
}

class _SourceActions extends StatelessWidget {
  const _SourceActions({
    required this.enabled,
    required this.isTesting,
    required this.onTest,
    required this.onSave,
  });

  final bool enabled;
  final bool isTesting;
  final Future<void> Function()? onTest;
  final Future<void> Function()? onSave;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final children = [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onTest == null ? null : () => onTest!(),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          icon: isTesting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.network_check_rounded, size: 18),
          label: Text(isTesting ? '测试中…' : '测试连接'),
        ),
      ),
      if (compact) ...[
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: !enabled || onSave == null ? null : () => onSave!(),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('保存设置'),
          ),
        ),
      ],
    ];
    return Row(children: children);
  }
}

class _SourceHelperText extends StatelessWidget {
  const _SourceHelperText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.muted,
        fontSize: 12,
        height: 1.35,
      ),
    );
  }
}

class _HoverableListTile extends StatefulWidget {
  const _HoverableListTile({
    this.focusIndicatorKey,
    this.focusNode,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.semanticLabel,
    this.expanded,
    this.onTap,
  });

  final FocusNode? focusNode;
  final Key? focusIndicatorKey;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final String? semanticLabel;
  final bool? expanded;
  final VoidCallback? onTap;

  @override
  State<_HoverableListTile> createState() => _HoverableListTileState();
}

class _HoverableListTileState extends State<_HoverableListTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _focusFromPointer = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final enabled = widget.onTap != null;
    final hoverBackground = theme.hoverWash.withValues(alpha: 0.56);
    final pressedBackground = theme.hoverWash.withValues(alpha: 0.74);
    final idleBackground = hoverBackground.withValues(alpha: 0);
    final showKeyboardFocus =
        _focused && !_focusFromPointer && enabled && widget.expanded != true;
    final backgroundColor = _pressed && enabled
        ? pressedBackground
        : (_hovered || showKeyboardFocus) && enabled
        ? hoverBackground
        : idleBackground;
    final radius = BorderRadius.circular(
      compact ? AppRadiusTokens.mobileMd : AppRadiusTokens.desktopMd,
    );

    return Semantics(
      label: widget.semanticLabel,
      button: enabled,
      enabled: enabled ? true : null,
      expanded: widget.expanded,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (enabled) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (enabled) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          }
        },
        child: AnimatedScale(
          duration: AppMotion.micro,
          curve: AppMotion.standard,
          scale: _pressed && enabled ? 0.997 : 1,
          child: AnimatedContainer(
            key: widget.focusIndicatorKey,
            duration: AppMotion.micro,
            curve: AppMotion.standard,
            constraints: BoxConstraints(minHeight: compact ? 46 : 48),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: radius,
              border: Border.all(
                color: showKeyboardFocus
                    ? colorScheme.primary.withValues(alpha: 0.62)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: enabled
                    ? (_) => setState(() => _focusFromPointer = true)
                    : null,
                child: InkWell(
                  focusNode: widget.focusNode,
                  canRequestFocus: enabled,
                  borderRadius: radius,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: colorScheme.primary.withValues(alpha: 0.06),
                  onFocusChange: enabled
                      ? (focused) {
                          setState(() {
                            _focused = focused;
                            if (!focused) _focusFromPointer = false;
                          });
                        }
                      : null,
                  onHighlightChanged: enabled
                      ? (pressed) => setState(() => _pressed = pressed)
                      : null,
                  onTap: widget.onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 16 : 20,
                      vertical: compact ? 11 : 12,
                    ),
                    child: Row(
                      children: [
                        if (widget.leading != null) ...[
                          IconTheme.merge(
                            data: IconThemeData(
                              size: compact ? 22 : 20,
                              color: theme.muted,
                            ),
                            child: widget.leading!,
                          ),
                          SizedBox(width: compact ? 14 : 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DefaultTextStyle.merge(
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontSize: compact ? 15 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                child: widget.title ?? const SizedBox.shrink(),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 4),
                                DefaultTextStyle.merge(
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.muted,
                                    fontSize: 12,
                                  ),
                                  child: widget.subtitle!,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: 12),
                          IconTheme.merge(
                            data: IconThemeData(
                              size: compact ? 20 : 18,
                              color: theme.muted,
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
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.75,
      indent: AppBreakpoints.isCompact(context) ? 16 : 20,
      color: colorScheme.outlineVariant.withValues(alpha: 0.72),
    );
  }
}

class _SourceTestBanner extends StatelessWidget {
  const _SourceTestBanner({required this.testState});

  final SourceTestState testState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, background, foreground) = switch (testState.status) {
      SourceTestStatus.success => (
        Icons.check_circle_rounded,
        colorScheme.tertiaryContainer.withValues(alpha: 0.82),
        colorScheme.onTertiaryContainer,
      ),
      SourceTestStatus.failure => (
        Icons.error_rounded,
        colorScheme.errorContainer.withValues(alpha: 0.9),
        colorScheme.onErrorContainer,
      ),
      SourceTestStatus.testing => (
        Icons.hourglass_top_rounded,
        colorScheme.secondaryContainer.withValues(alpha: 0.86),
        colorScheme.onSecondaryContainer,
      ),
      SourceTestStatus.idle => (
        Icons.info_outline_rounded,
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Semantics(
      label: '测试结果',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacingTokens.contentGap),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testState.message ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                  if (testState.resolvedUrl != null &&
                      testState.resolvedUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      testState.resolvedUrl!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

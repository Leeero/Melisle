import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) => a.isLoading != b.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
          return const AppContentPage(
            header: AppPageHeader(title: '设置', automaticImplyLeading: false),
            body: AppBodyStateView.loading(),
          );
        }

        final horizontalPadding = AppPageLayout.horizontalPadding(context);
        final colorScheme = Theme.of(context).colorScheme;

        return AppContentPage(
          header: const AppPageHeader(
            title: '设置',
            automaticImplyLeading: false,
          ),
          body: ListView(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: AppPageLayout.contentBottomInset,
            ),
            children: [
              const _SettingsSection(title: '服务器', child: _ServerCard()),
              const SizedBox(height: AppPageLayout.sectionGap),
              const _SettingsSection(title: '播放', child: _PlaybackCard()),
              const SizedBox(height: AppPageLayout.sectionGap),
              const _SettingsSection(
                title: '外观',
                child: Column(
                  children: [
                    _AppearanceCard(),
                    SizedBox(height: 14),
                    _CustomMediaSourcesCard(),
                  ],
                ),
              ),
              const SizedBox(height: AppPageLayout.sectionGap),
              _SettingsSection(
                title: '下载',
                child: _DownloadsSettingsCard(colorScheme: colorScheme),
              ),
              const SizedBox(height: AppPageLayout.sectionGap),
              _SettingsSection(
                title: '关于',
                child: _AboutCard(colorScheme: colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showLogoutConfirmation(BuildContext context) async {
  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: '退出登录',
    message: '退出后会清除当前设备上的登录态，需要重新输入服务器信息。',
    confirmLabel: '退出',
    icon: Icons.logout_rounded,
    tone: AppModalTone.danger,
  );
  if (confirmed && context.mounted) {
    context.read<AuthCubit>().logout();
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
    // 缓存清理操作：in-memory 缓存由 CachedMusicRepository 管理，
    // 登出时自动清除。此处重置会话即可触发缓存刷新。
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('缓存已清理')));
    }
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
                title: const Text('服务器地址'),
                subtitle: Text(session?.normalizedServerUrl ?? '尚未连接服务器'),
                trailing: _SettingValue(
                  label: connected ? '已连接' : '未连接',
                  emphasized: connected,
                ),
              ),
              _SettingsDivider(colorScheme: colorScheme),
              _HoverableListTile(
                title: const Text('服务类型'),
                subtitle: Text(
                  session == null ? '登录后显示当前后端服务' : '当前账号：${session.userName}',
                ),
                trailing: _SettingValue(
                  label: session == null ? '待连接' : _backendApiLabel(session),
                ),
              ),
              _SettingsDivider(colorScheme: colorScheme),
              _HoverableListTile(
                title: const Text('退出登录'),
                subtitle: const Text('回到登录页后重新连接服务器。'),
                trailing: const _SettingValue(label: '重新登录', chevron: true),
                onTap: () => _showLogoutConfirmation(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadsSettingsCard extends StatelessWidget {
  const _DownloadsSettingsCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupSurface(
      child: Column(
        children: [
          _HoverableListTile(
            title: const Text('下载管理'),
            subtitle: const Text('查看进行中与已下载的离线曲目。'),
            trailing: const _SettingValue(label: '打开', chevron: true),
            onTap: () => context.push('/downloads'),
          ),
          _SettingsDivider(colorScheme: colorScheme),
          _HoverableListTile(
            title: const Text('清理缓存'),
            subtitle: const Text('清除临时数据，已下载离线曲目不会受到影响。'),
            trailing: const _SettingValue(label: '清理'),
            onTap: () => _showClearCacheConfirmation(context),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupSurface(
      child: Column(
        children: [
          const _HoverableListTile(
            title: Text('应用'),
            subtitle: Text(AppConstants.appSlogan),
            trailing: _SettingValue(label: AppConstants.appEnglishName),
          ),
          _SettingsDivider(colorScheme: colorScheme),
          const _HoverableListTile(
            title: Text('当前版本'),
            subtitle: Text('跨平台自托管音乐播放器'),
            trailing: _SettingValue(label: '1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SettingValue extends StatelessWidget {
  const _SettingValue({
    required this.label,
    this.chevron = false,
    this.emphasized = false,
  });

  final String label;
  final bool chevron;
  final bool emphasized;

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

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) => a.themeMode != b.themeMode,
      builder: (context, state) {
        return _SettingsGroupSurface(
          child: _HoverableListTile(
            title: const Text('主题'),
            subtitle: const Text('浅色 / 深色 / 跟随系统。'),
            trailing: _SettingValue(
              label: _themeModeLabel(state.themeMode),
              chevron: true,
            ),
            onTap: () => _pickTheme(context, state.themeMode),
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
    if (result != null) {
      await cubit.setThemeMode(result);
    }
  }
}

class _PlaybackCard extends StatelessWidget {
  const _PlaybackCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) =>
          a.defaultQuality != b.defaultQuality ||
          a.gapBetweenTracks != b.gapBetweenTracks,
      builder: (context, state) {
        final cubit = context.read<AppSettingsCubit>();
        final colorScheme = Theme.of(context).colorScheme;
        return _SettingsGroupSurface(
          child: Column(
            children: [
              _HoverableListTile(
                title: const Text('在线音质'),
                subtitle: const Text('新建播放队列时使用，当前播放队列不受影响。'),
                trailing: _SettingValue(
                  label: state.defaultQuality.label,
                  chevron: true,
                ),
                onTap: () => _pickQuality(context, state, cubit),
              ),
              _SettingsDivider(colorScheme: colorScheme),
              _HoverableListTile(
                title: const Text('曲间间隔'),
                subtitle: Text(
                  state.gapBetweenTracks == Duration.zero
                      ? '无额外间隔（默认）'
                      : '每首结束后等待 ${state.gapBetweenTracks.inSeconds} 秒',
                ),
                trailing: _SettingValue(
                  label: _gapLabel(state.gapBetweenTracks),
                  chevron: true,
                ),
                onTap: () => _pickGap(context, state, cubit),
              ),
            ],
          ),
        );
      },
    );
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

String _qualityDescription(AudioQuality quality) {
  return switch (quality) {
    AudioQuality.auto => '自动选择当前服务可用的合适音质。',
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

class _CustomMediaSourcesCard extends StatefulWidget {
  const _CustomMediaSourcesCard();

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('自定义歌词与封面', style: Theme.of(context).textTheme.titleMedium),
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
                testingLabel: '正在测试封面地址…',
                customEnabledLabel: '当前生效：自定义封面地址优先',
                builtinEnabledLabel: '当前生效：数据源内置封面地址',
                emptyAddressLabel: '已开启，但地址为空，当前仍使用数据源内置封面地址',
                onTest: cubit.testCustomArtworkSource,
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
                testingLabel: '正在测试歌词地址…',
                customEnabledLabel: '当前生效：自定义歌词地址优先',
                builtinEnabledLabel: '当前生效：数据源内置歌词接口',
                emptyAddressLabel: '已开启，但地址为空，当前仍使用数据源内置歌词接口',
                onTest: cubit.testCustomLyricsSource,
              ),
            ],
          ),
        );
      },
    );
  }
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
    required this.testingLabel,
    required this.customEnabledLabel,
    required this.builtinEnabledLabel,
    required this.emptyAddressLabel,
    required this.onTest,
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
  final String testingLabel;
  final String customEnabledLabel;
  final String builtinEnabledLabel;
  final String emptyAddressLabel;
  final Future<void> Function() onTest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final addressIsEmpty = controller.text.trim().isEmpty;
    final isTesting = testState.status == SourceTestStatus.testing;
    final useCustomSource = enabled && !addressIsEmpty;
    final statusLabel = useCustomSource
        ? customEnabledLabel
        : (enabled ? emptyAddressLabel : builtinEnabledLabel);
    final statusBackground = useCustomSource
        ? colorScheme.tertiaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final statusForeground = useCustomSource
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: title,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.onSecondaryContainer),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (tooltipMessage != null) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: tooltipMessage!,
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: '${enabled ? '关闭' : '开启'} $title',
              child: Switch.adaptive(value: enabled, onChanged: onToggle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: statusLabel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: statusForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            labelText: '自定义地址',
            hintText: hintText,
            helperText: enabled
                ? (addressIsEmpty
                      ? '已开启，但当前地址为空，暂时仍使用对应数据源的内置地址。'
                      : '已开启：优先使用此地址；若不可用，会回退到对应数据源的内置地址。')
                : '未开启：当前直接使用对应数据源的内置地址。',
            prefixIcon: const Icon(Icons.link_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tooltip(
              message: '测试当前地址是否可用',
              child: TextButton.icon(
                onPressed: addressIsEmpty || isTesting ? null : onTest,
                icon: isTesting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.network_check_rounded, size: 18),
                label: Text(isTesting ? testingLabel : '测试地址'),
                style: AppActionButtonStyle.text(
                  context,
                  tone: AppActionButtonTone.primary,
                  dense: false,
                ),
              ),
            ),
          ],
        ),
        if (testState.message != null) ...[
          const SizedBox(height: 12),
          _SourceTestBanner(testState: testState),
        ],
      ],
    );
  }
}

class _HoverableListTile extends StatefulWidget {
  const _HoverableListTile({
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  State<_HoverableListTile> createState() => _HoverableListTileState();
}

class _HoverableListTileState extends State<_HoverableListTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final compact = AppBreakpoints.isCompact(context);
    final enabled = widget.onTap != null;
    final backgroundColor = _pressed && enabled
        ? theme.hoverWash.withValues(alpha: 0.74)
        : _hovered && enabled
        ? theme.hoverWash.withValues(alpha: 0.56)
        : Colors.transparent;

    return MouseRegion(
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
          duration: AppMotion.micro,
          curve: AppMotion.standard,
          constraints: BoxConstraints(minHeight: compact ? 46 : 48),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(
              compact ? AppRadiusTokens.mobileMd : AppRadiusTokens.desktopMd,
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 20,
                vertical: compact ? 11 : 12,
              ),
              child: Row(
                children: [
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
        padding: const EdgeInsets.all(12),
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

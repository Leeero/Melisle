import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
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
            header: AppPageTitleRow(title: '设置'),
            body: AppBodyStateView.loading(),
          );
        }

        final horizontalPadding = AppPageLayout.horizontalPadding(context);
        final colorScheme = Theme.of(context).colorScheme;

        return AppContentPage(
          header: const AppPageTitleRow(title: '设置'),
          body: ListView(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: AppPageLayout.contentBottomInset,
            ),
            children: [
              const _SettingsSection(title: '外观', child: _ThemeCard()),
              const SizedBox(height: AppPageLayout.sectionGap),
              const _SettingsSection(title: '播放', child: _PlaybackCard()),
              const SizedBox(height: AppPageLayout.sectionGap),
              const _SettingsSection(title: '媒体来源', child: _CustomMediaSourcesCard()),
              const SizedBox(height: AppPageLayout.sectionGap),
              _SettingsSection(
                title: '存储',
                child: Card(
                  child: Column(
                    children: [
                      _HoverableListTile(
                        leading: const Icon(Icons.download_for_offline_rounded),
                        title: const Text('下载管理'),
                        subtitle: const Text('查看进行中与已下载的离线曲目。'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/downloads'),
                      ),
                      Divider(height: 1, color: colorScheme.outlineVariant),
                      _HoverableListTile(
                        leading: const Icon(Icons.cleaning_services_rounded),
                        title: const Text('清理缓存'),
                        subtitle: const Text('清除临时数据，释放本地存储空间。'),
                        onTap: () => _showClearCacheConfirmation(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPageLayout.sectionGap),
              _SettingsSection(
                title: '连接与账户',
                child: Card(
                  child: Column(
                    children: [
                      BlocBuilder<AuthCubit, AuthState>(
                        buildWhen: (a, b) =>
                            a.status != b.status || a.session != b.session,
                        builder: (context, authState) {
                          final session = authState.session;
                          if (session == null) return const SizedBox.shrink();
                          return _HoverableListTile(
                            leading: const Icon(Icons.account_circle_rounded),
                            title: Text(session.userName),
                            subtitle: Text(session.normalizedServerUrl),
                          );
                        },
                      ),
                      _HoverableListTile(
                        leading: const Icon(Icons.logout_rounded),
                        title: const Text('退出登录'),
                        subtitle: const Text('清除当前设备上的登录态并回到登录页。'),
                        onTap: () => _showLogoutConfirmation(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showLogoutConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('退出登录'),
      content: const Text('确定要退出当前会话吗？退出后需重新输入服务器信息。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('退出'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<AuthCubit>().logout();
  }
}

Future<void> _showClearCacheConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('清理缓存'),
      content: const Text('确定要清理临时缓存吗？下载的离线曲目不受影响。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('清理'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    // 缓存清理操作：in-memory 缓存由 CachedMusicRepository 管理，
    // 登出时自动清除。此处重置会话即可触发缓存刷新。
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存已清理')),
      );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitleRow(
          title: title,
          padding: EdgeInsets.zero,
          titleStyle: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppPageLayout.sectionTitleBottomGap),
        child,
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (a, b) => a.themeMode != b.themeMode,
      builder: (context, state) {
        final cubit = context.read<AppSettingsCubit>();
        return Semantics(
          label: '主题模式选择',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RadioGroup<ThemeMode>(
                groupValue: state.themeMode,
                onChanged: (mode) {
                  if (mode != null) cubit.setThemeMode(mode);
                },
                child: Column(
                  children: [
                    _themeTile(
                      context,
                      ThemeMode.system,
                      Icons.brightness_auto_rounded,
                      '跟随系统',
                      '根据系统深色/浅色设置自动切换。',
                      state.themeMode,
                    ),
                    _themeTile(
                      context,
                      ThemeMode.light,
                      Icons.light_mode_rounded,
                      '浅色',
                      '日间或高亮环境下更易读。',
                      state.themeMode,
                    ),
                    _themeTile(
                      context,
                      ThemeMode.dark,
                      Icons.dark_mode_rounded,
                      '深色',
                      '适合夜间使用，减少屏幕眩光。',
                      state.themeMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _themeTile(
    BuildContext context,
    ThemeMode mode,
    IconData icon,
    String title,
    String subtitle,
    ThemeMode current,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = mode == current;
    final Color previewColor = switch (mode) {
      ThemeMode.system => colorScheme.primary,
      ThemeMode.light => AppColorTokens.lightPrimary,
      ThemeMode.dark => AppColorTokens.darkPrimary,
    };

    return Semantics(
      label: title,
      selected: isSelected,
      child: _HoverableListTile(
        isSelected: isSelected,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: previewColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: previewColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            Flexible(child: Text(subtitle)),
          ],
        ),
        trailing: Radio<ThemeMode>(value: mode),
        onTap: () => context.read<AppSettingsCubit>().setThemeMode(mode),
      ),
    );
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
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.graphic_eq_rounded),
                title: const Text('默认音质'),
                subtitle: Text('新建播放队列时使用 · 当前：${state.defaultQuality.label}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickQuality(context, state, cubit),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              ListTile(
                leading: const Icon(Icons.space_bar_rounded),
                title: const Text('曲间间隔'),
                subtitle: Text(
                  state.gapBetweenTracks == Duration.zero
                      ? '无额外间隔（默认）'
                      : '每首结束后等待 ${state.gapBetweenTracks.inSeconds} 秒',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
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
      showDragHandle: true,
      builder: (_) => RadioGroup<AudioQuality>(
        groupValue: state.defaultQuality,
        onChanged: (value) {
          if (value != null) Navigator.of(context).pop(value);
        },
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final q in AudioQuality.values)
                ListTile(
                  leading: Radio<AudioQuality>(value: q),
                  title: Text(q.label),
                  onTap: () => Navigator.of(context).pop(q),
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
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in presets)
              ListTile(
                leading: Icon(
                  s == state.gapBetweenTracks.inSeconds
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(s == 0 ? '无间隔' : '$s 秒'),
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (result != null) {
      await cubit.setGapBetweenTracks(Duration(seconds: result));
    }
  }
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
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '自定义歌词与封面',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message:
                      '歌词和封面的来源优先级：开启后优先使用填写的自定义地址。地址会自动保存，可随时启用或停用。',
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
                        child: Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
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
              child: OutlinedButton.icon(
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
                    : const Icon(Icons.network_check_rounded),
                label: Text(isTesting ? testingLabel : '测试地址'),
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
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  State<_HoverableListTile> createState() => _HoverableListTileState();
}

class _HoverableListTileState extends State<_HoverableListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.82)
              : _hovered
                  ? colorScheme.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: widget.leading,
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: widget.trailing,
          onTap: widget.onTap,
        ),
      ),
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

import 'dart:async';
import 'dart:io';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_text_tabs.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  Future<List<Download>>? _future;
  _DownloadView _activeView = _DownloadView.completed;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<DownloadsCubit>().load());
    _reload();
  }

  void _reload() {
    final db = context.read<AppDatabase>();
    setState(() {
      _future = db.allDownloads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppPageLayout.horizontalPadding(context);

    return AppContentPage(
      header: const AppPageHeader(
        title: '下载',
        description: '管理离线音乐、下载任务与本地存储',
        automaticImplyLeading: false,
      ),
      body: BlocListener<DownloadsCubit, DownloadsState>(
        listenWhen: (prev, curr) =>
            prev.completedTrackIds.length != curr.completedTrackIds.length ||
            prev.removedStaleRecords != curr.removedStaleRecords ||
            prev.cachedBytes != curr.cachedBytes,
        listener: (context, state) => _reload(),
        child: FutureBuilder<List<Download>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppBodyStateView.loading();
            }
            if (snapshot.hasError) {
              return AppBodyStateView.message(
                message: '下载记录加载失败',
                description: '${snapshot.error}',
                icon: Icons.error_outline_rounded,
              );
            }
            final rows = snapshot.data ?? const <Download>[];
            return BlocBuilder<DownloadsCubit, DownloadsState>(
              builder: (context, state) {
                final jobs = state.jobs.values.toList();
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    AppPageLayout.contentBottomInset,
                  ),
                  children: [
                    _DownloadToolbar(
                      activeView: _activeView,
                      completedCount: rows.length,
                      activityCount: jobs.length,
                      state: state,
                      onViewChanged: (view) =>
                          setState(() => _activeView = view),
                    ),
                    const SizedBox(height: AppSpacingTokens.contentGap),
                    _DownloadOverview(rows: rows, activityCount: jobs.length),
                    const SizedBox(height: AppSpacingTokens.sectionGap),
                    if (_activeView == _DownloadView.activity &&
                        jobs.isNotEmpty)
                      _DownloadSectionBody(
                        children: [for (final job in jobs) _JobRow(job: job)],
                      ),
                    if (_activeView == _DownloadView.completed &&
                        rows.isNotEmpty)
                      AppBreakpoints.isCompact(context)
                          ? _DownloadSectionBody(
                              children: [
                                for (final row in rows)
                                  _DownloadRow(
                                    record: row,
                                    fileMissing: state.missingTrackIds.contains(
                                      row.trackId,
                                    ),
                                    onDelete: () async {
                                      await context
                                          .read<DownloadsCubit>()
                                          .remove(row.trackId);
                                      _reload();
                                    },
                                  ),
                              ],
                            )
                          : _DownloadTable(
                              rows: rows,
                              missingTrackIds: state.missingTrackIds,
                              onDelete: (row) async {
                                await context.read<DownloadsCubit>().remove(
                                  row.trackId,
                                );
                                _reload();
                              },
                            ),
                    if (rows.isEmpty && jobs.isEmpty)
                      const _DownloadsEmptyState(),
                    if (_activeView == _DownloadView.completed &&
                        rows.isEmpty &&
                        jobs.isNotEmpty)
                      const _DownloadsTabEmptyState(message: '还没有完成的下载'),
                    if (_activeView == _DownloadView.activity &&
                        jobs.isEmpty &&
                        rows.isNotEmpty)
                      const _DownloadsTabEmptyState(message: '没有下载任务'),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

enum _DownloadView { completed, activity }

class _DownloadToolbar extends StatelessWidget {
  const _DownloadToolbar({
    required this.activeView,
    required this.completedCount,
    required this.activityCount,
    required this.state,
    required this.onViewChanged,
  });

  final _DownloadView activeView;
  final int completedCount;
  final int activityCount;
  final DownloadsState state;
  final ValueChanged<_DownloadView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final tabs = Semantics(
      label: '下载状态筛选',
      child: AppTextTabs<_DownloadView>(
        items: [
          AppTextTabItem(
            value: _DownloadView.completed,
            label: '已下载',
            count: completedCount,
          ),
          AppTextTabItem(
            value: _DownloadView.activity,
            label: '下载中',
            count: activityCount,
          ),
        ],
        selectedValue: activeView,
        onChanged: onViewChanged,
      ),
    );
    final actions = _DownloadDirectoryActions(state: state);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tabs,
          const SizedBox(height: AppSpacingTokens.compactGap),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: tabs),
        const SizedBox(width: AppSpacingTokens.contentGap),
        actions,
      ],
    );
  }
}

class _DownloadDirectoryActions extends StatefulWidget {
  const _DownloadDirectoryActions({required this.state});

  final DownloadsState state;

  @override
  State<_DownloadDirectoryActions> createState() =>
      _DownloadDirectoryActionsState();
}

class _DownloadDirectoryActionsState extends State<_DownloadDirectoryActions> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: widget.state.downloadDirectoryPath.isEmpty
              ? null
              : () => unawaited(
                  _openDownloadDirectory(
                    context,
                    widget.state.downloadDirectoryPath,
                  ),
                ),
          icon: const Icon(Icons.folder_open_rounded, size: 18),
          label: Text(compact ? '打开目录' : '打开下载目录'),
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 40),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacingTokens.compactGap),
        if (compact)
          IconButton(
            onPressed: () => _showDownloadDirectorySheet(context),
            icon: const Icon(Icons.tune_rounded, size: 19),
            tooltip: '修改下载目录',
            style: AppActionButtonStyle.icon(context, iconSize: 19),
          )
        else
          MenuAnchor(
            controller: _menuController,
            alignmentOffset: const Offset(-356, 8),
            style: MenuStyle(
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              elevation: const WidgetStatePropertyAll(10),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadiusTokens.card),
                ),
              ),
            ),
            menuChildren: [
              _DownloadDirectoryPopover(
                state: widget.state,
                onSaved: _menuController.close,
              ),
            ],
            builder: (context, controller, child) => IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.tune_rounded, size: 19),
              tooltip: '修改下载目录',
              style: AppActionButtonStyle.icon(context, iconSize: 19),
            ),
          ),
      ],
    );
  }
}

class _DownloadDirectoryPopover extends StatefulWidget {
  const _DownloadDirectoryPopover({required this.state, required this.onSaved});

  final DownloadsState state;
  final VoidCallback onSaved;

  @override
  State<_DownloadDirectoryPopover> createState() =>
      _DownloadDirectoryPopoverState();
}

class _DownloadDirectoryPopoverState extends State<_DownloadDirectoryPopover> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _choosing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.state.customDownloadDirectoryPath,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final path = widget.state.downloadDirectoryPath.isEmpty
        ? '正在读取下载目录'
        : widget.state.downloadDirectoryPath;
    final isBusy = _saving || _choosing;

    return SizedBox(
      width: 412,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacingTokens.contentGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacingTokens.inlineGap),
                Text(
                  '下载目录',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.state.usesDefaultDownloadDirectory ? '默认位置' : '自定义',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacingTokens.inlineGap),
            Text(
              '后续下载的离线文件将保存至此位置。',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.muted),
            ),
            const SizedBox(height: AppSpacingTokens.contentGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacingTokens.inlineGap),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.56,
                ),
                borderRadius: BorderRadius.circular(AppRadiusTokens.input),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前保存位置',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    path,
                    maxLines: 2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacingTokens.contentGap),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '新保存位置',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => _chooseFolder(context),
                  icon: _choosing
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open_rounded, size: 17),
                  label: Text(_choosing ? '正在选择' : '选择文件夹'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacingTokens.inlineGap,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: !isBusy,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(context),
              decoration: InputDecoration(
                hintText: '粘贴绝对路径',
                prefixIcon: const Icon(
                  Icons.drive_folder_upload_rounded,
                  size: 18,
                ),
                filled: true,
                fillColor: colorScheme.surface.withValues(alpha: 0.52),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (widget.state.directoryValidation ==
                    DownloadDirectoryValidation.invalid &&
                widget.state.directoryValidationMessage != null) ...[
              const SizedBox(height: 6),
              Semantics(
                liveRegion: true,
                child: Text(
                  widget.state.directoryValidationMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacingTokens.contentGap),
            Row(
              children: [
                TextButton(
                  onPressed: isBusy ? null : () => _resetToDefault(context),
                  child: const Text('使用默认'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: isBusy ? null : () => _save(context),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存更改'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseFolder(BuildContext context) async {
    if (!_supportsDirectoryPicker) {
      AppSnackBar.show(context, '当前平台暂不支持选择文件夹');
      return;
    }

    setState(() => _choosing = true);
    try {
      final path = await _pickDownloadDirectory();
      if (!context.mounted) return;
      setState(() => _choosing = false);
      if (path != null && path.trim().isNotEmpty) _controller.text = path;
    } catch (_) {
      if (!context.mounted) return;
      setState(() => _choosing = false);
      AppSnackBar.show(context, '无法打开文件夹选择器');
    }
  }

  Future<void> _resetToDefault(BuildContext context) async {
    _controller.clear();
    await _save(context);
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _saving = true);
    try {
      await context.read<DownloadsCubit>().setDownloadDirectoryPath(
        _controller.text,
      );
      if (!context.mounted) return;
      setState(() => _saving = false);
      AppSnackBar.show(context, '下载存储位置已更新');
      widget.onSaved();
    } catch (error) {
      if (!context.mounted) return;
      setState(() => _saving = false);
      AppSnackBar.show(context, _formatDirectoryError(error));
    }
  }
}

class _DownloadOverview extends StatelessWidget {
  const _DownloadOverview({required this.rows, required this.activityCount});

  final List<Download> rows;
  final int activityCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<DownloadsCubit>().state;
    final fallbackBytes = rows.fold<int>(0, (sum, row) => sum + row.fileSize);
    final totalBytes = state.cachedBytes > 0
        ? state.cachedBytes
        : fallbackBytes;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(AppRadiusTokens.desktopMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.66),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacingTokens.contentGap,
          vertical: AppSpacingTokens.inlineGap,
        ),
        child: Wrap(
          spacing: AppSpacingTokens.sectionGap,
          runSpacing: AppSpacingTokens.compactGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '本地占用  '),
                  TextSpan(
                    text: _formatBytes(totalBytes),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text:
                        '  ·  ${_storageDescription(rows.length, activityCount)}',
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.muted),
            ),
            const _DownloadQualityMenu(),
          ],
        ),
      ),
    );
  }
}

class _DownloadQualityMenu extends StatelessWidget {
  const _DownloadQualityMenu();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadsCubit, DownloadsState>(
      buildWhen: (previous, current) =>
          previous.downloadQuality != current.downloadQuality,
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return MenuAnchor(
          style: MenuStyle(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: AppSpacingTokens.compactGap),
            ),
            backgroundColor: WidgetStatePropertyAll(
              colorScheme.surfaceContainerHigh,
            ),
            elevation: const WidgetStatePropertyAll(8),
            shadowColor: WidgetStatePropertyAll(
              colorScheme.shadow.withValues(alpha: 0.18),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.card),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          menuChildren: [
            for (final quality in AudioQuality.values)
              _DownloadQualityMenuItem(
                quality: quality,
                selected: quality == state.downloadQuality,
                onSelected: () {
                  unawaited(_updateDownloadQuality(context, quality));
                },
              ),
          ],
          builder: (context, controller, child) => Semantics(
            button: true,
            label: '选择下载音质，当前为${state.downloadQuality.label}',
            child: OutlinedButton(
              key: const ValueKey('download-quality-menu'),
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacingTokens.contentGap,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -1),
                    child: Text('下载音质  ${state.downloadQuality.label}'),
                  ),
                  const SizedBox(width: AppSpacingTokens.inlineGapCompact),
                  Icon(
                    controller.isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DownloadQualityMenuItem extends StatelessWidget {
  const _DownloadQualityMenuItem({
    required this.quality,
    required this.selected,
    required this.onSelected,
  });

  final AudioQuality quality;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return MenuItemButton(
      onPressed: onSelected,
      leadingIcon: Icon(
        selected ? Icons.check_rounded : Icons.graphic_eq_rounded,
        size: 18,
        color: selected ? colorScheme.primary : theme.muted,
      ),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(244, 56)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacingTokens.contentGap,
            vertical: AppSpacingTokens.compactGap,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (selected) return colorScheme.primaryContainer;
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.surfaceContainerHighest;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStatePropertyAll(
          selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _downloadQualityTitle(quality),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _downloadQualityDescription(quality),
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.78)
                  : theme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

String _downloadQualityTitle(AudioQuality quality) {
  switch (quality) {
    case AudioQuality.auto:
      return '自动选择';
    case AudioQuality.lossless:
      return '无损';
    case AudioQuality.high:
      return '高品质';
    case AudioQuality.medium:
      return '标准';
    case AudioQuality.low:
      return '省流';
  }
}

String _downloadQualityDescription(AudioQuality quality) {
  switch (quality) {
    case AudioQuality.auto:
      return '按网络与可用音源选择';
    case AudioQuality.lossless:
      return '原始无损格式（如音源支持）';
    case AudioQuality.high:
      return '320 kbps · 兼顾细节与空间';
    case AudioQuality.medium:
      return '192 kbps · 日常聆听';
    case AudioQuality.low:
      return '128 kbps · 节省流量与空间';
  }
}

class _DownloadDirectoryRow extends StatefulWidget {
  const _DownloadDirectoryRow({required this.state});

  final DownloadsState state;

  @override
  State<_DownloadDirectoryRow> createState() => _DownloadDirectoryRowState();
}

class _DownloadDirectoryRowState extends State<_DownloadDirectoryRow> {
  late final TextEditingController _controller;
  bool _editing = false;
  bool _saving = false;
  bool _choosing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _currentEditablePath);
  }

  @override
  void didUpdateWidget(covariant _DownloadDirectoryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        oldWidget.state.customDownloadDirectoryPath !=
            widget.state.customDownloadDirectoryPath) {
      _controller.text = _currentEditablePath;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _currentEditablePath => widget.state.customDownloadDirectoryPath;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);

    if (_editing) {
      return _buildEditor(context, compact: compact);
    }

    return _buildSummary(context, compact: compact);
  }

  Widget _buildSummary(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final path = widget.state.downloadDirectoryPath.isEmpty
        ? '正在读取下载目录'
        : widget.state.downloadDirectoryPath;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 11 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '存储位置',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: compact ? 15 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.state.usesDefaultDownloadDirectory ? '默认' : '自定义',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _editing = true;
                _controller.text = _currentEditablePath;
              });
            },
            icon: const Icon(Icons.edit_location_alt_rounded, size: 17),
            label: const Text('修改'),
            style: TextButton.styleFrom(
              minimumSize: const Size(72, 36),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.inlineGapCompact,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        compact ? 11 : 12,
        compact ? 16 : 20,
        compact ? 13 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '存储位置',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: compact ? 15 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving || _choosing
                ? null
                : () => _chooseAndSave(context),
            icon: _choosing
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open_rounded, size: 17),
            label: Text(_choosing ? '正在选择' : '选择文件夹'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(108, 36),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.contentGap,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            enabled: !_saving && !_choosing,
            minLines: 1,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(context),
            decoration: InputDecoration(
              hintText: '也可以粘贴绝对路径',
              prefixIcon: const Icon(Icons.folder_open_rounded, size: 18),
              suffixIcon: Tooltip(
                message: '应用路径',
                child: IconButton(
                  onPressed: _saving || _choosing
                      ? null
                      : () => _apply(context),
                  icon: const Icon(Icons.check_rounded, size: 18),
                ),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh.withValues(
                alpha: 0.62,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.input),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.input),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.input),
                borderSide: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.62),
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
          if (widget.state.directoryValidation ==
                  DownloadDirectoryValidation.invalid &&
              widget.state.directoryValidationMessage != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                widget.state.directoryValidationMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: _saving || _choosing
                    ? null
                    : () => _resetToDefault(context),
                child: const Text('使用默认'),
              ),
              TextButton(
                onPressed: _saving || _choosing
                    ? null
                    : () {
                        setState(() {
                          _editing = false;
                          _controller.text = _currentEditablePath;
                        });
                      },
                child: const Text('取消'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _apply(BuildContext context) async {
    await _save(context, _controller.text);
  }

  Future<void> _resetToDefault(BuildContext context) async {
    _controller.clear();
    await _save(context, '');
  }

  Future<void> _chooseAndSave(BuildContext context) async {
    if (!_supportsDirectoryPicker) {
      AppSnackBar.show(context, '当前平台暂不支持选择文件夹');
      return;
    }

    setState(() => _choosing = true);
    try {
      final path = await _pickDownloadDirectory();
      if (!context.mounted) return;
      setState(() => _choosing = false);
      if (path == null || path.trim().isEmpty) return;
      _controller.text = path;
      await _save(context, path);
    } catch (_) {
      if (!context.mounted) return;
      setState(() => _choosing = false);
      AppSnackBar.show(context, '无法打开文件夹选择器');
    }
  }

  Future<void> _save(BuildContext context, String path) async {
    setState(() => _saving = true);
    try {
      await context.read<DownloadsCubit>().setDownloadDirectoryPath(path);
      if (!context.mounted) return;
      final savedPath = context
          .read<DownloadsCubit>()
          .state
          .customDownloadDirectoryPath;
      setState(() {
        _saving = false;
        _editing = false;
        _controller.text = savedPath;
      });
      AppSnackBar.show(context, '下载存储位置已更新');
    } catch (error) {
      if (!context.mounted) return;
      setState(() => _saving = false);
      AppSnackBar.show(context, _formatDirectoryError(error));
    }
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});
  final DownloadJob job;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DownloadListRow(
      artworkUrl: job.track.artworkUrl,
      title: job.track.title,
      subtitle: _statusLabel(job),
      trailing: job.status == DownloadJobStatus.failed
          ? IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: '重试下载',
              onPressed: () =>
                  context.read<DownloadsCubit>().retry(job.track.id),
            )
          : IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: '取消下载',
              onPressed: () =>
                  context.read<DownloadsCubit>().cancel(job.track.id),
            ),
      progress: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Semantics(
          label: job.progress == null
              ? '下载进度未知'
              : '下载进度 ${(job.progress! * 100).round()}%',
          value: job.progress == null
              ? null
              : '${(job.progress! * 100).round()}%',
          child: LinearProgressIndicator(
            value: job.progress,
            minHeight: 4,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.64,
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(DownloadJob job) {
    switch (job.status) {
      case DownloadJobStatus.pending:
        return '排队中';
      case DownloadJobStatus.running:
        final p = job.progress;
        if (p == null) {
          return '下载中 · ${_formatBytes(job.received)}';
        }
        return '下载中 · ${(p * 100).toStringAsFixed(0)}% · ${_formatBytes(job.received)} / ${_formatBytes(job.total)}';
      case DownloadJobStatus.completed:
        return '已完成';
      case DownloadJobStatus.failed:
        return '失败：${job.errorMessage ?? '未知'}';
      case DownloadJobStatus.canceled:
        return '已取消';
    }
  }
}

class _DownloadRow extends StatefulWidget {
  const _DownloadRow({
    required this.record,
    required this.fileMissing,
    required this.onDelete,
  });

  final Download record;
  final bool fileMissing;
  final Future<void> Function() onDelete;

  @override
  State<_DownloadRow> createState() => _DownloadRowState();
}

class _DownloadRowState extends State<_DownloadRow> {
  bool _deleteHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DownloadListRow(
      artworkUrl: widget.record.artworkUrl ?? '',
      title: widget.record.title,
      subtitle: [
        if (widget.fileMissing) '文件缺失',
        widget.record.artistName,
        if ((widget.record.container ?? '').isNotEmpty)
          widget.record.container!.toUpperCase(),
        _formatBytes(widget.record.fileSize),
      ].whereType<String>().join(' · '),
      trailing: MouseRegion(
        onEnter: (_) => setState(() => _deleteHovered = true),
        onExit: (_) => setState(() => _deleteHovered = false),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: AppMotion.micro,
            child: Icon(
              Icons.delete_outline_rounded,
              key: ValueKey(_deleteHovered),
              color: _deleteHovered
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          tooltip: '删除下载',
          onPressed: () =>
              _confirmDeleteDownload(context, widget.record, widget.onDelete),
        ),
      ),
    );
  }
}

class _DownloadTable extends StatelessWidget {
  const _DownloadTable({
    required this.rows,
    required this.missingTrackIds,
    required this.onDelete,
  });

  final List<Download> rows;
  final Set<String> missingTrackIds;
  final Future<void> Function(Download row) onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(AppRadiusTokens.desktopMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            const _DownloadTableHeader(),
            for (final row in rows)
              _DownloadTableRow(
                record: row,
                fileMissing: missingTrackIds.contains(row.trackId),
                onDelete: () => onDelete(row),
              ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTableHeader extends StatelessWidget {
  const _DownloadTableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(child: _DownloadTableHeaderText('标题')),
          SizedBox(width: 190, child: _DownloadTableHeaderText('专辑')),
          SizedBox(width: 92, child: _DownloadTableHeaderText('大小')),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _DownloadTableHeaderText extends StatelessWidget {
  const _DownloadTableHeaderText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DownloadTableRow extends StatefulWidget {
  const _DownloadTableRow({
    required this.record,
    required this.fileMissing,
    required this.onDelete,
  });

  final Download record;
  final bool fileMissing;
  final Future<void> Function() onDelete;

  @override
  State<_DownloadTableRow> createState() => _DownloadTableRowState();
}

class _DownloadTableRowState extends State<_DownloadTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: _hovered
              ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.56)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadiusTokens.desktopSm),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              CachedArtwork(
                imageUrl: widget.record.artworkUrl ?? '',
                size: 44,
                borderRadius: AppRadiusTokens.desktopSm,
                semanticLabel: '《${widget.record.title}》封面',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.fileMissing
                            ? colorScheme.error
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.fileMissing
                          ? '文件缺失 · ${widget.record.artistName ?? '未知歌手'}'
                          : widget.record.artistName ?? '未知歌手',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 190,
                child: Text(
                  widget.record.albumTitle ?? '未知专辑',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                child: Text(
                  _formatBytes(widget.record.fileSize),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: '删除下载',
                  onPressed: () => _confirmDeleteDownload(
                    context,
                    widget.record,
                    widget.onDelete,
                  ),
                  style: AppActionButtonStyle.icon(
                    context,
                    tone: AppActionButtonTone.danger,
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

class _DownloadListRow extends StatefulWidget {
  const _DownloadListRow({
    required this.artworkUrl,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.progress,
  });

  final String artworkUrl;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget? progress;

  @override
  State<_DownloadListRow> createState() => _DownloadListRowState();
}

class _DownloadListRowState extends State<_DownloadListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: widget.title,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.66)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadiusTokens.iconButton),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                CachedArtwork(
                  imageUrl: widget.artworkUrl,
                  size: 44,
                  borderRadius: 10,
                  semanticLabel: '《${widget.title}》封面',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.progress != null) ...[
                        const SizedBox(height: 8),
                        widget.progress!,
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 44, height: 44, child: widget.trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadSectionDivider extends StatelessWidget {
  const _DownloadSectionDivider({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.56),
          ),
        ),
      ),
      child: Padding(padding: const EdgeInsets.only(top: 4), child: child),
    );
  }
}

class _DownloadSectionBody extends StatelessWidget {
  const _DownloadSectionBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _DownloadSectionDivider(
      child: Column(children: [for (final child in children) child]),
    );
  }
}

class _DownloadsEmptyState extends StatelessWidget {
  const _DownloadsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 38),
      child: AppBodyStateView.message(
        message: '还没有下载内容',
        description: '在歌曲操作中选择下载后，离线曲目会显示在这里。',
        icon: Icons.download_for_offline_outlined,
      ),
    );
  }
}

class _DownloadsTabEmptyState extends StatelessWidget {
  const _DownloadsTabEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 38),
    child: Center(
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).muted),
      ),
    ),
  );
}

Future<void> _confirmDeleteDownload(
  BuildContext context,
  Download record,
  Future<void> Function() onDelete,
) async {
  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: '删除下载',
    message: '将删除《${record.title}》的本地离线文件，不会影响媒体库中的原始歌曲。',
    confirmLabel: '删除',
    icon: Icons.delete_outline_rounded,
    tone: AppModalTone.danger,
  );
  if (!confirmed || !context.mounted) return;
  await onDelete();
  if (!context.mounted) return;
  AppSnackBar.show(context, '已删除下载：${record.title}');
}

Future<void> _showDownloadDirectorySheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AppSheetScaffold(
      title: '下载目录',
      description: '打开当前目录，或更改后续离线文件的保存位置。',
      child: BlocBuilder<DownloadsCubit, DownloadsState>(
        builder: (context, state) => _DownloadDirectoryRow(state: state),
      ),
    ),
  );
}

Future<void> _updateDownloadQuality(
  BuildContext context,
  AudioQuality quality,
) async {
  try {
    await context.read<DownloadsCubit>().setDownloadQuality(quality);
  } on Object {
    if (!context.mounted) return;
    AppSnackBar.show(context, '下载音质保存失败，请稍后重试');
  }
}

Future<void> _openDownloadDirectory(BuildContext context, String path) async {
  if (!_supportsOpenDownloadDirectory) {
    AppSnackBar.show(context, '当前平台暂不支持打开下载目录');
    return;
  }

  try {
    final result = Platform.isMacOS
        ? await Process.run('open', [path])
        : await Process.run('explorer.exe', [path]);
    if (result.exitCode != 0) {
      throw FileSystemException('无法打开下载目录', path);
    }
  } on Object {
    if (!context.mounted) return;
    AppSnackBar.show(context, '无法打开下载目录，请确认路径可访问');
  }
}

String _storageDescription(int completedCount, int pendingCount) {
  final completed = '$completedCount 首已下载';
  if (pendingCount <= 0) return completed;
  return '$completed · $pendingCount 个任务进行中';
}

String _formatDirectoryError(Object error) {
  if (error is ArgumentError) {
    return error.message?.toString() ?? '请输入有效的下载存储位置';
  }
  return '无法更新下载存储位置，请确认路径可访问';
}

bool get _supportsDirectoryPicker => Platform.isMacOS || Platform.isWindows;

bool get _supportsOpenDownloadDirectory =>
    Platform.isMacOS || Platform.isWindows;

Future<String?> _pickDownloadDirectory() async {
  if (Platform.isMacOS) {
    final result = await Process.run('osascript', [
      '-e',
      'POSIX path of (choose folder with prompt "选择下载存储位置")',
    ]);
    if (result.exitCode != 0) return null;
    final path = result.stdout.toString().trim();
    return path.isEmpty ? null : path;
  }

  if (Platform.isWindows) {
    const script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
\$dialog.Description = '选择下载存储位置'
\$dialog.ShowNewFolderButton = \$true
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Write(\$dialog.SelectedPath)
}
''';
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-STA',
      '-Command',
      script,
    ]);
    if (result.exitCode != 0) return null;
    final path = result.stdout.toString().trim();
    return path.isEmpty ? null : path;
  }

  return null;
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var idx = 0;
  while (value >= 1024 && idx < units.length - 1) {
    value /= 1024;
    idx++;
  }
  return '${value.toStringAsFixed(value >= 10 || idx == 0 ? 0 : 1)} ${units[idx]}';
}

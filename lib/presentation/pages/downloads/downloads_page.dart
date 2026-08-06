import 'dart:async';
import 'dart:io';

import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_action_button.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_snackbar.dart';
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
      header: AppBreakpoints.usesDesktopToolbar(context)
          ? null
          : const _DownloadsHeader(),
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
                final pendingJobs = state.jobs.values.toList();
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppBreakpoints.usesDesktopToolbar(context)
                        ? 24
                        : AppPageLayout.compactTopInset,
                    horizontalPadding,
                    AppPageLayout.contentBottomInset,
                  ),
                  children: [
                    _DownloadStorageGroup(
                      rows: rows,
                      pendingJobs: pendingJobs,
                      state: state,
                    ),
                    const SizedBox(height: 24),
                    if (pendingJobs.isNotEmpty)
                      _DownloadSection(
                        label: '进行中',
                        child: _DownloadSectionBody(
                          children: [
                            for (final job in pendingJobs) _JobRow(job: job),
                          ],
                        ),
                      ),
                    if (pendingJobs.isNotEmpty && rows.isNotEmpty)
                      const _DownloadSectionSpacer(),
                    if (rows.isNotEmpty)
                      _DownloadSection(
                        label: '已下载',
                        child: AppBreakpoints.isCompact(context)
                            ? _DownloadSectionBody(
                                children: [
                                  for (final row in rows)
                                    _DownloadRow(
                                      record: row,
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
                                onDelete: (row) async {
                                  await context.read<DownloadsCubit>().remove(
                                    row.trackId,
                                  );
                                  _reload();
                                },
                              ),
                      ),
                    if (rows.isEmpty && pendingJobs.isEmpty)
                      const _DownloadsEmptyState(),
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

class _DownloadsHeader extends StatelessWidget {
  const _DownloadsHeader();

  @override
  Widget build(BuildContext context) {
    return const AppPageHeader(title: '下载管理');
  }
}

class _DownloadsSectionTitle extends StatelessWidget {
  const _DownloadsSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppSectionTitleRow(
      title: label,
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      titleStyle: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _DownloadStorageGroup extends StatelessWidget {
  const _DownloadStorageGroup({
    required this.rows,
    required this.pendingJobs,
    required this.state,
  });

  final List<Download> rows;
  final List<DownloadJob> pendingJobs;
  final DownloadsState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallbackBytes = rows.fold<int>(0, (sum, row) => sum + row.fileSize);
    final totalBytes = state.cachedBytes > 0
        ? state.cachedBytes
        : fallbackBytes;

    return _DownloadInfoGroup(
      title: '存储',
      children: [
        _DownloadInfoRow(
          title: '下载音质',
          description: '离线请求使用当前服务可用音质。',
          value: '自动',
        ),
        _DownloadInfoDivider(colorScheme: colorScheme),
        _DownloadInfoRow(
          title: '本地存储',
          description: _storageDescription(rows.length, pendingJobs.length),
          value: _formatBytes(totalBytes),
        ),
        _DownloadInfoDivider(colorScheme: colorScheme),
        _DownloadDirectoryRow(state: state),
      ],
    );
  }
}

class _DownloadInfoGroup extends StatelessWidget {
  const _DownloadInfoGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = AppBreakpoints.isCompact(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        compact ? AppRadiusTokens.mobileLg + 2 : AppRadiusTokens.desktopLg + 4,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: compact ? 0.96 : 0.72),
          borderRadius: BorderRadius.circular(
            compact
                ? AppRadiusTokens.mobileLg + 2
                : AppRadiusTokens.desktopLg + 4,
          ),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: compact ? 0.70 : 0.56,
            ),
            width: compact ? 0.75 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 13 : 16, 20, 8),
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: compact ? 0 : 0.32,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DownloadInfoRow extends StatelessWidget {
  const _DownloadInfoRow({
    required this.title,
    required this.description,
    required this.value,
  });

  final String title;
  final String description;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = AppBreakpoints.isCompact(context);

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
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: compact ? 15 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
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
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
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

class _DownloadInfoDivider extends StatelessWidget {
  const _DownloadInfoDivider({required this.colorScheme});

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
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: '取消下载',
        onPressed: () => context.read<DownloadsCubit>().cancel(job.track.id),
      ),
      progress: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: job.progress,
          minHeight: 4,
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.64,
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
  const _DownloadRow({required this.record, required this.onDelete});

  final Download record;
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
  const _DownloadTable({required this.rows, required this.onDelete});

  final List<Download> rows;
  final Future<void> Function(Download row) onDelete;

  @override
  Widget build(BuildContext context) {
    return _DownloadSectionDivider(
      child: Column(
        children: [
          const _DownloadTableHeader(),
          for (var i = 0; i < rows.length; i++)
            _DownloadTableRow(
              index: i,
              record: rows[i],
              onDelete: () => onDelete(rows[i]),
            ),
        ],
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
          const SizedBox(width: 34),
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
    required this.index,
    required this.record,
    required this.onDelete,
  });

  final int index;
  final Download record;
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
      child: AnimatedContainer(
        duration: AppMotion.micro,
        curve: AppMotion.standard,
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
              SizedBox(
                width: 34,
                child: Text(
                  '${widget.index + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.record.artistName ?? '未知艺术家',
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
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
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

class _DownloadSection extends StatelessWidget {
  const _DownloadSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DownloadsSectionTitle(label: label),
        child,
      ],
    );
  }
}

class _DownloadSectionSpacer extends StatelessWidget {
  const _DownloadSectionSpacer();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 24);
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

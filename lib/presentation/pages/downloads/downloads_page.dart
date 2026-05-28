import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_modal.dart';
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
      header: const _DownloadsHeader(),
      body: BlocListener<DownloadsCubit, DownloadsState>(
        listenWhen: (prev, curr) =>
            prev.completedTrackIds.length != curr.completedTrackIds.length,
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
                if (rows.isEmpty && pendingJobs.isEmpty) {
                  return const AppBodyStateView.message(
                    message: '还没有下载内容',
                    description: '在歌曲操作中选择下载后，离线曲目会显示在这里。',
                    icon: Icons.download_for_offline_outlined,
                  );
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppPageLayout.compactTopInset,
                    horizontalPadding,
                    AppPageLayout.contentBottomInset,
                  ),
                  children: [
                    if (pendingJobs.isNotEmpty)
                      _DownloadSection(
                        label: '进行中',
                        children: [
                          for (final job in pendingJobs) _JobRow(job: job),
                        ],
                      ),
                    if (pendingJobs.isNotEmpty && rows.isNotEmpty)
                      const _DownloadSectionSpacer(),
                    if (rows.isNotEmpty)
                      _DownloadSection(
                        label: '已下载',
                        children: [
                          for (final row in rows)
                            _DownloadRow(
                              record: row,
                              onDelete: () async {
                                await context.read<DownloadsCubit>().remove(
                                  row.trackId,
                                );
                                _reload();
                              },
                            ),
                        ],
                      ),
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
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: '删除下载',
      message: '将删除《${widget.record.title}》的本地离线文件，不会影响媒体库中的原始歌曲。',
      confirmLabel: '删除',
      icon: Icons.delete_outline_rounded,
      tone: AppModalTone.danger,
    );
    if (!confirmed || !context.mounted) return;
    await widget.onDelete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除下载：${widget.record.title}')));
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
  const _DownloadSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DownloadsSectionTitle(label: label),
        _DownloadSectionBody(children: children),
      ],
    );
  }
}

class _DownloadSectionSpacer extends StatelessWidget {
  const _DownloadSectionSpacer();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 24);
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

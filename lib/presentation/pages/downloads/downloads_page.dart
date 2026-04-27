import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('下载管理')),
      body: BlocListener<DownloadsCubit, DownloadsState>(
        listenWhen: (prev, curr) =>
            prev.completedTrackIds.length != curr.completedTrackIds.length,
        listener: (context, state) => _reload(),
        child: FutureBuilder<List<Download>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('加载失败：${snapshot.error}'),
                ),
              );
            }
            final rows = snapshot.data ?? const <Download>[];
            return BlocBuilder<DownloadsCubit, DownloadsState>(
              builder: (context, state) {
                final pendingJobs = state.jobs.values.toList();
                if (rows.isEmpty && pendingJobs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('还没有下载内容。'),
                    ),
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
                    if (pendingJobs.isNotEmpty) ...[
                      const _SectionLabel('进行中'),
                      for (final job in pendingJobs) _JobRow(job: job),
                      const SizedBox(height: 24),
                    ],
                    if (rows.isNotEmpty) ...[
                      const _SectionLabel('已下载'),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});
  final DownloadJob job;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CachedArtwork(
                imageUrl: job.track.artworkUrl,
                size: 48,
                borderRadius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Phase 4: Download progress bar with glow effect
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          if (job.progress != null && job.progress! > 0)
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                        ],
                      ),
                      child: LinearProgressIndicator(
                        value: job.progress,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(job),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: '取消下载',
                onPressed: () =>
                    context.read<DownloadsCubit>().cancel(job.track.id),
              ),
            ],
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

// Phase 4: Delete button hover → error color
class _DownloadRow extends StatefulWidget {
  const _DownloadRow({required this.record, required this.onDelete});

  final Download record;
  final VoidCallback onDelete;

  @override
  State<_DownloadRow> createState() => _DownloadRowState();
}

class _DownloadRowState extends State<_DownloadRow> {
  bool _deleteHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CachedArtwork(
                imageUrl: widget.record.artworkUrl ?? '',
                size: 48,
                borderRadius: 14,
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        widget.record.artistName,
                        if ((widget.record.container ?? '').isNotEmpty)
                          widget.record.container!.toUpperCase(),
                        _formatBytes(widget.record.fileSize),
                      ].whereType<String>().join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => _deleteHovered = true),
                onExit: (_) => setState(() => _deleteHovered = false),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      key: ValueKey(_deleteHovered),
                      color: _deleteHovered
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  tooltip: '删除下载',
                  onPressed: widget.onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';

class LyricTimelineEntry {
  const LyricTimelineEntry({
    required this.sourceIndex,
    required this.start,
    required this.end,
    required this.text,
    this.sourceOffset = Duration.zero,
  });

  final int sourceIndex;
  final Duration start;
  final Duration end;
  final String text;
  final Duration sourceOffset;

  Duration get seekStart => start;

  bool contains(Duration position) {
    return position >= start && position < end;
  }

  LyricLine toLyricLine() =>
      LyricLine(start: start, text: text, sourceOffset: sourceOffset);
}

class LyricTimeline {
  const LyricTimeline._(this.entries, this.sourceOffset, this.lines);

  static const empty = LyricTimeline._([], Duration.zero, []);

  final List<LyricTimelineEntry> entries;
  final Duration sourceOffset;
  final List<LyricLine> lines;

  bool get isEmpty => entries.isEmpty;

  bool get isNotEmpty => entries.isNotEmpty;

  int get length => entries.length;

  LyricTimelineEntry operator [](int index) => entries[index];

  List<LyricLine> toLyricLines() => lines;

  factory LyricTimeline.fromLines(
    List<LyricLine> lines, {
    Duration? duration,
    Duration fallbackLineDuration = const Duration(seconds: 4),
  }) {
    if (lines.isEmpty) return empty;

    final normalized = <_NormalizedLyricLine>[];
    for (var i = 0; i < lines.length; i++) {
      final text = lines[i].text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) continue;
      final start = lines[i].start.isNegative ? Duration.zero : lines[i].start;
      normalized.add(
        _NormalizedLyricLine(
          index: i,
          start: start,
          text: text,
          sourceOffset: lines[i].sourceOffset,
        ),
      );
    }
    if (normalized.isEmpty) return empty;

    normalized.sort((a, b) {
      final timeOrder = a.start.compareTo(b.start);
      if (timeOrder != 0) return timeOrder;
      return a.index.compareTo(b.index);
    });

    final coalesced = <_NormalizedLyricLine>[];
    for (final line in normalized) {
      if (coalesced.isNotEmpty && coalesced.last.start == line.start) {
        final previous = coalesced.removeLast();
        coalesced.add(
          _NormalizedLyricLine(
            index: previous.index,
            start: previous.start,
            text: '${previous.text}\n${line.text}',
            sourceOffset: previous.sourceOffset,
          ),
        );
      } else {
        coalesced.add(line);
      }
    }

    final entries = <LyricTimelineEntry>[];
    for (var i = 0; i < coalesced.length; i++) {
      final current = coalesced[i];
      final nextStart = i + 1 < coalesced.length
          ? coalesced[i + 1].start
          : null;
      var end =
          nextStart ??
          _lastLineEnd(current.start, duration, fallbackLineDuration);
      if (end <= current.start) {
        end = current.start + fallbackLineDuration;
      }
      entries.add(
        LyricTimelineEntry(
          sourceIndex: current.index,
          start: current.start,
          end: end,
          text: current.text,
          sourceOffset: current.sourceOffset,
        ),
      );
    }

    return LyricTimeline._(
      List.unmodifiable(entries),
      _dominantSourceOffset(coalesced),
      List.unmodifiable(entries.map((entry) => entry.toLyricLine())),
    );
  }

  static Duration _dominantSourceOffset(List<_NormalizedLyricLine> lines) {
    final counts = <int, int>{};
    for (final line in lines) {
      final offsetMs = line.sourceOffset.inMilliseconds;
      counts[offsetMs] = (counts[offsetMs] ?? 0) + 1;
    }
    var bestOffsetMs = 0;
    var bestCount = -1;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        bestOffsetMs = entry.key;
        bestCount = entry.value;
      }
    }
    return Duration(milliseconds: bestOffsetMs);
  }

  static Duration _lastLineEnd(
    Duration start,
    Duration? duration,
    Duration fallbackLineDuration,
  ) {
    if (duration != null && duration > start) return duration;
    return start + fallbackLineDuration;
  }
}

class _NormalizedLyricLine {
  const _NormalizedLyricLine({
    required this.index,
    required this.start,
    required this.text,
    required this.sourceOffset,
  });

  final int index;
  final Duration start;
  final String text;
  final Duration sourceOffset;
}

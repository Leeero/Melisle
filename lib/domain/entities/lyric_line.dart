/// 单条同步歌词。
class LyricLine {
  const LyricLine({
    required this.start,
    required this.text,
    this.sourceOffset = Duration.zero,
  });

  /// 该行歌词开始的相对时间。
  final Duration start;

  /// 歌词文本（不含时间戳）。
  final String text;

  /// Source-declared global offset, for example LRC `[offset:+500]`.
  ///
  /// This does not mutate [start]; the sync engine applies it together with
  /// the user offset in one place.
  final Duration sourceOffset;

  @override
  String toString() =>
      'LyricLine(${start.inMilliseconds}ms, offset=${sourceOffset.inMilliseconds}ms, "$text")';
}

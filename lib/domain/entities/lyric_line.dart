/// 单条同步歌词。
class LyricLine {
  const LyricLine({
    required this.start,
    required this.text,
  });

  /// 该行歌词开始的相对时间。
  final Duration start;

  /// 歌词文本（不含时间戳）。
  final String text;

  @override
  String toString() => 'LyricLine(${start.inMilliseconds}ms, "$text")';
}

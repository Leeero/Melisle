import 'dart:async';

/// 睡眠定时器。支持两种模式：
/// - 按固定时长倒计时（`startCountdown`）
/// - 播到"本曲结束"（`startEndOfTrack`，由外部在下一次 currentIndex 变化时 `cancel`）
class SleepTimer {
  SleepTimer();

  Timer? _timer;
  DateTime? _deadline;
  bool _endOfTrack = false;
  void Function()? _onFire;

  /// 剩余时长（null 表示未启用）。
  Duration? get remaining {
    if (_deadline == null) return null;
    final left = _deadline!.difference(DateTime.now());
    if (left.isNegative) return Duration.zero;
    return left;
  }

  bool get endOfTrackMode => _endOfTrack;

  bool get isActive => _timer != null || _endOfTrack;

  void startCountdown(Duration duration, void Function() onFire) {
    cancel();
    _endOfTrack = false;
    _deadline = DateTime.now().add(duration);
    _onFire = onFire;
    _timer = Timer(duration, () {
      _timer = null;
      _deadline = null;
      onFire();
    });
  }

  /// 标记"本曲结束"模式。由 PlayerCubit 在 currentIndex 变化或播放结束时手动触发 [fireNow]。
  void startEndOfTrack(void Function() onFire) {
    cancel();
    _endOfTrack = true;
    _deadline = null;
    _onFire = onFire;
  }

  /// 由外部主动触发（"本曲结束"模式使用）。
  void fireNow() {
    final handler = _onFire;
    cancel();
    handler?.call();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
    _endOfTrack = false;
    _onFire = null;
  }
}

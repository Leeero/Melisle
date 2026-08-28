/// A monotonic media clock used to bridge sparse or stale native positions.
///
/// Native positions remain authoritative while the player is ready. Callers
/// pause this clock whenever the native player is buffering so the UI never
/// reports media progress while no audio frames are being produced.
final class PlaybackClock {
  PlaybackClock({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _anchorTime = (now ?? DateTime.now)();

  final DateTime Function() _now;

  Duration _anchorPosition = Duration.zero;
  late DateTime _anchorTime;
  Duration? _duration;
  double _speed = 1;
  bool _running = false;

  Duration get position => _positionAt(_now());

  bool get isRunning => _running;

  void reset({Duration position = Duration.zero, Duration? duration}) {
    _duration = _validDuration(duration);
    _anchorPosition = _clamp(position);
    _anchorTime = _now();
    _running = false;
    _speed = 1;
  }

  void start({double speed = 1}) {
    final now = _now();
    _anchorPosition = _positionAt(now);
    _anchorTime = now;
    _speed = speed > 0 ? speed : 1;
    _running = true;
  }

  void pause() {
    final now = _now();
    _anchorPosition = _positionAt(now);
    _anchorTime = now;
    _running = false;
  }

  void seek(Duration position) {
    _anchorPosition = _clamp(position);
    _anchorTime = _now();
  }

  void setDuration(Duration? duration) {
    _duration = _validDuration(duration);
    seek(position);
  }

  /// Re-anchors the clock to a native media position.
  ///
  /// When [allowBackward] is false, stale native samples cannot erase elapsed
  /// media time.
  void synchronize(
    Duration nativePosition, {
    required bool allowBackward,
    Duration? maxBackwardCorrection,
  }) {
    final current = position;
    final target = _clamp(nativePosition);
    if (target < current) {
      if (!allowBackward) return;
      if (maxBackwardCorrection != null &&
          current - target > maxBackwardCorrection) {
        return;
      }
    }
    _anchorPosition = target;
    _anchorTime = _now();
  }

  void complete({Duration? nativePosition}) {
    final knownDuration = _duration;
    if (knownDuration != null) {
      _anchorPosition = knownDuration;
    } else if (nativePosition != null && nativePosition > position) {
      _anchorPosition = nativePosition;
    } else {
      _anchorPosition = position;
    }
    _anchorTime = _now();
    _running = false;
  }

  Duration _positionAt(DateTime now) {
    var result = _anchorPosition;
    if (_running) {
      final elapsed = now.difference(_anchorTime);
      if (!elapsed.isNegative) {
        result += elapsed * _speed;
      }
    }
    return _clamp(result);
  }

  Duration _clamp(Duration value) {
    if (value.isNegative) return Duration.zero;
    final duration = _duration;
    if (duration != null && value > duration) return duration;
    return value;
  }

  Duration? _validDuration(Duration? duration) {
    return duration != null && duration > Duration.zero ? duration : null;
  }
}

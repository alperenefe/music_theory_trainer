import 'dart:math' as math;

final class PitchReadingSmoother {
  PitchReadingSmoother({
    this.alpha = 0.085,
    this.maxJumpCents = 280,
    this.invalidStreakToReset = 12,
    this.minHz = 70,
    this.maxHz = 520,
  });

  final double alpha;
  final double maxJumpCents;
  final int invalidStreakToReset;
  final double minHz;
  final double maxHz;

  double? _log2Hz;
  var _invalidStreak = 0;

  void reset() {
    _log2Hz = null;
    _invalidStreak = 0;
  }

  double? push(double hz) {
    if (!hz.isFinite || hz < minHz || hz > maxHz) {
      _invalidStreak++;
      if (_invalidStreak >= invalidStreakToReset) {
        reset();
      }
      return null;
    }
    _invalidStreak = 0;
    final log = math.log(hz) / math.ln2;
    if (_log2Hz == null) {
      _log2Hz = log;
      return hz;
    }
    final jumpCents = 1200.0 * (log - _log2Hz!);
    if (jumpCents.abs() > maxJumpCents) {
      return math.pow(2.0, _log2Hz!).toDouble();
    }
    _log2Hz = _log2Hz! * (1 - alpha) + log * alpha;
    return math.pow(2.0, _log2Hz!).toDouble();
  }
}

final class PitchStringLock {
  PitchStringLock({this.framesToSwitch = 18});

  final int framesToSwitch;

  int? _locked;
  int? _pending;
  var _pendingCount = 0;

  void reset() {
    _locked = null;
    _pending = null;
    _pendingCount = 0;
  }

  int push(int candidate) {
    if (_locked == null) {
      _locked = candidate;
      _pending = null;
      _pendingCount = 0;
      return _locked!;
    }
    if (candidate == _locked) {
      _pending = null;
      _pendingCount = 0;
      return _locked!;
    }
    if (_pending == candidate) {
      _pendingCount++;
    } else {
      _pending = candidate;
      _pendingCount = 1;
    }
    if (_pendingCount >= framesToSwitch) {
      _locked = candidate;
      _pending = null;
      _pendingCount = 0;
    }
    return _locked!;
  }
}

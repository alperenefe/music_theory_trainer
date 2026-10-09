import 'dart:math' as math;
import 'dart:typed_data';

import '../dsp/yin_pitch.dart';
import '../models/chord_shape.dart';

/// Bir açık telin duyulması: hangi tel ve akort sapması (sent).
final class StringHeard {
  const StringHeard({required this.string, required this.cents});

  /// 0 = 6. tel (en kalın) … 5 = 1. tel.
  final int string;
  final double cents;
}

/// Mikrofon parçalarından açık tel perdesini (YIN) bulur.
///
/// Aynı tel art arda [needStable] pencerede, birbirine yakın perdeyle duyulursa
/// "çalındı" sayılır. Aynı tel tekrar bildirilmez; sessizlik ya da başka bir
/// tel gelince yeniden bildirilebilir.
final class OpenStringListener {
  OpenStringListener({
    required this.sampleRate,
    this.needStable = 2,
    this.maxCents = 50,
    this.minRms = 0.006,
  }) : _yin = YinPitchDetector(sampleRate: sampleRate, minHz: 70, maxHz: 400, minClarity: 0.75);

  final int sampleRate;
  final int needStable;
  final double maxCents;
  final double minRms;
  final YinPitchDetector _yin;

  static const _win = 4096;
  static const _hop = 2048;
  final _buf = Float64List(_win);
  var _filled = 0;
  var _since = 0;

  int? _candidate;
  var _count = 0;
  int? _reported;

  double level = 0;

  void reset() {
    _filled = 0;
    _since = 0;
    _candidate = null;
    _count = 0;
    _reported = null;
    _buf.fillRange(0, _win, 0);
  }

  StringHeard? feed(Float64List chunk) {
    var e = 0.0;
    for (final v in chunk) {
      e += v * v;
    }
    final rms = chunk.isEmpty ? 0.0 : math.sqrt(e / chunk.length);
    level = (rms * 8).clamp(0.0, 1.0);

    final n = chunk.length;
    if (n >= _win) {
      _buf.setRange(0, _win, chunk, n - _win);
    } else {
      _buf.setRange(0, _win - n, _buf, n);
      _buf.setRange(_win - n, _win, chunk);
    }
    _filled = math.min(_win, _filled + n);
    _since += n;
    if (_filled < _win || _since < _hop) return null;
    _since = 0;

    if (_windowRms() < minRms) {
      _candidate = null;
      _count = 0;
      _reported = null; // sessizlikten sonra aynı tel yeniden sayılabilir
      return null;
    }
    final est = _yin.detect(_buf);
    if (est == null) {
      _count = 0;
      return null;
    }
    final midi = 69 + 12 * math.log(est.hz / 440) / math.ln2;
    int? best;
    var bestCents = 1e9;
    for (var s = 0; s < 6; s++) {
      final c = (midi - ChordShape.openStringMidi[s]) * 100;
      if (c.abs() < bestCents.abs()) {
        bestCents = c;
        best = s;
      }
    }
    if (best == null || bestCents.abs() > maxCents) {
      _count = 0;
      return null;
    }
    if (_candidate == best) {
      _count++;
    } else {
      _candidate = best;
      _count = 1;
    }
    if (_count >= needStable && _reported != best) {
      _reported = best;
      return StringHeard(string: best, cents: bestCents);
    }
    return null;
  }

  double _windowRms() {
    var e = 0.0;
    for (final v in _buf) {
      e += v * v;
    }
    return math.sqrt(e / _win);
  }
}

import 'dart:math' as math;
import 'dart:typed_data';

import '../dsp/chord_detector.dart';
import '../models/chord_shape.dart';

/// Canlı akor dinleyici: mikrofon parçalarını biriktirir, belirli aralıkla son
/// [fftSize] örneği [target] akoruna karşı analiz eder.
///
/// Bir akorun "çalındı" sayılması için art arda [needStreak] analizin eşleşmesi
/// gerekir (tek seferlik tesadüfü eler).
final class ChordListener {
  ChordListener({
    required this.sampleRate,
    required this.target,
    this.candidates = ChordLibrary.all,
    this.hopMs = 180,
    this.needStreak = 2,
    this.fftSize = 16384,
    this.minRms = 0.004,
  }) : _detector = ChordDetector(sampleRate: sampleRate, fftSize: fftSize);

  final int sampleRate;
  ChordShape target;
  final Iterable<ChordShape> candidates;
  final int hopMs;
  final int needStreak;
  final int fftSize;
  final double minRms;
  final ChordDetector _detector;

  /// Aynı tampon üzerinde başka akorları da sınamak için (döngü kulak egzersizi).
  ChordDetector get detector => _detector;

  /// Son analizin spektrumu (`null` = henüz analiz yok / çok sessiz).
  Spectrum? lastSpectrum;

  late final Float64List _buf = Float64List(fftSize);
  var _filled = 0;
  var _sinceAnalysis = 0;

  var _streak = 0;
  ChordAnalysis? last;

  /// Son analiz penceresinin RMS'i (sessiz de olsa).
  double lastRms = 0;

  /// Son parçanın seviyesi (0–1, görsel ölçer için).
  double level = 0;

  int get streak => _streak;
  bool get confirmed => _streak >= needStreak;

  void reset() {
    _filled = 0;
    _sinceAnalysis = 0;
    _streak = 0;
    last = null;
    lastSpectrum = null;
    level = 0;
    _buf.fillRange(0, _buf.length, 0);
  }

  /// Yeni bir analiz yapıldıysa sonucunu döner.
  ChordAnalysis? feed(Float64List chunk) {
    var e = 0.0;
    for (final v in chunk) {
      e += v * v;
    }
    final chunkRms = chunk.isEmpty ? 0.0 : math.sqrt(e / chunk.length);
    level = (chunkRms * 8).clamp(0.0, 1.0);

    final n = chunk.length;
    if (n >= fftSize) {
      _buf.setRange(0, fftSize, chunk, n - fftSize);
    } else {
      _buf.setRange(0, fftSize - n, _buf, n);
      _buf.setRange(fftSize - n, fftSize, chunk);
    }
    _filled = math.min(fftSize, _filled + n);
    _sinceAnalysis += n;
    if (_filled < fftSize || _sinceAnalysis < sampleRate * hopMs / 1000) return null;
    _sinceAnalysis = 0;

    final spec = _detector.analyze(_buf);
    lastRms = spec.rms;
    if (spec.rms < minRms) {
      _streak = 0;
      last = null;
      lastSpectrum = null;
      return null;
    }
    lastSpectrum = spec;
    final res = _detector.check(target, spec, candidates: candidates);
    _streak = res.isMatch ? _streak + 1 : 0;
    last = res;
    return res;
  }
}

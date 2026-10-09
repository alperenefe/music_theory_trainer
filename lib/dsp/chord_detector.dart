import 'dart:math' as math;
import 'dart:typed_data';

import '../models/chord_shape.dart';
import 'fft.dart';

/// Spektrumdaki bir tepe: [hz] kesirli bin interpolasyonuyla, [amp] pencere
/// içindeki en güçlü tepeye oranla (0–1).
final class SpectralPeak {
  const SpectralPeak(this.hz, this.amp);
  final double hz;
  final double amp;
}

/// Bir ses penceresinin çıkarılmış tepeleri + ses seviyesi.
final class Spectrum {
  const Spectrum(this.peaks, this.rms);

  final List<SpectralPeak> peaks;
  final double rms;

  bool get isEmpty => peaks.isEmpty;
}

final class ChordAnalysis {
  const ChordAnalysis({
    required this.target,
    required this.score,
    required this.best,
    required this.bestScore,
    required this.isMatch,
    required this.missingStrings,
    required this.extraStrings,
  });

  final ChordShape target;

  /// Hedef akor şablonuyla benzerlik (0–1, kosinüs).
  final double score;

  /// Aday akorlar arasında en benzeyen (hedef dahil).
  final ChordShape? best;
  final double bestScore;

  /// Hedef akor çalındı mı?
  final bool isMatch;

  /// Çalınması gerektiği hâlde duyulmayan teller (0 = 6. tel).
  final List<int> missingStrings;

  /// Susturulması gerektiği hâlde çınlayan teller.
  final List<int> extraStrings;

  static const empty = ChordAnalysis(
    target: ChordLibrary.em,
    score: 0,
    best: null,
    bestScore: 0,
    isMatch: false,
    missingStrings: [],
    extraStrings: [],
  );
}

/// Bilinen bir akor şeklinin (hangi teller, hangi perdeler) ses spektrumunu
/// önceden hesaplayıp, mikrofondan gelen sesin spektrumuyla karşılaştırır.
///
/// Neden "akor tanıma" yerine "bu akor mu?" sorusu: serbest akor tanıma
/// (kroma + şablon) gitarda majör/minör'ü sık karıştırır, çünkü kökün 5.
/// harmoniği büyük 3'lüyü verir. Hangi tellerin çalınması gerektiğini
/// bildiğimizde ise beklenen kısmi sesleri (harmonikleri) birebir hesaplayıp
/// ölçümle karşılaştırabiliriz; ayrıca hangi telin eksik/fazla olduğunu da
/// söyleyebiliriz.
final class ChordDetector {
  ChordDetector({
    required this.sampleRate,
    this.fftSize = 16384,
    this.a4 = 440,
    this.minHz = 70,
    this.maxHz = 1500,
    this.matchScore = 0.62,
    this.matchMargin = 0.04,
    this.minCoverage = 0.6,
    this.minStringCoverage = 0.5,
  }) : _fft = Fft(fftSize);

  final int sampleRate;
  final int fftSize;
  final double a4;
  final double minHz;
  final double maxHz;

  /// Hedef şablonla en az bu benzerlik gerekir.
  final double matchScore;

  /// Hedef, en iyi rakipten en fazla bu kadar geride olabilir.
  final double matchMargin;

  /// Beklenen kısmi seslerin en az bu kadarı ölçümde bulunmalı.
  final double minCoverage;

  /// Ayırt edilebilen tellerin en az bu oranı çınlamalı.
  final double minStringCoverage;

  /// Bir kısmi sesin "var" sayılması için en güçlü tepeye oranla alt genlik.
  /// Çok düşük tutulursa yüksek harmonikler (7., 9. …) başka tellerin kısmi
  /// seslerine tesadüfen denk gelip yanlış kanıt üretir.
  static const double presentAmp = 0.08;

  final Fft _fft;

  // Bir telin harmonik ağırlıkları (1., 2., … 6.); gitar teli için tipik.
  static const _harmonicWeights = [1.0, 0.85, 0.65, 0.45, 0.3, 0.2];

  // Cent ızgarası: [minMidi, maxMidi] arası 4 bölme (25 cent).
  static const _gridPerSemitone = 4;
  static const _sigmaCents = 28.0;

  late final double _minMidi = _midiOfHz(minHz);
  late final double _maxMidi = _midiOfHz(maxHz);
  late final int _gridSize = ((_maxMidi - _minMidi) * _gridPerSemitone).ceil() + 1;

  double _midiOfHz(double hz) => 69 + 12 * math.log(hz / a4) / math.ln2;
  double _hzOfMidi(double midi) => a4 * math.pow(2.0, (midi - 69) / 12.0);

  /// Pencereden tepe noktalarını çıkarır. [samples] ham, -1..1 aralığında.
  Spectrum analyze(Float64List samples) {
    var e = 0.0;
    for (final v in samples) {
      e += v * v;
    }
    final rms = math.sqrt(e / math.max(1, samples.length));
    final mag = _fft.magnitudeSpectrum(samples);
    final binHz = sampleRate / fftSize;
    final lo = math.max(2, (minHz / binHz).floor());
    final hi = math.min(mag.length - 2, (maxHz / binHz).ceil());
    if (hi <= lo + 2) return Spectrum(const [], rms);

    var maxMag = 0.0;
    final sorted = <double>[];
    for (var i = lo; i <= hi; i++) {
      if (mag[i] > maxMag) maxMag = mag[i];
      sorted.add(mag[i]);
    }
    if (maxMag <= 0) return Spectrum(const [], rms);
    sorted.sort();
    final median = sorted[sorted.length ~/ 2];
    // Mutlak (en güçlü tepeye göre) ve göreli (gürültü tabanına göre) eşik.
    final threshold = math.max(maxMag * 0.03, median * 8);

    final peaks = <SpectralPeak>[];
    for (var i = lo; i <= hi; i++) {
      final m = mag[i];
      if (m < threshold) continue;
      if (m <= mag[i - 1] || m < mag[i + 1]) continue;
      // Logaritmik parabolik interpolasyon.
      final a = math.log(mag[i - 1] + 1e-12);
      final b = math.log(m + 1e-12);
      final c = math.log(mag[i + 1] + 1e-12);
      final denom = a - 2 * b + c;
      final p = denom.abs() < 1e-12 ? 0.0 : 0.5 * (a - c) / denom;
      final amp = math.exp(b - 0.25 * (a - c) * p) / maxMag;
      peaks.add(SpectralPeak((i + p) * binHz, amp.clamp(0.0, 1.0)));
    }
    return Spectrum(peaks, rms);
  }

  // ---- Izgara temsili -----------------------------------------------------

  Float64List _gridOfPeaks(List<SpectralPeak> peaks) {
    final g = Float64List(_gridSize);
    for (final p in peaks) {
      _addGaussian(g, _midiOfHz(p.hz), math.sqrt(p.amp));
    }
    return g;
  }

  Float64List _templateOf(List<int> midis) {
    final g = Float64List(_gridSize);
    for (final m in midis) {
      final f0 = _hzOfMidi(m.toDouble());
      for (var h = 1; h <= _harmonicWeights.length; h++) {
        final f = f0 * h * math.sqrt(1 + 0.00015 * h * h);
        if (f < minHz || f > maxHz) continue;
        _addGaussian(g, _midiOfHz(f), _harmonicWeights[h - 1]);
      }
    }
    return g;
  }

  void _addGaussian(Float64List g, double midi, double weight) {
    final center = (midi - _minMidi) * _gridPerSemitone;
    final sigmaBins = _sigmaCents / 100 * _gridPerSemitone;
    final from = (center - 3 * sigmaBins).floor();
    final to = (center + 3 * sigmaBins).ceil();
    for (var i = from; i <= to; i++) {
      if (i < 0 || i >= _gridSize) continue;
      final d = (i - center) / sigmaBins;
      g[i] += weight * math.exp(-0.5 * d * d);
    }
  }

  static double _cosine(Float64List a, Float64List b) {
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na <= 0 || nb <= 0) return 0;
    return dot / math.sqrt(na * nb);
  }

  /// Hedef akor şablonuyla benzerlik (0–1).
  double similarity(ChordShape shape, Spectrum spec) {
    if (spec.isEmpty) return 0;
    return _cosine(_gridOfPeaks(spec.peaks), _templateOf(shape.midis));
  }

  /// Beklenen kısmi seslerin (ağırlıklı) ne kadarı ölçümde gerçekten var?
  ///
  /// Kosinüs benzerliği tek başına yetmez: tek bir La teli çalınınca ölçüm,
  /// Am şablonunun bir ALT KÜMESİ olduğu için benzerlik yüksek kalır. Kapsama
  /// "akorun yeterince teli çınlıyor mu?" sorusunu cevaplar.
  double coverage(ChordShape shape, Spectrum spec) {
    if (spec.isEmpty) return 0;
    var total = 0.0;
    var found = 0.0;
    for (final m in shape.midis) {
      final f0 = _hzOfMidi(m.toDouble());
      for (var h = 1; h <= 4; h++) {
        final f = f0 * h;
        if (f < minHz || f > maxHz) continue;
        final w = _harmonicWeights[h - 1];
        total += w;
        if (_ampNear(spec, f, cents: 40) >= presentAmp) found += w;
      }
    }
    return total <= 0 ? 0 : found / total;
  }

  /// [target]'ın çalınıp çalınmadığını, [candidates] arasındaki rakiplerle
  /// karşılaştırarak söyler. [candidates] hedefi içermese de olur.
  ChordAnalysis check(
    ChordShape target,
    Spectrum spec, {
    Iterable<ChordShape> candidates = ChordLibrary.all,
  }) {
    if (spec.isEmpty) {
      return ChordAnalysis(
        target: target,
        score: 0,
        best: null,
        bestScore: 0,
        isMatch: false,
        missingStrings: const [],
        extraStrings: const [],
      );
    }
    final measured = _gridOfPeaks(spec.peaks);
    final score = _cosine(measured, _templateOf(target.midis));

    ChordShape? best = target;
    var bestScore = score;
    for (final c in candidates) {
      if (c.id == target.id) continue;
      final s = _cosine(measured, _templateOf(c.midis));
      if (s > bestScore) {
        bestScore = s;
        best = c;
      }
    }

    final cov = coverage(target, spec);
    final evidence = _stringEvidence(target, spec);
    // Ayırt edilebilir tellerin en az yarısı çınlamalı: tek tel çalmak akor
    // sayılmaz, bir tel eksik kalması ise geri bildirimle bildirilir.
    final enoughStrings = evidence.testable == 0 ||
        evidence.missing.length <= evidence.testable * (1 - minStringCoverage);
    final isMatch = score >= matchScore &&
        score >= bestScore - matchMargin &&
        cov >= minCoverage &&
        enoughStrings;
    final missing = <int>[];
    final extra = <int>[];
    if (score >= 0.45) {
      missing.addAll(evidence.missing);
      extra.addAll(_extraStrings(target, spec));
    }
    return ChordAnalysis(
      target: target,
      score: score,
      best: best,
      bestScore: bestScore,
      isMatch: isMatch,
      missingStrings: missing,
      extraStrings: extra,
    );
  }

  /// Birden çok aday arasından en çok benzeyeni döner (null = hiçbiri yeterli değil).
  ChordShape? identify(Spectrum spec, Iterable<ChordShape> candidates) {
    if (spec.isEmpty) return null;
    final measured = _gridOfPeaks(spec.peaks);
    ChordShape? best;
    var bestScore = 0.0;
    var second = 0.0;
    for (final c in candidates) {
      final s = _cosine(measured, _templateOf(c.midis));
      if (s > bestScore) {
        second = bestScore;
        bestScore = s;
        best = c;
      } else if (s > second) {
        second = s;
      }
    }
    if (best == null || bestScore < matchScore) return null;
    if (bestScore - second < matchMargin * 0.5) return null;
    return best;
  }

  // ---- Tel bazlı geri bildirim ----------------------------------------------

  /// [hz] civarında (±[cents]) ölçülmüş en güçlü tepenin göreli genliği.
  double _ampNear(Spectrum spec, double hz, {double cents = 35}) {
    var best = 0.0;
    for (final p in spec.peaks) {
      final d = 1200 * (math.log(p.hz / hz) / math.ln2).abs();
      if (d <= cents && p.amp > best) best = p.amp;
    }
    return best;
  }

  /// Tel [s]'nin [h]. harmoniği, başka bir BEKLENEN telin ilk 6 harmoniğiyle
  /// çakışıyor mu? Çakışıyorsa bu tel için kanıt ayırt edici değildir.
  bool _overlapsOthers(ChordShape shape, int stringIndex, double hz) {
    for (final s in shape.playedStrings) {
      if (s == stringIndex) continue;
      final f0 = _hzOfMidi((ChordShape.openStringMidi[s] + shape.frets[s]).toDouble());
      for (var h = 1; h <= 6; h++) {
        final d = 1200 * (math.log(f0 * h / hz) / math.ln2).abs();
        if (d < 45) return true;
      }
    }
    return false;
  }

  /// Her çalınan tel için, SADECE o tele ait (başka tellerle çakışmayan)
  /// kısmi seslere bakar. Hiç ayırt edici kısmi yoksa tel "test edilemez"
  /// sayılır (ör. Em'de 3. mi teli, 1. ve 6. mi tellerinin harmonikleriyle
  /// aynıdır; ayrı duyulması mümkün değildir).
  ({List<int> missing, int testable}) _stringEvidence(ChordShape shape, Spectrum spec) {
    final out = <int>[];
    var testable = 0;
    for (final s in shape.playedStrings) {
      final f0 = _hzOfMidi((ChordShape.openStringMidi[s] + shape.frets[s]).toDouble());
      var tested = false;
      var evidence = 0.0;
      for (var h = 1; h <= 4; h++) {
        final f = f0 * h;
        if (f < minHz || f > maxHz) continue;
        if (_overlapsOthers(shape, s, f)) continue;
        tested = true;
        evidence = math.max(evidence, _ampNear(spec, f, cents: 28));
      }
      if (!tested) continue;
      testable++;
      if (evidence < presentAmp) out.add(s);
    }
    return (missing: out, testable: testable);
  }

  List<int> _extraStrings(ChordShape shape, Spectrum spec) {
    final out = <int>[];
    for (var s = 0; s < 6; s++) {
      if (shape.frets[s] >= 0) continue;
      final f0 = _hzOfMidi(ChordShape.openStringMidi[s].toDouble());
      var evidence = 0.0;
      for (var h = 1; h <= 3; h++) {
        final f = f0 * h;
        if (f < minHz || f > maxHz) continue;
        if (_overlapsOthers(shape, -1, f)) continue;
        evidence = math.max(evidence, _ampNear(spec, f, cents: 28));
      }
      if (evidence >= 0.30) out.add(s);
    }
    return out;
  }
}

import 'dart:math' as math;
import 'dart:typed_data';

import 'fft.dart';

/// Bir vuruşun (strum / nota atağı) zamanı.
final class Onset {
  const Onset({required this.sample, required this.strength});

  /// Akış başından itibaren mutlak örnek sırası.
  final int sample;

  /// Tepe noktasındaki spektral akış (≈ vuruşun sertliği).
  final double strength;

  double timeSec(int sampleRate) => sample / sampleRate;
}

/// Spektral akış tabanlı vuruş algılayıcı (akış halinde çalışır).
///
/// 1024 örneklik pencerelerin (hop 256) log-genlik spektrumları arasındaki
/// POZİTİF farkların toplamı bir "yenilik" eğrisi verir. Çınlayan sürekli ses
/// spektrumu değiştirmediği için akış ≈ 0 kalır; yeni bir vuruş ise birçok
/// frekansta aynı anda artış yaratır. Eşik, son ~0.25 saniyenin ortancasına
/// ve sapmasına göre uyarlanır; böylece gürültülü odalarda da çalışır.
///
/// Zaman damgası, akışın İLK tepesinin pencere ortasıdır. (Vuruşun yüksek
/// frekans enerjisi ince teller girdikçe ~100 ms boyunca yükselmeyi sürdürür;
/// bu yüzden "atak zarfı" gibi geriye dönük düzeltmeler tutarsız çıkıyor, ilk
/// akış tepesi ise ardışık vuruşlarda ±5 ms tutarlı.)
final class OnsetDetector {
  OnsetDetector({
    required this.sampleRate,
    this.minRms = 0.004,
    this.refractoryMs = 110,
    this.sensitivity = 1.0,
    this.latencyBiasMs = 0,
    this.lowBandWeight = 0.0,
    this.onTrace,
  })  : _fft = Fft(_frame),
        _window = _hann();

  static const _frame = 1024;
  static const _hop = 256;
  static const _historyLen = 40;
  static const _minFluxMargin = 10.0;
  static const _histSize = 16384;

  final int sampleRate;

  /// Pencere RMS'i bunun altındaysa vuruş aranmaz.
  final double minRms;
  final int refractoryMs;

  /// 1'den büyük = daha hassas (daha düşük eşik).
  final double sensitivity;

  /// Düzeltilmiş vuruş zamanına eklenecek sabit kaydırma (ms).
  final double latencyBiasMs;

  /// Düşük bant (100–1000 Hz) akışının ağırlığı. Aşağı vuruş pes tellerden
  /// başlar; yüksek bantta ancak tiz teller girince görünür (≈50 ms geç).
  final double lowBandWeight;

  /// Hata ayıklama: her hop için (pencere sonu örnek, akış, eşik).
  final void Function(int endSample, double flux, double threshold)? onTrace;

  final Fft _fft;
  final Float64List _window;

  final _hist = Float64List(_histSize); // son örnekler (dairesel)
  var _consumed = 0; // akıştan alınan toplam örnek
  var _sinceHop = 0;
  Float64List? _prev;
  final _flux = <double>[];
  final _fluxEnd = <int>[]; // her akış değerinin pencere sonu (örnek sırası)
  var _lastOnsetSample = -1 << 30;
  var _lowCount = 0;

  static Float64List _hann() {
    final w = Float64List(_frame);
    for (var i = 0; i < _frame; i++) {
      w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (_frame - 1));
    }
    return w;
  }

  double _at(int absIndex) => _hist[absIndex % _histSize];

  void reset() {
    _hist.fillRange(0, _histSize, 0);
    _consumed = 0;
    _sinceHop = 0;
    _prev = null;
    _flux.clear();
    _fluxEnd.clear();
    _lastOnsetSample = -1 << 30;
  }

  /// Yeni bir ses parçasını işler; bu parçada kesinleşen vuruşları döner.
  List<Onset> process(Float64List chunk) {
    final out = <Onset>[];
    for (var i = 0; i < chunk.length; i++) {
      _hist[_consumed % _histSize] = chunk[i];
      _consumed++;
      _sinceHop++;
      if (_sinceHop >= _hop && _consumed >= _frame) {
        _sinceHop = 0;
        _step(out);
      }
    }
    return out;
  }

  void _step(List<Onset> out) {
    final re = Float64List(_frame);
    final im = Float64List(_frame);
    var e = 0.0;
    final start = _consumed - _frame;
    for (var i = 0; i < _frame; i++) {
      final v = _at(start + i);
      e += v * v;
      re[i] = v * _window[i];
    }
    final rms = math.sqrt(e / _frame);
    _fft.transform(re, im);

    // Yüksek frekans bandı (1.5–9 kHz): pena geçişi geniş bantlıdır ve çınlayan
    // tellerin enerjisi bu bantta çabuk söner. Aynı akor üstüne yeniden vurunca
    // düşük bantta spektrum neredeyse değişmez, bu bantta ise net bir sıçrama olur.
    final binHz = sampleRate / _frame;
    final lowLo = math.max(1, (100 / binHz).floor());
    final lowHi = (1000 / binHz).ceil();
    final lo = math.max(1, (1500 / binHz).floor());
    final hi = math.min(_frame ~/ 2 - 1, (9000 / binHz).ceil());
    // [lowLo..lowHi] düşük bant, [lo..hi] yüksek bant: tek dizide art arda.
    final lowCount = lowHi - lowLo + 1;
    final mags = Float64List(lowCount + hi - lo + 1);
    for (var k = lowLo; k <= lowHi; k++) {
      final m = math.sqrt(re[k] * re[k] + im[k] * im[k]);
      mags[k - lowLo] = math.log(1 + m * 8);
    }
    for (var k = lo; k <= hi; k++) {
      final m = math.sqrt(re[k] * re[k] + im[k] * im[k]);
      mags[lowCount + k - lo] = math.log(1 + m * 8);
    }
    _lowCount = lowCount;

    final prev = _prev;
    _prev = mags;
    if (prev == null) return;
    var flux = 0.0;
    for (var i = 0; i < mags.length; i++) {
      final d = mags[i] - prev[i];
      if (d > 0) flux += d * (i < _lowCount ? lowBandWeight : 1.0);
    }
    if (rms < minRms) flux = 0;

    _flux.add(flux);
    _fluxEnd.add(_consumed);
    if (_flux.length > _historyLen) {
      _flux.removeAt(0);
      _fluxEnd.removeAt(0);
    }
    if (_flux.length < 4) return;

    // Aday: bir önceki hop (n-1), n-2'den büyük ve n'den küçük değil.
    final n = _flux.length;
    final cand = _flux[n - 2];
    if (cand <= _flux[n - 3] || cand < _flux[n - 1]) return;

    // Uyarlanır eşik: aday HARİÇ yerel ortanca + sapma.
    final others = <double>[
      for (var i = 0; i < n; i++)
        if (i != n - 2) _flux[i],
    ]..sort();
    final median = others[others.length ~/ 2];
    var mad = 0.0;
    for (final v in others) {
      mad += (v - median).abs();
    }
    mad /= others.length;
    // Mutlak alt sınır: sürekli çınlamanın doğal dalgalanması (≈ 8–13) vuruş
    // sayılmasın; gerçek vuruşlar tipik olarak 40–70 verir.
    final margin = math.max(_minFluxMargin, 4 * mad) / sensitivity;
    final threshold = median + margin;

    onTrace?.call(_fluxEnd[n - 2], cand, threshold);
    final endSample = _fluxEnd[n - 2];
    final sinceLast = (endSample - _lastOnsetSample) * 1000 / sampleRate;
    if (cand > threshold && sinceLast >= refractoryMs) {
      // Zamanı akışın TEPESİNDEN değil YÜKSELİŞİNİN BAŞLANGICINDAN al: aşağı
      // vuruşta teller tek tek girdiği için eğri yavaş yükselir (tepe ≈ +40 ms
      // geç), yukarı vuruşta keskin sıçrar. Tepenin %30'una (tabanın üstünde)
      // ulaşılan ilk hop yükselişin başıdır.
      final level = median + 0.3 * (cand - median);
      var j = n - 2;
      while (j > 0 && _flux[j - 1] >= level && _fluxEnd[j - 1] > _lastOnsetSample) {
        j--;
      }
      // Pencere sonu değil, atağın pencereye girdiği yer ~ ortası.
      final refined = _fluxEnd[j] - _frame ~/ 2;
      final adjusted = refined + (latencyBiasMs * sampleRate / 1000).round();
      out.add(Onset(sample: math.max(0, adjusted), strength: cand));
      _lastOnsetSample = endSample;
    }
  }
}

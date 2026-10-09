import 'dart:math' as math;
import 'dart:typed_data';

import '../models/chord_shape.dart';
import 'chord_detector.dart';
import 'onset_detector.dart';

/// İki akor arasındaki değişimleri sayar (JustinGuitar'ın "bir dakikada akor
/// değişimi" egzersizi).
///
/// Akış: her vuruşta (strum) bir analiz planlanır; vuruştan ~[settleMs] sonra,
/// son [windowSamples] örnek A ve B akorlarıyla karşılaştırılır. Hangisi
/// çalındıysa o "mevcut akor" olur; mevcut akor bir öncekinden FARKLIYSA bir
/// değişim sayılır. Aynı akoru art arda çalmak, ya da hiçbirine uymayan bir
/// çalış (yanlış tutuş) sayılmaz.
final class ChordChangeCounter {
  ChordChangeCounter({
    required this.sampleRate,
    required this.a,
    required this.b,
    this.settleMs = 300,
    this.windowSamples = 8192,
    OnsetDetector? onsetDetector,
  })  : _onsets = onsetDetector ?? OnsetDetector(sampleRate: sampleRate),
        _detector = ChordDetector(
          sampleRate: sampleRate,
          fftSize: windowSamples,
          // Yalnız iki aday var: göreli karşılaştırma yeterince güçlü, mutlak
          // eşikleri biraz gevşetiyoruz (kısa pencere = daha az çözünürlük).
          matchScore: 0.55,
        );

  final int sampleRate;
  final ChordShape a;
  final ChordShape b;
  final int settleMs;
  final int windowSamples;

  final OnsetDetector _onsets;
  final ChordDetector _detector;

  // Son çalınan örneklerin dairesel tamponu.
  static const _histSize = 32768;
  final _hist = Float64List(_histSize);
  var _consumed = 0;

  // Planlanmış analizler: analiz edilecek mutlak örnek sırası.
  final _pending = <int>[];

  ChordShape? _current;
  var _changes = 0;
  var _strums = 0;
  var _unrecognized = 0;

  /// Saydığı toplam akor değişimi.
  int get changes => _changes;

  /// Algılanan toplam vuruş.
  int get strums => _strums;

  /// Hiçbir akora uymayan çalışlar (yanlış tutuş, susturulmuş teller …).
  int get unrecognized => _unrecognized;

  /// Şu an çalındığı sanılan akor.
  ChordShape? get current => _current;

  void reset() {
    _onsets.reset();
    _hist.fillRange(0, _histSize, 0);
    _consumed = 0;
    _pending.clear();
    _current = null;
    _changes = 0;
    _strums = 0;
    _unrecognized = 0;
  }

  /// Yeni ses parçasını işler. Bu parçada yeni bir akor değişimi kesinleştiyse
  /// onu dönen listede verir (`null` = bu parçada olay yok).
  List<ChangeEvent> process(Float64List chunk) {
    final events = <ChangeEvent>[];
    for (var i = 0; i < chunk.length; i++) {
      _hist[_consumed % _histSize] = chunk[i];
      _consumed++;
    }
    for (final o in _onsets.process(chunk)) {
      _strums++;
      _pending.add(o.sample + (settleMs * sampleRate / 1000).round());
    }
    while (_pending.isNotEmpty && _pending.first <= _consumed) {
      final at = _pending.removeAt(0);
      final ev = _analyze(at);
      if (ev != null) events.add(ev);
    }
    return events;
  }

  ChangeEvent? _analyze(int endSample) {
    final from = endSample - windowSamples;
    if (from < 0 || endSample > _consumed || _consumed - from > _histSize) {
      return null;
    }
    final w = Float64List(windowSamples);
    for (var i = 0; i < windowSamples; i++) {
      w[i] = _hist[(from + i) % _histSize];
    }
    final spec = _detector.analyze(w);
    ChordShape? heard;
    final ra = _detector.check(a, spec, candidates: [a, b]);
    final rb = _detector.check(b, spec, candidates: [a, b]);
    if (ra.isMatch && (!rb.isMatch || ra.score >= rb.score)) {
      heard = a;
    } else if (rb.isMatch) {
      heard = b;
    }
    if (heard == null) {
      _unrecognized++;
      return ChangeEvent(chord: null, counted: false, total: _changes);
    }
    final changed = _current != null && _current!.id != heard.id;
    _current = heard;
    if (changed) _changes++;
    return ChangeEvent(chord: heard, counted: changed, total: _changes);
  }

  /// Egzersiz süresi dolduğunda bekleyen son analizleri de değerlendirir.
  List<ChangeEvent> flush() {
    final events = <ChangeEvent>[];
    final maxEnd = _consumed;
    while (_pending.isNotEmpty) {
      final at = math.min(_pending.removeAt(0), maxEnd);
      final ev = _analyze(at);
      if (ev != null) events.add(ev);
    }
    return events;
  }
}

final class ChangeEvent {
  const ChangeEvent({required this.chord, required this.counted, required this.total});

  /// Duyulan akor (hiçbirine uymadıysa null).
  final ChordShape? chord;

  /// Bu çalış bir akor DEĞİŞİMİ olarak sayıldı mı?
  final bool counted;

  /// Şu ana kadarki toplam değişim.
  final int total;
}

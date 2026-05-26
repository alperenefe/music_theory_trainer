import 'dart:math';

import '../models/guitar_note.dart';
import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';

/// Basit hedef seçimi:
/// - Önce havuzdaki her nota en az bir kez (1 tur).
/// - Sonra **son 2** o notaya ait denemeye göre doğruluk.
/// - Yanlış varsa ağırlık 4, yalnızca yavaş doğruysa 2, iyi doğruysa 1 (zayıf/güçlü ≥ 4:1).
/// - Aynı birimdeki notalar (ör. hepsi hızlı %100) tur penceresinde eşit görünür.
/// - Ardışık aynı nota tekrar sorulmaz (başka aday varsa).
abstract final class TargetPicker {
  static const int _lastStatCount = 2;

  /// Güçlü / orta (yavaş) / zayıf (son 2'de hata) / hiç görülmedi.
  static const int _unitStrong = 1;
  static const int _unitSlow = 2;
  static const int _unitWeak = 4;
  static const int _unitUnseen = 8;

  static const int _baselineFloorMs = 350;

  static NotationPitch pick(
    Random rnd,
    List<NotationPitch> pool,
    List<PracticeAttempt> history,
  ) {
    if (pool.isEmpty) {
      throw StateError('pool');
    }
    if (pool.length == 1) {
      return pool.first;
    }
    final midi = pickMidi(rnd, pool.map((e) => e.midi), history);
    return pool.firstWhere((e) => e.midi == midi);
  }

  static GuitarNote pickGuitarNote(
    Random rnd,
    List<GuitarNote> pool,
    List<PracticeAttempt> history,
  ) {
    if (pool.isEmpty) {
      throw StateError('pool');
    }
    if (pool.length == 1) {
      return pool.first;
    }
    final midi = pickMidi(rnd, pool.map((e) => e.midi), history);
    final same = pool.where((e) => e.midi == midi).toList();
    return same[rnd.nextInt(same.length)];
  }

  static GuitarNote pickGuitarNoteByPitchClass(
    Random rnd,
    List<GuitarNote> pool,
    List<PracticeAttempt> history,
  ) {
    if (pool.isEmpty) {
      throw StateError('pool');
    }
    final classes = pool.map((e) => e.pitchClass).toSet().toList();
    final pc = pickPitchClass(rnd, classes, history);
    final same = pool.where((e) => e.pitchClass == pc).toList();
    return same[rnd.nextInt(same.length)];
  }

  static int pickMidi(
    Random rnd,
    Iterable<int> midis,
    List<PracticeAttempt> history,
  ) {
    final list = midis.toSet().toList()..sort();
    if (list.length == 1) {
      return list.first;
    }
    return _pick(
      rnd,
      list,
      history,
      matchHistory: (attempt, key) => attempt.midi == key,
    );
  }

  static int pickPitchClass(
    Random rnd,
    Iterable<int> pitchClasses,
    List<PracticeAttempt> history,
  ) {
    final list = pitchClasses.toSet().toList()..sort();
    if (list.length == 1) {
      return list.first;
    }
    return _pick(
      rnd,
      list,
      history,
      matchHistory: (attempt, key) => attempt.midi % 12 == key,
    );
  }

  static List<PracticeAttempt> _lastTour(
    List<PracticeAttempt> history,
    int tourLen,
  ) {
    if (history.isEmpty) {
      return const [];
    }
    if (history.length <= tourLen) {
      return history;
    }
    return history.sublist(history.length - tourLen);
  }

  static List<PracticeAttempt> _lastAttemptsForKey<T>(
    List<PracticeAttempt> history,
    T key,
    int maxCount, {
    required bool Function(PracticeAttempt attempt, T key) matchHistory,
  }) {
    final out = <PracticeAttempt>[];
    for (var i = history.length - 1; i >= 0 && out.length < maxCount; i--) {
      if (matchHistory(history[i], key)) {
        out.add(history[i]);
      }
    }
    return out;
  }

  static int? _medianCorrectLatencyMs(List<PracticeAttempt> history) {
    final ms =
        history.where((a) => a.correct).map((a) => a.latencyMs).toList()
          ..sort();
    if (ms.isEmpty) {
      return null;
    }
    return ms[ms.length ~/ 2];
  }

  /// Son [attempts] ortalaması, etkinlikteki doğru cevap medyanına göre yavaş mı?
  static bool _slowInAttempts(
    List<PracticeAttempt> attempts,
    List<PracticeAttempt> history,
  ) {
    if (attempts.isEmpty) {
      return false;
    }
    final median = _medianCorrectLatencyMs(history);
    if (median == null) {
      return false;
    }
    final med = median.clamp(_baselineFloorMs, 20000);
    var sum = 0;
    for (final a in attempts) {
      sum += a.latencyMs;
    }
    final avg = sum / attempts.length;
    final margin = max(400, (med * 0.12).round());
    return avg > med + margin;
  }

  static bool _poolTourComplete<T>(
    List<T> keys,
    List<PracticeAttempt> history, {
    required bool Function(PracticeAttempt attempt, T key) matchHistory,
  }) {
    for (final k in keys) {
      if (!history.any((a) => matchHistory(a, k))) {
        return false;
      }
    }
    return true;
  }

  static int _weightUnit<T>(
    T key,
    List<T> keys,
    List<PracticeAttempt> history,
    List<PracticeAttempt> recentTour, {
    required bool Function(PracticeAttempt attempt, T key) matchHistory,
  }) {
    final ever = history.any((a) => matchHistory(a, key));
    if (!ever) {
      return _unitUnseen;
    }

    final tourComplete = _poolTourComplete(
      keys,
      history,
      matchHistory: matchHistory,
    );
    if (!tourComplete) {
      var shown = 0;
      for (final a in recentTour) {
        if (matchHistory(a, key)) {
          shown++;
        }
      }
      if (shown == 0) {
        return _unitWeak;
      }
      return _unitStrong;
    }

    final last = _lastAttemptsForKey(
      history,
      key,
      _lastStatCount,
      matchHistory: matchHistory,
    );
    if (last.isEmpty) {
      return _unitStrong;
    }
    if (last.any((a) => !a.correct)) {
      return _unitWeak;
    }
    if (_slowInAttempts(last, history)) {
      return _unitSlow;
    }
    return _unitStrong;
  }

  static double _weight<T>(
    T key,
    List<T> keys,
    List<PracticeAttempt> history,
    List<PracticeAttempt> recentTour, {
    required bool Function(PracticeAttempt attempt, T key) matchHistory,
  }) {
    final unit = _weightUnit(
      key,
      keys,
      history,
      recentTour,
      matchHistory: matchHistory,
    );

    if (unit == _unitUnseen) {
      return unit.toDouble();
    }

    if (!_poolTourComplete(keys, history, matchHistory: matchHistory)) {
      var shown = 0;
      for (final a in recentTour) {
        if (matchHistory(a, key)) {
          shown++;
        }
      }
      if (unit == _unitUnseen) {
        return _unitUnseen.toDouble();
      }
      final base = unit == _unitWeak ? _unitWeak.toDouble() : 1.0;
      return (base / (1.0 + shown * 1.2)).clamp(0.25, 8.0);
    }

    var w = unit.toDouble();

    // Aynı performans (birim 1): tur içinde eşit görünme.
    if (unit == _unitStrong) {
      var shown = 0;
      for (final a in recentTour) {
        if (matchHistory(a, key)) {
          shown++;
        }
      }
      w /= 1.0 + shown * 0.55;
    }

    return w.clamp(0.15, 12.0);
  }

  static T _pick<T>(
    Random rnd,
    List<T> keys,
    List<PracticeAttempt> history, {
    required bool Function(PracticeAttempt attempt, T key) matchHistory,
  }) {
    final tourLen = keys.length;
    final recentTour = _lastTour(history, tourLen);

    T? lastKey;
    if (history.isNotEmpty) {
      for (final k in keys) {
        if (matchHistory(history.last, k)) {
          lastKey = k;
          break;
        }
      }
    }

    final eligible = keys.length > 1 && lastKey != null
        ? keys.where((k) => k != lastKey).toList()
        : keys;

    final weights = eligible
        .map(
          (k) => _weight(
            k,
            keys,
            history,
            recentTour,
            matchHistory: matchHistory,
          ),
        )
        .toList();
    var sum = 0.0;
    for (final x in weights) {
      sum += x;
    }
    if (sum <= 0) {
      return eligible.first;
    }
    var t = rnd.nextDouble() * sum;
    for (var i = 0; i < eligible.length; i++) {
      t -= weights[i];
      if (t <= 0) {
        return eligible[i];
      }
    }
    return eligible.last;
  }
}

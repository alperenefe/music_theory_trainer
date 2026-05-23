import 'dart:math';

import '../models/guitar_note.dart';
import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';

/// Egzersiz hedefi: önce adil dönüşüm, sonra zayıf / hatalı notaları öne al.
abstract final class TargetPicker {
  static const int _fairnessWindow = 40;
  static const int _statsWindow = 120;

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

  /// Aynı pitch class için (gitar bul) — istatistik midi ile eşleşir.
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
    return _weightedPick(
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
    return _weightedPick(
      rnd,
      list,
      history,
      matchHistory: (attempt, key) => attempt.midi % 12 == key,
    );
  }

  static T _weightedPick<T>(
    Random rnd,
    List<T> keys,
    List<PracticeAttempt> history, {
    required bool Function(PracticeAttempt attempt, T key) matchHistory,
  }) {
    final recent = history.length <= _fairnessWindow
        ? history
        : history.sublist(history.length - _fairnessWindow);
    final statsSlice = history.length <= _statsWindow
        ? history
        : history.sublist(history.length - _statsWindow);

    final recentCount = <T, int>{};
    for (final k in keys) {
      recentCount[k] = 0;
    }
    for (final a in recent) {
      for (final k in keys) {
        if (matchHistory(a, k)) {
          recentCount[k] = (recentCount[k] ?? 0) + 1;
        }
      }
    }

    var minRecent = recentCount.values.first;
    for (final c in recentCount.values) {
      if (c < minRecent) {
        minRecent = c;
      }
    }

    final tier = (history.length ~/ 40).clamp(0, 20);
    final tierMul = 1.0 + tier * 0.028;

    double weight(T key) {
      final shown = recentCount[key] ?? 0;
      // Az görülen nota öne: 13×1 vs 1×1 dengesizliğini kırar.
      var w = 1.0 / (1.0 + shown * 1.35);
      if (shown <= minRecent + 1) {
        w *= 1.55;
      }

      final rs = statsSlice.where((e) => matchHistory(e, key)).toList();
      if (rs.length >= 2) {
        var correct = 0;
        var sumMs = 0;
        for (final e in rs) {
          sumMs += e.latencyMs;
          if (e.correct) {
            correct++;
          }
        }
        final acc = correct / rs.length;
        final errPart = (1.0 - acc) * 1.35;
        final slowPart = (sumMs / rs.length / 4000.0).clamp(0.0, 1.0) * 0.75;
        final weak = (errPart + slowPart).clamp(0.0, 2.4);
        w *= 1.0 + weak * 0.62 * tierMul;

        var missStreak = 0;
        for (var i = rs.length - 1; i >= 0; i--) {
          if (rs[i].correct) {
            break;
          }
          missStreak++;
        }
        if (missStreak > 0) {
          w *= pow(1.22, missStreak.clamp(0, 5)).toDouble();
        }
      } else if (rs.length == 1 && !rs.first.correct) {
        w *= 1.35 * tierMul;
      }

      if (history.isNotEmpty && matchHistory(history.last, key) && !history.last.correct) {
        w *= 1.28;
      }

      return w.clamp(0.12, 6.0);
    }

    final weights = keys.map(weight).toList();
    var sum = 0.0;
    for (final x in weights) {
      sum += x;
    }
    var t = rnd.nextDouble() * sum;
    for (var i = 0; i < keys.length; i++) {
      t -= weights[i];
      if (t <= 0) {
        return keys[i];
      }
    }
    return keys.last;
  }
}

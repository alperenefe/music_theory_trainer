import 'dart:math';

import '../models/guitar_note.dart';
import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';

/// Egzersiz hedefi: önce havuzdaki her nota en az bir kez (1 tur), sonra zayıflara ağırlık.
///
/// Tur uzunluğu = havuzdaki benzersiz nota sayısı; son [tur] deneme adillik ve
/// istatistik penceresi olarak kullanılır (sabit 50/120 yok).
abstract final class TargetPicker {
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

  static T _weightedPick<T>(
    Random rnd,
    List<T> keys,
    List<PracticeAttempt> history, {
    required bool Function(PracticeAttempt attempt, T key) matchHistory,
  }) {
    final tourLen = keys.length;
    final recent = _lastTour(history, tourLen);
    final tourComplete = _poolTourComplete(
      keys,
      history,
      matchHistory: matchHistory,
    );
    final statsSlice = recent;

    final recentCount = <T, int>{};
    final lifetimeCount = <T, int>{};
    for (final k in keys) {
      recentCount[k] = 0;
      lifetimeCount[k] = 0;
    }
    for (final a in recent) {
      for (final k in keys) {
        if (matchHistory(a, k)) {
          recentCount[k] = (recentCount[k] ?? 0) + 1;
        }
      }
    }
    for (final a in history) {
      for (final k in keys) {
        if (matchHistory(a, k)) {
          lifetimeCount[k] = (lifetimeCount[k] ?? 0) + 1;
        }
      }
    }

    var minRecent = recentCount.values.first;
    for (final c in recentCount.values) {
      if (c < minRecent) {
        minRecent = c;
      }
    }

    final toursDone = tourLen > 0 ? history.length ~/ tourLen : 0;
    final tierMul = 1.0 + toursDone.clamp(0, 20) * 0.028;

    double weight(T key) {
      final shown = recentCount[key] ?? 0;
      final ever = lifetimeCount[key] ?? 0;

      // Tur tamamlanmadan: hiç çıkmamış notalar öncelikli.
      if (!tourComplete) {
        if (ever == 0) {
          return 8.0;
        }
        var w = 1.0 / (1.0 + shown * 1.5);
        if (shown <= minRecent) {
          w *= 2.0;
        }
        return w.clamp(0.2, 8.0);
      }

      // Tur bitti: son [tourLen] denemeye göre adillik + zayıflık.
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

      if (history.isNotEmpty &&
          matchHistory(history.last, key) &&
          !history.last.correct) {
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

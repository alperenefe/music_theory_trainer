import 'dart:math';

import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';

final class TargetPicker {
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
    if (history.length < 50) {
      return pool[rnd.nextInt(pool.length)];
    }
    const recentN = 160;
    final slice = history.length <= recentN
        ? history
        : history.sublist(history.length - recentN);
    final tier = (history.length ~/ 50).clamp(0, 24);
    final tierMul = 1.0 + tier * 0.034;
    double w(NotationPitch p) {
      final rs = slice.where((e) => e.midi == p.midi).toList();
      if (rs.length < 2) {
        return 1.0;
      }
      var c = 0;
      var sum = 0;
      for (final e in rs) {
        sum += e.latencyMs;
        if (e.correct) {
          c++;
        }
      }
      final acc = c / rs.length;
      final avg = sum / rs.length;
      final errPart = (1.0 - acc) * 1.12;
      final slowPart = (avg / 4200.0).clamp(0.0, 1.0) * 0.88;
      final weak = (errPart + slowPart).clamp(0.0, 2.2);
      return 1.0 + weak * 0.52 * tierMul;
    }

    final weights = pool.map(w).toList();
    var s = 0.0;
    for (final x in weights) {
      s += x;
    }
    var t = rnd.nextDouble() * s;
    for (var i = 0; i < pool.length; i++) {
      t -= weights[i];
      if (t <= 0) {
        return pool[i];
      }
    }
    return pool.last;
  }
}

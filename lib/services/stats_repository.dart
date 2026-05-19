import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/practice_attempt.dart';

final class StatsRepository {
  static const _key = 'practice_attempts_v1';
  static const int maxStoredAttempts = 1000;
  static const int defaultExerciseWindow = 500;

  Future<List<PracticeAttempt>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) => PracticeAttempt.fromJson(
            Map<String, Object?>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  /// Bu egzersize ait son [limit] deneme (kronolojik).
  Future<List<PracticeAttempt>> recentForExercise(
    String exercise, {
    int limit = defaultExerciseWindow,
  }) async {
    final matching =
        (await load()).where((r) => r.exercise == exercise).toList();
    if (matching.length <= limit) {
      return matching;
    }
    return matching.sublist(matching.length - limit);
  }

  Future<void> append(PracticeAttempt a) async {
    final p = await SharedPreferences.getInstance();
    final cur = await load();
    cur.add(a);
    if (cur.length > maxStoredAttempts) {
      cur.removeRange(0, cur.length - maxStoredAttempts);
    }
    final encoded = jsonEncode(cur.map((e) => e.toJson()).toList());
    await p.setString(_key, encoded);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  /// Yalnızca bu egzersizin kayıtlarını siler.
  Future<void> clearExercise(String exercise) async {
    final p = await SharedPreferences.getInstance();
    final kept = (await load()).where((r) => r.exercise != exercise).toList();
    if (kept.isEmpty) {
      await p.remove(_key);
      return;
    }
    final encoded = jsonEncode(kept.map((e) => e.toJson()).toList());
    await p.setString(_key, encoded);
  }
}

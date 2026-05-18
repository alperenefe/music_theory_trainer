import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/practice_attempt.dart';

final class StatsRepository {
  static const _key = 'practice_attempts_v1';

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

  Future<void> append(PracticeAttempt a) async {
    final p = await SharedPreferences.getInstance();
    final cur = await load();
    cur.add(a);
    final encoded = jsonEncode(cur.map((e) => e.toJson()).toList());
    await p.setString(_key, encoded);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

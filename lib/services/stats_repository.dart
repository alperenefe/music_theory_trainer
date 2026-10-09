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
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return [];
    }
    if (decoded is! List) return [];
    final result = <PracticeAttempt>[];
    for (final e in decoded) {
      if (e is! Map) continue;
      try {
        result.add(
          PracticeAttempt.fromJson(Map<String, Object?>.from(e)),
        );
      } catch (_) {
        // Bozuk tek kayıt tüm geçmişi silmesin; sadece o kayıt atlanır.
      }
    }
    return result;
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
    final trimmed = _trimPerExercise(cur);
    final encoded = jsonEncode(trimmed.map((e) => e.toJson()).toList());
    await p.setString(_key, encoded);
  }

  /// Her egzersiz türü için AYRI AYRI en fazla [maxStoredAttempts] kayıt
  /// tutar (eskiden TÜM egzersizler tek ortak bir üst sınırı paylaşıyordu).
  ///
  /// Ortak sınırla, kullanıcı birden çok egzersiz türünde pratik yaptığında
  /// diğer egzersizlerdeki yeni denemeler, henüz tamamlanmamış bir hedefin
  /// ("goal") ait olduğu egzersizdeki eski denemelerini sessizce siliyordu;
  /// bu da [GoalTracker] ve [GoalProgressSnapshot]'ın doğruluk/en iyi
  /// seri/ortalama süre gibi hedef istatistiklerini yanlış (eksik veriyle)
  /// hesaplamasına yol açıyordu. Egzersiz başına ayrı sınır bu sessiz
  /// veri kaybını engeller.
  List<PracticeAttempt> _trimPerExercise(List<PracticeAttempt> all) {
    final byExercise = <String, List<PracticeAttempt>>{};
    for (final a in all) {
      (byExercise[a.exercise] ??= <PracticeAttempt>[]).add(a);
    }
    final out = <PracticeAttempt>[];
    for (final list in byExercise.values) {
      out.addAll(
        list.length <= maxStoredAttempts
            ? list
            : list.sublist(list.length - maxStoredAttempts),
      );
    }
    out.sort((a, b) => a.atMillis.compareTo(b.atMillis));
    return out;
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

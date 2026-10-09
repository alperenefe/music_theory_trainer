import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final class EarSrsCard {
  const EarSrsCard({
    required this.key,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitionCount = 0,
    this.nextReviewAt = 0,
  });

  final String key;
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final int nextReviewAt;

  bool get isDueNow =>
      DateTime.now().millisecondsSinceEpoch >= nextReviewAt;

  EarSrsCard update({required bool correct, required int latencyMs}) {
    final q = _qualityRating(correct: correct, latencyMs: latencyMs);

    var newEF = easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (newEF < 1.3) newEF = 1.3;

    final now = DateTime.now().millisecondsSinceEpoch;

    if (q < 3) {
      return EarSrsCard(
        key: key,
        easeFactor: newEF,
        intervalDays: 1,
        repetitionCount: 0,
        nextReviewAt: now + const Duration(days: 1).inMilliseconds,
      );
    }

    final newRep = repetitionCount + 1;
    final int newInterval;
    if (newRep == 1) {
      newInterval = 1;
    } else if (newRep == 2) {
      newInterval = 4;
    } else {
      newInterval = (intervalDays * newEF).round().clamp(1, 365);
    }

    return EarSrsCard(
      key: key,
      easeFactor: newEF,
      intervalDays: newInterval,
      repetitionCount: newRep,
      nextReviewAt: now + Duration(days: newInterval).inMilliseconds,
    );
  }

  static int _qualityRating({required bool correct, required int latencyMs}) {
    if (!correct) return 1;
    if (latencyMs < 2000) return 5;
    if (latencyMs < 4000) return 4;
    return 3;
  }

  Map<String, Object?> toJson() => {
        'key': key,
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'repetitionCount': repetitionCount,
        'nextReviewAt': nextReviewAt,
      };

  static EarSrsCard fromJson(Map<String, Object?> j) {
    double nd(Object? v, double d) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      return d;
    }

    int ni(Object? v, int d) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return d;
    }

    return EarSrsCard(
      key: j['key']?.toString() ?? '',
      easeFactor: nd(j['easeFactor'], 2.5),
      intervalDays: ni(j['intervalDays'], 1),
      repetitionCount: ni(j['repetitionCount'], 0),
      nextReviewAt: ni(j['nextReviewAt'], 0),
    );
  }
}

final class EarSrsService {
  static const _key = 'ear_srs_cards_v1';

  Future<Map<String, EarSrsCard>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return {};
    }
    if (decoded is! Map) return {};
    final result = <String, EarSrsCard>{};
    for (final entry in decoded.entries) {
      final v = entry.value;
      if (v is Map) {
        result[entry.key.toString()] =
            EarSrsCard.fromJson(Map<String, Object?>.from(v));
      }
    }
    return result;
  }

  Future<void> save(Map<String, EarSrsCard> cards) async {
    final p = await SharedPreferences.getInstance();
    final j = {
      for (final e in cards.entries) e.key: e.value.toJson(),
    };
    await p.setString(_key, jsonEncode(j));
  }

  Future<EarSrsCard> recordAttempt({
    required String cardKey,
    required bool correct,
    required int latencyMs,
  }) async {
    final cards = await load();
    final existing = cards[cardKey] ?? EarSrsCard(key: cardKey);
    final updated = existing.update(correct: correct, latencyMs: latencyMs);
    cards[cardKey] = updated;
    await save(cards);
    return updated;
  }

  /// Tekrar zamanı gelmiş kartlar; en çok geciken önce.
  Future<List<String>> dueToday({DateTime? now}) async {
    final cards = await load();
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final due = cards.values.where((c) => t >= c.nextReviewAt).toList()
      ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return due.map((c) => c.key).toList();
  }
}

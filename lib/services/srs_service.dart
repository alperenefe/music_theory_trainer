import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/srs_card.dart';

/// SM-2 kart havuzunu SharedPreferences'ta saklar.
/// Her porte egzersizi kendi kartını güncellemek için bu servisi kullanır.
final class SrsService {
  static const _key = 'srs_cards_v1';

  Future<Map<int, SrsCard>> load() async {
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
    final result = <int, SrsCard>{};
    for (final entry in decoded.entries) {
      final midi = int.tryParse(entry.key.toString());
      if (midi == null) continue;
      if (entry.value is Map) {
        try {
          result[midi] = SrsCard.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
        } catch (_) {
          // Bozuk tek kart tüm SRS havuzunu silmesin; sadece o kart atlanır.
        }
      }
    }
    return result;
  }

  Future<void> save(Map<int, SrsCard> cards) async {
    final p = await SharedPreferences.getInstance();
    final j = {
      for (final e in cards.entries) '${e.key}': e.value.toJson(),
    };
    await p.setString(_key, jsonEncode(j));
  }

  /// [midi] için kartı güncelle ve kaydet.
  Future<SrsCard> recordAttempt({
    required int midi,
    required bool correct,
    required int latencyMs,
  }) async {
    final cards = await load();
    final existing = cards[midi] ?? SrsCard(midi: midi);
    final updated = existing.update(correct: correct, latencyMs: latencyMs);
    cards[midi] = updated;
    await save(cards);
    return updated;
  }

  /// Bugün tekrar edilmesi gereken notaların MIDI listesi.
  Future<List<int>> dueToday() async {
    final cards = await load();
    return cards.values.where((c) => c.isDueNow).map((c) => c.midi).toList();
  }
}

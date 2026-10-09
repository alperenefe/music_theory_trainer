import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/practice_prefs.dart';

final class PracticePrefsRepository {
  static const _key = 'practice_prefs_v1';

  Future<PracticePrefs> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const PracticePrefs();
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const PracticePrefs();
    }
    if (decoded is! Map) return const PracticePrefs();
    try {
      return PracticePrefs.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return const PracticePrefs();
    }
  }

  Future<void> save(PracticePrefs prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(prefs.toJson()));
  }
}

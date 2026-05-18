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
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return PracticePrefs.fromJson(Map<String, Object?>.from(j));
  }

  Future<void> save(PracticePrefs prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(prefs.toJson()));
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/services/guitar_practice_clock.dart';
import 'package:music_theory_trainer/services/practice_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('gün anahtarı yerel tarihtir', () {
    expect(PracticeDay.key(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });

  test('süre bugüne yazılır, 2 sn altı yazılmaz, tek kayıt 10 dk ile sınırlı', () async {
    final repo = PracticePrefsRepository();
    var ms = 90000;
    final day = DateTime(2026, 10, 9, 12);
    final clock = GuitarPracticeClock(repo: repo, now: () => day, elapsedMs: () => ms);
    expect(await clock.commit(), 90000);
    expect((await repo.load()).practiceMsOn('2026-10-09'), 90000);

    ms = 1500;
    expect(await clock.commit(), 0);
    expect((await repo.load()).practiceMsOn('2026-10-09'), 90000);

    ms = 3 * 3600 * 1000; // ekran açık unutuldu
    await clock.commit();
    expect((await repo.load()).practiceMsOn('2026-10-09'), 90000 + 600000);
  });
}

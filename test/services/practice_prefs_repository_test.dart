import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:music_theory_trainer/services/practice_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await p.clear();
  });

  test('roundtrip', () async {
    final r = PracticePrefsRepository();
    const a = PracticePrefs(
      poolMinMidi: 62,
      poolMaxMidi: 79,
      goalKind: 'placement',
      goalTarget: 120,
      goalProgress: 5,
      goalStartedAtMillis: 999,
      soundEnabled: true,
      onboardingDone: true,
    );
    await r.save(a);
    final b = await r.load();
    expect(b.poolMinMidi, 62);
    expect(b.poolMaxMidi, 79);
    expect(b.goalKind, 'placement');
    expect(b.goalTarget, 120);
    expect(b.goalProgress, 5);
    expect(b.goalStartedAtMillis, 999);
    expect(b.soundEnabled, isTrue);
    expect(b.onboardingDone, isTrue);
  });
}

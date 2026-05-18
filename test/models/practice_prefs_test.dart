import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';

void main() {
  group('PracticePrefs.fromJson', () {
    test('havuz alanları yoksa porte varsayılanı', () {
      final p = PracticePrefs.fromJson({});
      expect(p.poolMinMidi, PracticePrefs.defaultPoolMinMidi);
      expect(p.poolMaxMidi, PracticePrefs.defaultPoolMaxMidi);
      expect(p.referenceA4Hz, PracticePrefs.defaultReferenceA4Hz);
    });

    test('yeni alanlar eksikse migration varsayılanları', () {
      final p = PracticePrefs.fromJson({
        'poolMinMidi': 60,
        'poolMaxMidi': 72,
        'goalKind': 'mcq',
        'goalTarget': 100,
        'goalProgress': 3,
        'goalStartedAtMillis': 1,
      });
      expect(p.soundEnabled, isTrue);
      expect(p.onboardingDone, isTrue);
    });

    test('soundEnabled ve onboardingDone açıkça okunur', () {
      final p = PracticePrefs.fromJson({
        'poolMinMidi': 60,
        'poolMaxMidi': 72,
        'goalKind': null,
        'goalTarget': 500,
        'goalProgress': 0,
        'goalStartedAtMillis': 0,
        'soundEnabled': false,
        'onboardingDone': false,
      });
      expect(p.soundEnabled, isFalse);
      expect(p.onboardingDone, isFalse);
    });

    test('toJson roundtrip', () {
      const a = PracticePrefs(
        poolMinMidi: 61,
        poolMaxMidi: 80,
        goalKind: 'placement',
        goalTarget: 200,
        goalProgress: 4,
        goalStartedAtMillis: 99,
        soundEnabled: false,
        onboardingDone: true,
        referenceA4Hz: 442,
      );
      final b = PracticePrefs.fromJson(a.toJson());
      expect(b.poolMinMidi, a.poolMinMidi);
      expect(b.poolMaxMidi, a.poolMaxMidi);
      expect(b.goalKind, a.goalKind);
      expect(b.goalTarget, a.goalTarget);
      expect(b.goalProgress, a.goalProgress);
      expect(b.goalStartedAtMillis, a.goalStartedAtMillis);
      expect(b.soundEnabled, a.soundEnabled);
      expect(b.onboardingDone, a.onboardingDone);
      expect(b.referenceA4Hz, a.referenceA4Hz);
    });

    test('onboardingDone 1 veya string true okunur', () {
      expect(
        PracticePrefs.fromJson({
          'onboardingDone': 1,
        }).onboardingDone,
        isTrue,
      );
      expect(
        PracticePrefs.fromJson({
          'onboardingDone': 'true',
        }).onboardingDone,
        isTrue,
      );
    });

    test('referenceA4Hz aşırı değerler sıkıştırılır', () {
      final p = PracticePrefs.fromJson({'referenceA4Hz': 900});
      expect(p.referenceA4Hz, 455);
      final q = PracticePrefs.fromJson({'referenceA4Hz': 400});
      expect(q.referenceA4Hz, 415);
    });
  });
}

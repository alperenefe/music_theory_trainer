import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/ear_exercise_kind.dart';
import 'package:music_theory_trainer/models/ear_session_result.dart';
import 'package:music_theory_trainer/models/weekly_progress.dart';
import 'package:music_theory_trainer/services/ear_curriculum_service.dart';
import 'package:music_theory_trainer/services/weak_spot_analyzer.dart';
import 'package:music_theory_trainer/services/weekly_mastery_gate.dart';

EarSessionResult _session({
  int week = 1,
  int total = 10,
  int correct = 9,
  DateTime? at,
  EarSessionMode mode = EarSessionMode.practice,
  Map<String, int> errors = const {},
  Map<String, int> attempts = const {},
}) =>
    EarSessionResult(
      kind: EarExerciseKind.intervalBlind,
      weekNumber: week,
      totalQuestions: total,
      correctCount: correct,
      errorsBySubtype: errors,
      attemptsBySubtype: attempts,
      durationSeconds: 60,
      completedAt: at ?? DateTime(2026, 9, 1, 12),
      mode: mode,
    );

void main() {
  group('EarCurriculumService', () {
    const service = EarCurriculumService();

    test('ensureProgressList initializes 12 weeks with week 1 unlocked', () {
      final list = service.ensureProgressList([]);
      expect(list.length, 12);
      expect(list.first.weekNumber, 1);
      expect(list.first.isUnlocked, isTrue);
      expect(list[1].weekNumber, 2);
      expect(list[1].isUnlocked, isFalse);
    });

    test('currentWeek returns the first unlocked incomplete week', () {
      final list = service.ensureProgressList([
        const WeeklyProgress(weekNumber: 1, isUnlocked: true, isCompleted: true),
        const WeeklyProgress(weekNumber: 2, isUnlocked: true, isCompleted: false),
      ]);
      final current = service.currentWeek(list);
      expect(current.weekNumber, 2);
    });

    test('calculateStreak counts consecutive calendar days', () {
      final now = DateTime(2026, 9, 23, 10);
      final days = {
        WeeklyProgress.dayKey(now),
        WeeklyProgress.dayKey(DateTime(2026, 9, 22, 23, 50)),
        WeeklyProgress.dayKey(DateTime(2026, 9, 21, 8)),
        WeeklyProgress.dayKey(DateTime(2026, 9, 18, 8)), // boşluk: sayılmaz
      };
      expect(service.calculateStreak(days, now: now), 3);
    });

    test('calculateStreak keeps yesterday streak when not practiced today yet', () {
      final now = DateTime(2026, 9, 23, 10);
      final days = {WeeklyProgress.dayKey(DateTime(2026, 9, 22, 9))};
      expect(service.calculateStreak(days, now: now), 1);
      expect(service.practicedToday(days, now: now), isFalse);
    });
  });

  group('WeeklyMasteryGate', () {
    final initial = const EarCurriculumService().ensureProgressList(const []);

    test('does not pass on a single day even with high accuracy (minDaysActive)', () {
      final updated = WeeklyMasteryGate.applySession(
        progressList: initial,
        session: _session(total: 25, correct: 24),
      );
      expect(updated[0].totalQuestions, 25);
      expect(updated[0].activeDays, hasLength(1));
      expect(updated[0].isCompleted, isFalse);
      expect(updated[1].isUnlocked, isFalse);
    });

    test(
      'passes after enough questions, accuracy, distinct days AND boss cleared; unlocks next week',
      () {
        var list = initial;
        for (var d = 1; d <= 3; d++) {
          list = WeeklyMasteryGate.applySession(
            progressList: list,
            session: _session(total: 10, correct: 9, at: DateTime(2026, 9, d, 12)),
          );
        }
        // Diğer barajlar geçilmiş olsa da boss henüz yenilmedi: hafta tamamlanmaz.
        expect(list[0].activeDays, hasLength(3));
        expect(list[0].isCompleted, isFalse);
        expect(list[1].isUnlocked, isFalse);

        list = WeeklyMasteryGate.applySession(
          progressList: list,
          session: _session(
            total: 10,
            correct: 9,
            mode: EarSessionMode.boss,
            at: DateTime(2026, 9, 3, 13),
          ),
        );
        expect(list[0].bossCleared, isTrue);
        expect(list[0].isCompleted, isTrue);
        expect(list[0].completedAt, DateTime(2026, 9, 3, 13));
        expect(list[1].isUnlocked, isTrue);
      },
    );

    test('same day sessions count as one active day', () {
      var list = initial;
      for (var h = 8; h < 11; h++) {
        list = WeeklyMasteryGate.applySession(
          progressList: list,
          session: _session(at: DateTime(2026, 9, 1, h)),
        );
      }
      expect(list[0].activeDays, hasLength(1));
    });

    test('review sessions do not count toward the gate', () {
      final updated = WeeklyMasteryGate.applySession(
        progressList: initial,
        session: _session(mode: EarSessionMode.review),
      );
      expect(updated[0].totalQuestions, 0);
    });

    test('boss session above threshold marks bossCleared', () {
      final updated = WeeklyMasteryGate.applySession(
        progressList: initial,
        session: _session(total: 15, correct: 14, mode: EarSessionMode.boss),
      );
      expect(updated[0].bossCleared, isTrue);
    });

    test('GateStatus fractions are clamped', () {
      const p = WeeklyProgress(weekNumber: 1, isUnlocked: true, totalQuestions: 999, bestAccuracy: 1);
      final s = WeeklyMasteryGate.status(p, const EarCurriculumService().currentWeek([p]));
      expect(s.questionsFraction, 1.0);
      expect(s.accuracyFraction, 1.0);
      expect(s.daysFraction, 0.0);
      expect(s.passed, isFalse);
    });
  });

  group('WeakSpotAnalyzer', () {
    const analyzer = WeakSpotAnalyzer();

    test('aggregates errors and returns top weak spots', () {
      final sessions = [
        _session(correct: 7, errors: {'interval_minor3': 2, 'interval_major3': 1}),
        _session(correct: 6, errors: {'interval_minor3': 3, 'chord_minor': 1}),
      ];

      final top = analyzer.topWeakSpots(sessions, n: 2);
      expect(top.first.subtype, 'interval_minor3');
      expect(top.first.errorCount, 5);
      expect(top.first.label, contains('Küçük 3'));
    });

    test('uses the newest sessions (history is stored newest-first)', () {
      final sessions = [
        _session(errors: {'chord_minor': 1}), // en yeni
        for (var i = 0; i < 20; i++) _session(),
        _session(errors: {'interval_octave': 9}), // en eski — pencere dışı
      ];
      final agg = analyzer.aggregateErrors(sessions, lastN: 15);
      expect(agg.containsKey('chord_minor'), isTrue);
      expect(agg.containsKey('interval_octave'), isFalse);
    });

    test(
      'ranks by error RATE, not raw count, once both subtypes have enough samples',
      () {
        // Çok denenmiş eski konu: 200 denemede 10 hata (%5).
        // Az denenmiş yeni konu: 12 denemede 6 hata (%50).
        final sessions = [
          _session(
            errors: {'interval_minor3': 10},
            attempts: {'interval_minor3': 200, 'chord_dominant7': 12},
          ),
          _session(errors: {'chord_dominant7': 6}),
        ];
        final top = analyzer.topWeakSpots(sessions, n: 2);
        expect(top.first.subtype, 'chord_dominant7');
        expect(top.first.errorRate, closeTo(0.5, 0.001));
        expect(top.last.subtype, 'interval_minor3');
      },
    );

    test(
      'falls back to raw error count when a subtype has too few samples',
      () {
        // interval_octave: tek denemede 1 hata (%100 ama örneklem çok düşük).
        // interval_minor3: 200 denemede 10 hata (%5 ama güvenilir örneklem).
        final sessions = [
          _session(
            errors: {'interval_minor3': 10, 'interval_octave': 1},
            attempts: {'interval_minor3': 200, 'interval_octave': 1},
          ),
        ];
        final top = analyzer.topWeakSpots(sessions, n: 2);
        // Güvenilir örneklemi olan (>=5 deneme) her zaman önce gelir.
        expect(top.first.subtype, 'interval_minor3');
      },
    );
  });
}

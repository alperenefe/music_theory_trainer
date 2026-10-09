import '../models/ear_curriculum.dart';
import '../models/ear_session_result.dart';
import '../models/weekly_progress.dart';

/// Bir haftanın baraj kriterlerine göre ilerleme durumu (UI için).
final class GateStatus {
  const GateStatus({
    required this.gate,
    required this.accuracy,
    required this.questions,
    required this.days,
    required this.bossRequired,
    required this.bossCleared,
  });

  final MasteryGate gate;
  final double accuracy;
  final int questions;
  final int days;
  final bool bossRequired;
  final bool bossCleared;

  bool get accuracyMet => accuracy >= gate.accuracyThreshold;
  bool get questionsMet => questions >= gate.minQuestions;
  bool get daysMet => days >= gate.minDaysActive;
  bool get bossMet => !bossRequired || bossCleared;
  bool get passed => accuracyMet && questionsMet && daysMet && bossMet;

  double get accuracyFraction =>
      gate.accuracyThreshold <= 0 ? 1.0 : (accuracy / gate.accuracyThreshold).clamp(0.0, 1.0);
  double get questionsFraction =>
      gate.minQuestions <= 0 ? 1.0 : (questions / gate.minQuestions).clamp(0.0, 1.0);
  double get daysFraction =>
      gate.minDaysActive <= 0 ? 1.0 : (days / gate.minDaysActive).clamp(0.0, 1.0);

  /// Üç kriterin ortalaması — halka/ilerleme göstergeleri için.
  double get overallFraction =>
      (accuracyFraction + questionsFraction + daysFraction) / 3;
}

final class WeeklyMasteryGate {
  const WeeklyMasteryGate();

  static GateStatus status(WeeklyProgress progress, EarWeek week) => GateStatus(
        gate: week.gate,
        accuracy: progress.gateAccuracy,
        questions: progress.totalQuestions,
        days: progress.activeDays.length,
        bossRequired: week.bossTitle != null,
        bossCleared: progress.bossCleared,
      );

  static bool isWeekPassed(WeeklyProgress progress, EarWeek week) =>
      status(progress, week).passed;

  /// Seansı ilgili haftaya işler; baraj geçildiyse sonraki haftayı açar.
  ///
  /// [progressList] eksik haftalar içerebilir; çağıran taraf önce
  /// `EarCurriculumService.ensureProgressList` ile tamamlamalıdır.
  static List<WeeklyProgress> applySession({
    required List<WeeklyProgress> progressList,
    required EarSessionResult session,
  }) {
    final list = [...progressList];
    if (!session.mode.countsTowardGate) return list;

    final weekIdx = list.indexWhere((p) => p.weekNumber == session.weekNumber);
    if (weekIdx == -1) return list;

    final current = list[weekIdx];
    final newQuestions = current.totalQuestions + session.totalQuestions;
    final newCorrect = current.totalCorrect + session.correctCount;
    final sessionAcc = session.accuracy;
    final newBestAcc =
        sessionAcc > current.bestAccuracy ? sessionAcc : current.bestAccuracy;

    final updatedErrors = Map<String, int>.from(current.errorsBySubtype);
    for (final e in session.errorsBySubtype.entries) {
      updatedErrors[e.key] = (updatedErrors[e.key] ?? 0) + e.value;
    }

    final day = WeeklyProgress.dayKey(session.completedAt);
    final days = current.activeDays.contains(day)
        ? current.activeDays
        : [...current.activeDays, day];

    final week = earWeekByNumber(session.weekNumber);
    final bossCleared = current.bossCleared ||
        (session.mode == EarSessionMode.boss &&
            sessionAcc >= week.gate.accuracyThreshold);

    var updated = current.copyWith(
      totalQuestions: newQuestions,
      totalCorrect: newCorrect,
      bestAccuracy: newBestAcc,
      recentAccuracies: current.withRecentAccuracy(sessionAcc),
      errorsBySubtype: updatedErrors,
      activeDays: days,
      bossCleared: bossCleared,
    );

    final passed = isWeekPassed(updated, week);
    updated = updated.copyWith(
      isCompleted: current.isCompleted || passed,
      completedAt: (passed && current.completedAt == null)
          ? session.completedAt
          : current.completedAt,
    );
    list[weekIdx] = updated;

    if (updated.isCompleted && session.weekNumber < earCurriculumWeeks.length) {
      final nextIdx =
          list.indexWhere((p) => p.weekNumber == session.weekNumber + 1);
      if (nextIdx != -1 && !list[nextIdx].isUnlocked) {
        list[nextIdx] = list[nextIdx].copyWith(
          isUnlocked: true,
          unlockedAt: session.completedAt,
        );
      }
    }

    return list;
  }
}

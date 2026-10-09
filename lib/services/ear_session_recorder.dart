import '../models/ear_curriculum.dart';
import '../models/ear_session_result.dart';
import '../models/weekly_progress.dart';
import 'ear_curriculum_service.dart';
import 'practice_prefs_repository.dart';
import 'weekly_mastery_gate.dart';

/// Bir seansın kaydedilmesinin sonucu (sonuç ekranı için önce/sonra durumu).
final class EarSessionOutcome {
  const EarSessionOutcome({
    required this.result,
    required this.week,
    required this.before,
    required this.after,
    this.unlockedWeek,
  });

  final EarSessionResult result;
  final EarWeek week;
  final WeeklyProgress before;
  final WeeklyProgress after;

  /// Bu seansla kilidi açılan hafta (varsa).
  final EarWeek? unlockedWeek;

  bool get weekJustCompleted => !before.isCompleted && after.isCompleted;
  bool get bossJustCleared => !before.bossCleared && after.bossCleared;
  GateStatus get gate => WeeklyMasteryGate.status(after, week);
}

/// Seansı kalıcı hale getirir: haftalık ilerleme + seans geçmişi.
///
/// Not: Önceki sürümde ilerleme listesi hiç kaydedilmediği için boş liste
/// üzerinde `applySession` çalışıyor ve ilk seanslar kayboluyordu; burada
/// liste her zaman 12 haftaya tamamlanıp öyle işlenir.
final class EarSessionRecorder {
  const EarSessionRecorder(this.repo);

  static const maxHistory = 60;

  final PracticePrefsRepository repo;

  Future<EarSessionOutcome> record(EarSessionResult result) async {
    const curriculum = EarCurriculumService();
    final prefs = await repo.load();
    final progress = curriculum.ensureProgressList(prefs.earWeekProgress);
    final week = earWeekByNumber(result.weekNumber);

    final before = curriculum.progressForWeek(result.weekNumber, progress);
    final updated = WeeklyMasteryGate.applySession(
      progressList: progress,
      session: result,
    );
    final after = curriculum.progressForWeek(result.weekNumber, updated);

    EarWeek? unlocked;
    final nextNumber = result.weekNumber + 1;
    if (nextNumber <= earCurriculumWeeks.length) {
      final nextBefore = curriculum.progressForWeek(nextNumber, progress);
      final nextAfter = curriculum.progressForWeek(nextNumber, updated);
      if (!nextBefore.isUnlocked && nextAfter.isUnlocked) {
        unlocked = earWeekByNumber(nextNumber);
      }
    }

    final history = [result, ...prefs.earSessionHistory].take(maxHistory).toList();
    await repo.save(
      prefs.copyWith(earWeekProgress: updated, earSessionHistory: history),
    );

    return EarSessionOutcome(
      result: result,
      week: week,
      before: before,
      after: after,
      unlockedWeek: unlocked,
    );
  }

  /// Haftalık öz değerlendirmeyi kaydeder.
  Future<WeeklyProgress> saveReflection({
    required int weekNumber,
    required int confidence,
    required String hardestArea,
  }) async {
    const curriculum = EarCurriculumService();
    final prefs = await repo.load();
    final progress = curriculum.ensureProgressList(prefs.earWeekProgress);
    final idx = progress.indexWhere((p) => p.weekNumber == weekNumber);
    if (idx == -1) {
      return WeeklyProgress(weekNumber: weekNumber);
    }
    final updated = progress[idx].copyWith(
      confidence: confidence.clamp(1, 5),
      hardestArea: hardestArea,
    );
    final list = [...progress]..[idx] = updated;
    await repo.save(prefs.copyWith(earWeekProgress: list));
    return updated;
  }

  /// [EarLessonScreen] açıldığında işaretler — "Dersi Oku" kartında
  /// tamamlandı rozetini göstermek için. Zaten görüldüyse no-op.
  Future<WeeklyProgress> markLessonViewed(int weekNumber) async {
    const curriculum = EarCurriculumService();
    final prefs = await repo.load();
    final progress = curriculum.ensureProgressList(prefs.earWeekProgress);
    final idx = progress.indexWhere((p) => p.weekNumber == weekNumber);
    if (idx == -1) {
      return WeeklyProgress(weekNumber: weekNumber);
    }
    if (progress[idx].lessonViewed) return progress[idx];
    final updated = progress[idx].copyWith(lessonViewed: true);
    final list = [...progress]..[idx] = updated;
    await repo.save(prefs.copyWith(earWeekProgress: list));
    return updated;
  }
}

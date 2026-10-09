import '../models/ear_curriculum.dart';
import '../models/ear_exercise_kind.dart';
import '../models/weekly_progress.dart';

final class EarCurriculumService {
  const EarCurriculumService();

  List<WeeklyProgress> ensureProgressList(List<WeeklyProgress> existing) {
    final map = {for (final p in existing) p.weekNumber: p};
    final out = <WeeklyProgress>[];
    for (int w = 1; w <= 12; w++) {
      if (map.containsKey(w)) {
        out.add(map[w]!);
      } else {
        out.add(
          WeeklyProgress(
            weekNumber: w,
            isUnlocked: w == 1,
            unlockedAt: w == 1 ? DateTime.now() : null,
          ),
        );
      }
    }
    return out;
  }

  WeeklyProgress progressForWeek(
    int weekNumber,
    List<WeeklyProgress> progressList,
  ) {
    final list = ensureProgressList(progressList);
    return list.firstWhere(
      (p) => p.weekNumber == weekNumber,
      orElse: () => WeeklyProgress(weekNumber: weekNumber),
    );
  }

  EarWeek currentWeek(List<WeeklyProgress> progressList) {
    final list = ensureProgressList(progressList);
    for (final p in list) {
      if (p.isUnlocked && !p.isCompleted) {
        return earCurriculumWeeks.firstWhere(
          (w) => w.weekNumber == p.weekNumber,
          orElse: () => earCurriculumWeeks.first,
        );
      }
    }
    return earCurriculumWeeks.last;
  }

  bool isWeekUnlocked(int weekNumber, List<WeeklyProgress> progressList) {
    if (weekNumber == 1) return true;
    final list = ensureProgressList(progressList);
    final p = list.firstWhere(
      (x) => x.weekNumber == weekNumber,
      orElse: () => WeeklyProgress(weekNumber: weekNumber),
    );
    return p.isUnlocked;
  }

  List<EarExerciseKind> todayExercises(EarWeek week) {
    return week.exercises;
  }

  /// Tüm haftalardaki [WeeklyProgress.activeDays]'in birleşimi — bu liste
  /// `earSessionHistory`nin aksine ASLA budanmaz (bkz. [EarSessionRecorder]
  /// `maxHistory`). Seri/streak ve "bugün çalıştın mı" hesapları bu yüzden
  /// `earSessionHistory` yerine bu birleşimi kullanmalı: günde birden fazla
  /// seans yapan bir kullanıcı 60 kayıtlık sınırı haftalar içinde doldurur,
  /// ve eski günlerin TÜM seansları listeden düşerse o gün "hiç çalışılmamış"
  /// gibi görünüp aktif bir seriyi hatalı biçimde kırar.
  Set<String> practicedDayKeys(List<WeeklyProgress> progressList) {
    final out = <String>{};
    for (final p in progressList) {
      out.addAll(p.activeDays);
    }
    return out;
  }

  int calculateStreak(Set<String> practicedDays, {DateTime? now}) {
    if (practicedDays.isEmpty) return 0;

    final today = now ?? DateTime.now();
    var streak = 0;
    for (var i = 0; i < 366; i++) {
      // Takvim günü bazında geri git (yaz saati geçişlerinde 24 saat çıkarmak
      // aynı günü iki kez sayabilir).
      final day = DateTime(today.year, today.month, today.day - i);
      if (practicedDays.contains(WeeklyProgress.dayKey(day))) {
        streak++;
      } else {
        // Bugün henüz pratik yapılmadıysa seri dünden itibaren sayılır.
        if (i == 0) continue;
        break;
      }
    }
    return streak;
  }

  /// Bugün en az bir seans tamamlandı mı (günlük hedef rozeti için).
  bool practicedToday(Set<String> practicedDays, {DateTime? now}) {
    final key = WeeklyProgress.dayKey(now ?? DateTime.now());
    return practicedDays.contains(key);
  }
}

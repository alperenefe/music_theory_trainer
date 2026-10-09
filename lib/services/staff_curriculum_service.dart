import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';
import '../l10n/app_strings.dart';

/// Treble porte notalarını 5 faza böler.
/// Faz 1: 5 çizgi (EVERY GOOD BOY / Mi Sol Si Re Fa)
/// Faz 2: 4 aralık (FACE / Fa La Do Mi)
/// Faz 3: Alt ek çizgiler (Re Do Si)
/// Faz 4: Üst ek çizgiler (Sol La Si)
/// Faz 5: Derin alt ek çizgiler (La Sol Fa Mi)
abstract final class StaffCurriculumService {
  static const int minPhase = 1;
  static const int maxPhase = 5;

  /// %80 doğruluk, son 10 denemede — kilit açma eşiği.
  static const double _unlockThreshold = 0.80;
  static const int _unlockWindow = 10;

  /// Faz başına sounding MIDI listesi.
  static const Map<int, List<int>> _phaseMidis = {
    1: [52, 55, 59, 62, 65], // 5 çizgi: Mi Sol Si Re Fa
    2: [53, 57, 60, 64],     // 4 aralık: Fa La Do Mi
    3: [50, 48, 47],         // Alt ek çizgi: Re Do Si
    4: [67, 69, 71],         // Üst ek çizgi: Sol La Si
    5: [45, 43, 41, 40],     // Derin alt: La Sol Fa Mi
  };

  /// 1–[currentPhase] arası tüm notaların aktif pool'u.
  static List<NotationPitch> activePool(int currentPhase) {
    final phase = currentPhase.clamp(minPhase, maxPhase);
    final activeMidis = <int>{};
    for (var p = minPhase; p <= phase; p++) {
      activeMidis.addAll(_phaseMidis[p] ?? const []);
    }
    return NotationPitch.trainingPool()
        .where((n) => activeMidis.contains(n.midi))
        .toList();
  }

  /// Belirtilen fazın MIDI kümesi.
  static Set<int> phaseMidis(int phase) =>
      Set<int>.unmodifiable(_phaseMidis[phase] ?? const []);

  /// Mevcut faz tamamlandı mı?
  /// Hem MCQ hem Placement denemeleri birlikte değerlendirilir.
  static bool canAdvancePhase(
    int currentPhase,
    List<PracticeAttempt> staffHistory,
  ) {
    if (currentPhase >= maxPhase) return false;
    final midis = phaseMidis(currentPhase);
    if (midis.isEmpty) return false;

    final relevant =
        staffHistory.where((a) => midis.contains(a.midi)).toList();
    if (relevant.length < _unlockWindow) return false;

    final window = relevant.sublist(relevant.length - _unlockWindow);
    final correct = window.where((a) => a.correct).length;
    return correct / window.length >= _unlockThreshold;
  }

  /// MCQ + Placement denemelerini filtrele.
  static List<PracticeAttempt> staffAttempts(List<PracticeAttempt> all) =>
      all
          .where(
            (a) =>
                a.exercise == AppStrings.exerciseMcq ||
                a.exercise == AppStrings.exercisePlacement,
          )
          .toList();
}

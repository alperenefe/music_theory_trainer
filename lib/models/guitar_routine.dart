import 'guitar_path.dart';

/// Günlük 15 dakikalık çalışma rutininin bir bloğu.
final class RoutineBlock {
  const RoutineBlock({
    required this.minutes,
    required this.title,
    required this.why,
    this.stepId,
    this.opensEar = false,
  });

  final int minutes;
  final String title;
  final String why;

  /// Açılacak gitar yolu adımı (`null` = açılacak uygun adım yok).
  final String? stepId;

  /// true: kulak eğitimi ana ekranı açılır.
  final bool opensEar;
}

/// JustinGuitar'ın 20 dakikalık ve Yousician'ın kısa günlük oturum önerilerine
/// dayanan, 15 dakikaya sığdırılmış rutin: ısınma 2 · akor değişimi 4 · vuruş 4 ·
/// şarkı/döngü 4 · kulak 1. Adımlar yıldızlara göre seçilir: önce henüz 3 yıldız
/// alınmamış, ama gerekli akorları öğrenilmiş en kolay adım.
abstract final class GuitarRoutine {
  static List<RoutineBlock> plan(Map<String, int> stars) {
    bool played(String chordId) => GuitarPath.allSteps.any((s) =>
        s.kind == GuitarStepKind.chordPlay &&
        s.chordIds.first == chordId &&
        (stars[s.id] ?? 0) >= 1);

    // Bu adımdaki akorlar çalınarak öğrenilmiş mi? (Sus/7'li gibi tek başına
    // chordPlay'i olmayan akorlar için de adımın kendisi yeterlidir.)
    bool ready(GuitarStep s) => s.chordIds.every(played);

    String? pick(GuitarStepKind kind) {
      final candidates = GuitarPath.allSteps.where((s) => s.kind == kind && ready(s)).toList();
      for (final s in candidates) {
        if ((stars[s.id] ?? 0) < 3) return s.id;
      }
      return candidates.isEmpty ? null : candidates.first.id;
    }

    return [
      const RoutineBlock(
        minutes: 2,
        title: 'Isınma: açık teller',
        why: 'Parmakları ısıt, gitarın akortlu olduğundan emin ol.',
        stepId: 'l0b.open',
      ),
      RoutineBlock(
        minutes: 4,
        title: 'Akor değişimi',
        why: 'Bir dakikada değişim sayını artırmak en hızlı ilerleme yoludur.',
        stepId: pick(GuitarStepKind.changes),
      ),
      RoutineBlock(
        minutes: 4,
        title: 'Vuruş kalıbı',
        why: 'Sağ elin ritmi; metronomla çalıştıkça şarkılar akar.',
        stepId: pick(GuitarStepKind.strum),
      ),
      RoutineBlock(
        minutes: 4,
        title: 'Akor döngüsü',
        why: 'Akor değişimi + ritim bir arada: gerçek şarkıya en yakın egzersiz.',
        stepId: pick(GuitarStepKind.progression),
      ),
      const RoutineBlock(
        minutes: 1,
        title: 'Kulak eğitimi',
        why: 'Bir dakika bile olsa her gün: kulak, çalmayı besler.',
        opensEar: true,
      ),
    ];
  }

  static int totalMinutes(List<RoutineBlock> plan) => plan.fold(0, (s, b) => s + b.minutes);
}

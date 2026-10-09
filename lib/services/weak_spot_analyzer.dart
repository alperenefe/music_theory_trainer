import '../audio/ear_audio_types.dart';
import '../models/ear_session_result.dart';

typedef WeakSpot = ({
  String subtype,
  int errorCount,
  int attemptCount,
  double errorRate,
  String label,
});

typedef SubtypeAccuracy = ({
  String subtype,
  String label,
  int attempts,
  int correct,
  double accuracy,
});

final class WeakSpotAnalyzer {
  const WeakSpotAnalyzer();

  /// Bir alt türün "zayıf" sayılabilmesi için gereken minimum deneme sayısı.
  /// Bunun altındaki örneklemler hata ORANI yerine ham sayıyla sıralanır;
  /// aksi hâlde 1-2 denemede 1 hata yapan yeni bir konu %100 oranla en
  /// tepeye sıçrar.
  static const int minSampleForRate = 5;

  /// [sessions] en yeniden eskiye sıralıdır (kayıt sırası: `[yeni, ...eski]`).
  /// Yalnızca son [lastN] seansın hataları toplanır.
  Map<String, int> aggregateErrors(
    List<EarSessionResult> sessions, {
    int lastN = 15,
  }) {
    final recent = sessions.take(lastN);

    final result = <String, int>{};
    for (final s in recent) {
      for (final e in s.errorsBySubtype.entries) {
        if (e.value <= 0) continue;
        result[e.key] = (result[e.key] ?? 0) + e.value;
      }
    }
    return result;
  }

  /// Alt tür başına toplam deneme sayısı (doğru+yanlış), aynı pencereyle.
  Map<String, int> aggregateAttempts(
    List<EarSessionResult> sessions, {
    int lastN = 15,
  }) {
    final recent = sessions.take(lastN);

    final result = <String, int>{};
    for (final s in recent) {
      for (final e in s.attemptsBySubtype.entries) {
        if (e.value <= 0) continue;
        result[e.key] = (result[e.key] ?? 0) + e.value;
      }
    }
    return result;
  }

  /// En zayıf [n] alt türü döner. Yeterli örneklemi olan (>= [minSampleForRate]
  /// deneme) konular hata ORANINA göre sıralanır — az denenmiş ama çok
  /// tekrarlanan bir konunun, oranı çok daha kötü olan yeni bir konuyu
  /// sırf ham hata sayısı yüksek diye gölgelemesini engeller. Deneme sayısı
  /// bilinmeyen (eski/geriye dönük) kayıtlar ham sayıya göre sıralanmaya
  /// devam eder.
  List<WeakSpot> topWeakSpots(
    List<EarSessionResult> sessions, {
    int n = 3,
  }) {
    final errors = aggregateErrors(sessions);
    if (errors.isEmpty) return const [];
    final attempts = aggregateAttempts(sessions);

    final list = errors.entries.map((e) {
      final attemptCount = attempts[e.key] ?? 0;
      final rate = attemptCount > 0 ? e.value / attemptCount : 0.0;
      return (
        subtype: e.key,
        errorCount: e.value,
        attemptCount: attemptCount,
        errorRate: rate,
        label: subtypeLabel(e.key),
      );
    }).toList();

    list.sort((a, b) {
      final aReliable = a.attemptCount >= minSampleForRate;
      final bReliable = b.attemptCount >= minSampleForRate;
      if (aReliable && bReliable) {
        final byRate = b.errorRate.compareTo(a.errorRate);
        return byRate != 0 ? byRate : b.errorCount.compareTo(a.errorCount);
      }
      if (aReliable != bReliable) return aReliable ? -1 : 1;
      return b.errorCount.compareTo(a.errorCount);
    });
    return list.take(n).toList();
  }

  /// Konu bazında doğru oranı (en düşükten en yükseğe). Deneme sayısı
  /// kaydedilmemiş eski seanslar ve [minAttempts]'ten az denenmiş konular
  /// hariç tutulur — 1-2 denemelik bir yüzde yanıltıcı olur.
  List<SubtypeAccuracy> subtypeAccuracy(
    List<EarSessionResult> sessions, {
    int lastN = 15,
    int minAttempts = 3,
  }) {
    final attempts = aggregateAttempts(sessions, lastN: lastN);
    final errors = aggregateErrors(sessions, lastN: lastN);
    final out = <SubtypeAccuracy>[];
    for (final e in attempts.entries) {
      if (e.value < minAttempts) continue;
      final wrong = (errors[e.key] ?? 0).clamp(0, e.value);
      out.add((
        subtype: e.key,
        label: subtypeLabel(e.key),
        attempts: e.value,
        correct: e.value - wrong,
        accuracy: (e.value - wrong) / e.value,
      ));
    }
    out.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return out;
  }

  static const _degreeNames = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'];

  static String subtypeLabel(String subtype) {
    final interval = EarIntervalType.fromSrsKey(subtype);
    if (interval != null) return interval.label;
    final chord = EarChordQuality.fromSrsKey(subtype);
    if (chord != null) return '${chord.label} akor';
    final cadence = EarCadenceType.fromSrsKey(subtype);
    if (cadence != null) return cadence.label;
    if (subtype.startsWith('degree_')) {
      final d = int.tryParse(subtype.substring(7));
      if (d != null && d >= 1 && d <= 7) return '$d. Derece (${_degreeNames[d - 1]})';
    }
    return switch (subtype) {
      'downbeat_bass' => '1. Vuruş (Downbeat) Bası',
      'inversion_slash' => '1. İnversiyon (bas 3\'lü, C/E)',
      'inversion_second' => '2. İnversiyon (bas 5\'li, C/G)',
      'inversion_root' => 'Kök Pozisyon Akor',
      'rhythm_2_beats' => 'Harmonik Ritim (2 Vuruşta Bir)',
      'rhythm_4_beats' => 'Harmonik Ritim (4 Vuruşta Bir)',
      'rhythm_8_beats' => 'Harmonik Ritim (8 Vuruşta Bir)',
      _ => subtype.replaceAll('_', ' '),
    };
  }
}

import '../audio/ear_sound.dart';
import 'ear_exercise_kind.dart';

/// Cevap seçeneklerinin nasıl gösterileceği.
enum EarAnswerLayout {
  /// Başlık + alt başlıklı kart listesi / ızgara.
  choices,

  /// Gitar klavyesi (tel × perde) üzerinde dokunma.
  fretboard,
}

final class EarAnswerOption {
  const EarAnswerOption({
    required this.id,
    required this.title,
    this.subtitle,
    this.sound,
    this.stringNumber,
    this.fret,
  });

  final String id;
  final String title;
  final String? subtitle;

  /// Cevaptan sonra karşılaştırmalı dinleme için bu seçeneğin sesi.
  final EarSound? sound;

  /// [EarAnswerLayout.fretboard] için tel (6 = kalın Mi) ve perde.
  final int? stringNumber;
  final int? fret;
}

/// Tek bir kulak eğitimi sorusu. Tamamen veri: UI ve ses motoru bunu yorumlar.
final class EarQuestion {
  const EarQuestion({
    required this.kind,
    required this.subtypeKey,
    required this.prompt,
    required this.hint,
    required this.sound,
    required this.options,
    required this.correctIds,
    required this.correctLabel,
    this.layout = EarAnswerLayout.choices,
    this.altSound,
    this.altSoundLabel,
    this.altSoundAfterAnswer = false,
    this.explanation,
  });

  final EarExerciseKind kind;

  /// Hata/SRS anahtarı (ör. `interval_minor3`).
  final String subtypeKey;
  final String prompt;
  final String hint;
  final EarSound sound;
  final List<EarAnswerOption> options;
  final Set<String> correctIds;

  /// Geri bildirimde gösterilecek doğru cevap metni.
  final String correctLabel;
  final EarAnswerLayout layout;

  /// İkincil dinleme (ör. aralığı birlikte çal, akoru arpej çal).
  final EarSound? altSound;
  final String? altSoundLabel;

  /// true: ikincil ses cevabı ele vereceği için yalnızca cevaptan sonra sunulur.
  final bool altSoundAfterAnswer;

  /// Cevaptan sonra gösterilen kısa teori notu.
  final String? explanation;

  bool isCorrect(String optionId) => correctIds.contains(optionId);

  EarAnswerOption? optionById(String id) {
    for (final o in options) {
      if (o.id == id) return o;
    }
    return null;
  }
}

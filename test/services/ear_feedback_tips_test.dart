import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/audio/ear_audio_types.dart';
import 'package:music_theory_trainer/models/ear_exercise_kind.dart';
import 'package:music_theory_trainer/services/ear_feedback_tips.dart';
import 'package:music_theory_trainer/services/ear_question_factory.dart';

void main() {
  final f = EarQuestionFactory(random: Random(3));

  test('no contrast tip for a correct answer', () {
    final q = f.interval(weekNumber: 1, target: EarIntervalType.major3);
    expect(EarFeedbackTips.contrast(q, q.subtypeKey), isNull);
  });

  test('minor vs major third explains the semitone gap and how to tell them apart', () {
    final q = f.interval(weekNumber: 1, target: EarIntervalType.major3);
    final tip = EarFeedbackTips.contrast(q, EarIntervalType.minor3.srsKey)!;
    expect(tip, contains('3 yarım ses'));
    expect(tip, contains('4 yarım ses'));
    expect(tip, contains('Nasıl ayırırsın'));
  });

  test('every wrong pick in every kind produces a tip', () {
    for (final kind in EarExerciseKind.values) {
      if (kind == EarExerciseKind.interleaved) continue;
      for (var i = 0; i < 10; i++) {
        final q = f.build(kind, weekNumber: 12);
        for (final o in q.options) {
          if (q.isCorrect(o.id)) continue;
          expect(EarFeedbackTips.contrast(q, o.id), isNotNull, reason: '${kind.name} ${o.id}');
        }
      }
    }
  });

  test('bass hunter: same note in a different octave is called out', () {
    const target = BassTarget('Mi Majör (E)', EarChordQuality.major, 52, 'Mi (E)');
    final q = f.bassHunter(target: target);
    // 6. tel boş = Mi (E2), doğru ses E3: bir oktav fark.
    final tip = EarFeedbackTips.contrast(q, 's6f0')!;
    expect(tip, contains('oktav'));
  });
}

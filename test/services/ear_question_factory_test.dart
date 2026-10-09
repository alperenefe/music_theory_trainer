import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/audio/ear_audio_types.dart';
import 'package:music_theory_trainer/audio/ear_sound.dart';
import 'package:music_theory_trainer/models/ear_curriculum.dart';
import 'package:music_theory_trainer/models/ear_exercise_kind.dart';
import 'package:music_theory_trainer/models/ear_question.dart';
import 'package:music_theory_trainer/services/ear_question_factory.dart';

void main() {
  group('EarQuestionFactory', () {
    test('every question has its correct answer among the options', () {
      final f = EarQuestionFactory(random: Random(1));
      for (final kind in EarExerciseKind.values) {
        for (var i = 0; i < 20; i++) {
          final q = f.build(kind, weekNumber: 12);
          expect(q.correctIds, isNotEmpty, reason: kind.name);
          for (final id in q.correctIds) {
            expect(q.optionById(id), isNotNull, reason: '${kind.name} $id');
          }
        }
      }
    });

    test('interval pool grows with the curriculum (P4 from week 3)', () {
      final f = EarQuestionFactory(random: Random(2));
      final early = f.interval(weekNumber: 1);
      final later = f.interval(weekNumber: 3);
      expect(early.optionById(EarIntervalType.perfect4.srsKey), isNull);
      expect(later.optionById(EarIntervalType.perfect4.srsKey), isNotNull);
    });

    test('seconds join the interval pool from week 4', () {
      final f = EarQuestionFactory(random: Random(14));
      expect(f.interval(weekNumber: 3).optionById(EarIntervalType.minor2.srsKey), isNull);
      final q = f.interval(weekNumber: 4);
      expect(q.optionById(EarIntervalType.minor2.srsKey), isNotNull);
      expect(q.optionById(EarIntervalType.major2.srsKey), isNotNull);
      expect(q.options, hasLength(7));
      expect(earWeekByNumber(4).exercises, contains(EarExerciseKind.intervalBlind));
    });

    test('7th chords appear only from week 11', () {
      final f = EarQuestionFactory(random: Random(3));
      expect(f.chordQuality(weekNumber: 4).optionById('chord_dominant7'), isNull);
      expect(f.chordQuality(weekNumber: 11).optionById('chord_dominant7'), isNotNull);
    });

    test('does not ask the same target twice in a row', () {
      final f = EarQuestionFactory(random: Random(4));
      String? last;
      for (var i = 0; i < 40; i++) {
        final q = f.interval(weekNumber: 1);
        expect(q.subtypeKey, isNot(last));
        last = q.subtypeKey;
      }
    });

    test('deceptive and plagal cadences are playable and answerable', () {
      final f = EarQuestionFactory(random: Random(11));
      for (final target in [EarCadenceType.V_vi, EarCadenceType.IV_I]) {
        final q = f.cadence(target: target);
        expect(q.correctIds, {target.srsKey});
        expect(q.optionById(target.srsKey), isNotNull);
        expect(target.chords, hasLength(2));
      }
    });

    test('interleaved session really mixes kinds, balanced', () {
      final f = EarQuestionFactory(random: Random(5));
      final questions = f.session(
        kinds: const [EarExerciseKind.interleaved],
        count: 20,
        weekNumber: 10,
      );
      final counts = <EarExerciseKind, int>{};
      for (final q in questions) {
        counts[q.kind] = (counts[q.kind] ?? 0) + 1;
      }
      final expected = earKindsIntroducedBy(10);
      expect(expected.length, greaterThanOrEqualTo(3));
      expect(counts.keys.toSet(), expected.toSet());
      for (final k in expected) {
        expect(counts[k], inInclusiveRange(20 ~/ expected.length, (20 ~/ expected.length) + 1));
      }
    });

    test('week 5 consolidation mixes introduced kinds', () {
      expect(
        earKindsIntroducedBy(5),
        containsAll([EarExerciseKind.intervalBlind, EarExerciseKind.chordQuality]),
      );
    });

    test('review session targets only the given subtypes', () {
      final f = EarQuestionFactory(random: Random(6));
      final keys = ['chord_minor7', 'cadence_V7_i', 'downbeat_bass', 'unknown_key'];
      final questions = f.session(
        kinds: const [EarExerciseKind.intervalBlind],
        count: 9,
        weekNumber: 1,
        subtypes: keys,
      );
      expect(questions, hasLength(9));
      for (final q in questions) {
        expect(keys.take(3), contains(q.subtypeKey));
      }
    });

    test('bass hunter accepts every position with the same pitch', () {
      final f = EarQuestionFactory(random: Random(7));
      const target = BassTarget('Mi Majör (E)', EarChordQuality.major, 52, 'Mi (E)');
      final q = f.bassHunter(target: target);
      expect(q.layout, EarAnswerLayout.fretboard);
      // 5. tel 7. perde ve 6. tel 12. perde aynı Mi (E3).
      expect(q.correctIds, {'s5f7', 's6f12'});
      for (final id in q.correctIds) {
        final s = q.optionById(id)!.sound;
        expect(s, isA<NoteSound>());
        expect((s! as NoteSound).midi, 52);
      }
    });

    test('forSubtype returns null for unknown keys', () {
      final f = EarQuestionFactory(random: Random(8));
      expect(f.forSubtype('nope', weekNumber: 1), isNull);
      expect(EarQuestionFactory.isKnownSubtype('interval_perfect4'), isTrue);
      expect(EarQuestionFactory.isKnownSubtype('rhythm_2_beats'), isTrue);
      expect(EarQuestionFactory.isKnownSubtype('inversion_slash'), isTrue);
    });

    test('harmonic rhythm offers 2/4/8 beats with equal total length', () {
      final f = EarQuestionFactory(random: Random(9));
      for (final beats in EarQuestionFactory.rhythmBeatsPool) {
        final q = f.harmonicRhythm(targetBeats: beats);
        expect(q.kind, EarExerciseKind.harmonicRhythm);
        expect(q.subtypeKey, 'rhythm_${beats}_beats');
        final s = q.sound as HarmonicRhythmSound;
        expect(s.beatsPerChord, beats);
        expect(q.options.length, 3);
        // Süre ipucu yok: her seçenek toplam 16 vuruş.
        for (final o in q.options) {
          final os = o.sound! as HarmonicRhythmSound;
          expect(os.chords.length * os.beatsPerChord, 16);
          expect(os.bpm, s.bpm);
        }
      }
    });

    test('harmonic rhythm varies tempo and key across questions', () {
      final f = EarQuestionFactory(random: Random(21));
      final tempos = <int>{};
      final firstBass = <int>{};
      for (var i = 0; i < 20; i++) {
        final s = f.harmonicRhythm(targetBeats: 4).sound as HarmonicRhythmSound;
        tempos.add(s.bpm);
        firstBass.add(s.chords.first.first);
      }
      expect(tempos.length, greaterThan(3));
      expect(firstBass.length, greaterThan(2));
    });

    test('inversion detect: three options share the same upper chord', () {
      final f = EarQuestionFactory(random: Random(10));
      for (var inv = 0; inv < 3; inv++) {
        final q = f.inversionDetect(targetInversion: inv);
        expect(q.kind, EarExerciseKind.inversionDetect);
        expect(q.subtypeKey, EarQuestionFactory.inversionKeys[inv]);
        expect(q.sound, isA<SlashChordSound>());
        expect(q.options.length, 3);
        final uppers = {
          for (final o in q.options) (o.sound! as SlashChordSound).upperMidis.join(','),
        };
        expect(uppers, hasLength(1));
        final basses = {for (final o in q.options) (o.sound! as SlashChordSound).bassMidi};
        expect(basses, hasLength(3));
      }
    });

    test('scale degree: context then target, resolution only after answer', () {
      final f = EarQuestionFactory(random: Random(12));
      for (final d in [1, 3, 4, 5, 7]) {
        final q = f.scaleDegree(weekNumber: 3, target: d);
        expect(q.kind, EarExerciseKind.scaleDegree);
        expect(q.subtypeKey, 'degree_$d');
        expect(q.options.map((o) => o.id), [
          for (final x in EarQuestionFactory.degreePool(3)) 'degree_$x',
        ]);
        final s = q.sound as ScaleSound;
        final tonic = s.notes.first;
        const offsets = [0, 2, 4, 5, 7, 9, 11];
        expect(s.notes.last, tonic + offsets[d - 1]);
        expect(q.altSoundAfterAnswer, isTrue);
        final resolution = q.altSound! as ScaleSound;
        expect(resolution.notes.last % 12, tonic % 12, reason: 'eve çözülür');
      }
    });

    test('scale degree pool grows from week 6', () {
      expect(EarQuestionFactory.degreePool(3), [1, 3, 4, 5, 7]);
      expect(EarQuestionFactory.degreePool(6), [1, 2, 3, 4, 5, 6, 7]);
      expect(EarQuestionFactory.isKnownSubtype('degree_4'), isTrue);
      expect(EarQuestionFactory.isKnownSubtype('degree_9'), isFalse);
      expect(EarQuestionFactory.isKnownSubtype('inversion_second'), isTrue);
      expect(EarQuestionFactory.isKnownSubtype('rhythm_8_beats'), isTrue);
    });

    test('week 1 intervals are ascending; descending appears from week 2', () {
      final f = EarQuestionFactory(random: Random(13));
      for (var i = 0; i < 40; i++) {
        final s = f.interval(weekNumber: 1).sound as IntervalSound;
        expect(s.descending, isFalse);
      }
      var down = 0;
      for (var i = 0; i < 60; i++) {
        final q = f.interval(weekNumber: 3);
        final s = q.sound as IntervalSound;
        if (s.descending) {
          down++;
          expect(q.prompt, contains('↓'));
          for (final o in q.options) {
            expect((o.sound! as IntervalSound).descending, isTrue);
          }
        }
      }
      expect(down, inInclusiveRange(8, 40));
    });
  });
}

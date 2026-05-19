import 'dart:math';

import 'music_interval.dart';
import 'theory_note_labels.dart';

final class IntervalQuestion {
  const IntervalQuestion({
    required this.rootMidi,
    required this.kind,
    required this.up,
    required this.answerMidi,
    required this.options,
    required this.correctLabel,
  });

  final int rootMidi;
  final IntervalKind kind;
  final bool up;
  final int answerMidi;
  final List<String> options;
  final String correctLabel;

  String get prompt => MusicInterval.buildQuestionText(
        rootMidi: rootMidi,
        kind: kind,
        up: up,
      );

  static IntervalQuestion random(Random rnd, int minMidi, int maxMidi) {
    const maxTries = 64;
    for (var t = 0; t < maxTries; t++) {
      final kind = MusicInterval.practiceSet[
          rnd.nextInt(MusicInterval.practiceSet.length)];
      final up = rnd.nextBool();
      final root = minMidi + rnd.nextInt(max(1, maxMidi - minMidi + 1));
      final answer = MusicInterval.apply(root, kind, up: up);
      if (answer < minMidi || answer > maxMidi) {
        continue;
      }
      final correctLabel =
          TheoryNoteLabels.label(answer, withOctave: false);
      final wrongMidis = <int>{};
      var guard = 0;
      while (wrongMidis.length < 3 && guard < 40) {
        guard++;
        final altKind = MusicInterval.practiceSet[
            rnd.nextInt(MusicInterval.practiceSet.length)];
        final altUp = rnd.nextBool();
        var w = MusicInterval.apply(root, altKind, up: altUp);
        if (w < minMidi || w > maxMidi) {
          continue;
        }
        if (w != answer) {
          wrongMidis.add(w);
        }
      }
      if (wrongMidis.length < 3) {
        continue;
      }
      final labels = TheoryNoteLabels.optionLabels(
        [answer, ...wrongMidis]..shuffle(rnd),
        withOctave: false,
      );
      return IntervalQuestion(
        rootMidi: root,
        kind: kind,
        up: up,
        answerMidi: answer,
        options: labels,
        correctLabel: correctLabel,
      );
    }
    // Dar aralıkta yine de soru üret (tek oktav içinde sabit kök).
    final root = minMidi;
    const kind = IntervalKind.majorThird;
    final answer = MusicInterval.apply(root, kind, up: true);
    final clamped = answer.clamp(minMidi, maxMidi);
    final wrong = <int>{
      MusicInterval.apply(root, IntervalKind.perfectFifth, up: true),
      MusicInterval.apply(root, IntervalKind.majorSecond, up: true),
      MusicInterval.apply(root, IntervalKind.perfectFourth, up: false),
    }..remove(clamped);
    final labels = TheoryNoteLabels.optionLabels(
      [clamped, ...wrong.take(3)],
      withOctave: false,
    );
    return IntervalQuestion(
      rootMidi: root,
      kind: kind,
      up: true,
      answerMidi: clamped,
      options: labels,
      correctLabel: TheoryNoteLabels.label(clamped, withOctave: false),
    );
  }
}

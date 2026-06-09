import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/theory/interval_question.dart';
import 'package:music_theory_trainer/theory/music_interval.dart';

void main() {
  test('allowedKinds yalnızca seçili aralıkları üretir', () {
    const allowed = [IntervalKind.majorThird];
    for (var i = 0; i < 15; i++) {
      final q = IntervalQuestion.random(
        Random(i),
        60,
        72,
        allowedKinds: allowed,
      );
      expect(q.kind, IntervalKind.majorThird);
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/custom_workout.dart';
import 'package:music_theory_trainer/theory/music_interval.dart';

void main() {
  test('json roundtrip', () {
    const w = CustomWorkout(
      exerciseKind: 'interval',
      minMidi: 55,
      maxMidi: 70,
      intervalKinds: ['majorThird', 'perfectFifth'],
    );
    final decoded = CustomWorkout.fromJson(w.toJson());
    expect(decoded.exerciseKind, 'interval');
    expect(decoded.resolvedIntervalKinds(), [
      IntervalKind.majorThird,
      IntervalKind.perfectFifth,
    ]);
  });
}

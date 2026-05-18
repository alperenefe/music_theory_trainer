import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/utils/microphone_pitch_smoother.dart';

void main() {
  test('PitchReadingSmoother outlier tek karede yutar', () {
    final s = PitchReadingSmoother(
      alpha: 1,
      maxJumpCents: 200,
      invalidStreakToReset: 99,
    );
    expect(s.push(110), closeTo(110, 0.01));
    final afterSpike = s.push(400);
    expect(afterSpike, closeTo(110, 1));
  });

  test('PitchStringLock yeni tel için yeterli tekrar ister', () {
    final l = PitchStringLock(framesToSwitch: 3);
    expect(l.push(4), 4);
    expect(l.push(4), 4);
    expect(l.push(2), 4);
    expect(l.push(2), 4);
    expect(l.push(2), 2);
  });
}

import 'package:flutter_detect_pitch/pitch_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromEvent map', () {
    final f = PitchFrame.fromEvent({'hz': 82.4, 'rms': 0.15});
    expect(f.hz, closeTo(82.4, 0.001));
    expect(f.rms, 0.15);
  });

  test('fromEvent num legacy', () {
    final f = PitchFrame.fromEvent(110.0);
    expect(f.hz, 110);
    expect(f.rms, 1.0);
  });
}

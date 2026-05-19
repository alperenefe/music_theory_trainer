import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/utils/guitar_target_pitch_match.dart';

void main() {
  test('Mi2 (82 Hz) hedef MIDI 40 — Sol değil Mi', () {
    const ref = 440.0;
    final m = GuitarTargetPitchMatch.matchMidi(
      hz: 82,
      targetMidi: 40,
      referenceA4: ref,
    );
    expect(m, 40);
    expect(m! % 12, 4);
  });

  test('harmonik 164 Hz hedef MIDI 40 — hedef oktava (Mi2)', () {
    final m = GuitarTargetPitchMatch.matchMidi(
      hz: 164,
      targetMidi: 40,
      referenceA4: 440,
    );
    expect(m, 40);
  });

  test('yanlış 98 Hz (Sol2) hedef Mi için eşleşmez veya geniş toleransta bile Mi', () {
    final m = GuitarTargetPitchMatch.matchMidi(
      hz: 98,
      targetMidi: 40,
      referenceA4: 440,
      maxCents: 50,
    );
    expect(m, isNull);
  });

  test('foldToFundamental 98 Hz harmonikten 82 ye iner', () {
    final folded = GuitarTargetPitchMatch.foldToFundamental(
      hz: 164,
      targetMidi: 40,
      referenceA4: 440,
    );
    expect(folded, closeTo(82, 1));
  });
}

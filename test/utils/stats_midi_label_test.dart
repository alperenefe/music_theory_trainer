import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/utils/stats_midi_label.dart';

void main() {
  test('gitar stili diyez adı kullanır', () {
    expect(
      StatsMidiLabel.forMidi(42, guitarStyle: true),
      'Fa diyez (2. oktav)',
    );
  });

  test('porte stili doğal ad', () {
    expect(
      StatsMidiLabel.forMidi(64, guitarStyle: false),
      'Mi (4. oktav)',
    );
  });

  test('diyez notalar anlamlı ad', () {
    expect(
      StatsMidiLabel.forMidi(42, guitarStyle: false),
      'Fa diyez (2. oktav)',
    );
  });
}

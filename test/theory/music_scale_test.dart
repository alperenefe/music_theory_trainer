import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/theory/music_scale.dart';
import 'package:music_theory_trainer/theory/theory_note_labels.dart';

void main() {
  test('Fa majör bemol yazımı', () {
    final labels = MusicScale.spelledLabels(65, ScaleMode.major);
    expect(labels, [
      'Fa',
      'Sol',
      'La',
      'Si bemol',
      'Do',
      'Re',
      'Mi',
    ]);
  });

  test('La doğal minör', () {
    final labels = MusicScale.spelledLabels(69, ScaleMode.naturalMinor);
    expect(labels, [
      'La',
      'Si',
      'Do',
      'Re',
      'Mi',
      'Fa',
      'Sol',
    ]);
  });

  test('spelledDegrees MIDI ile uyumlu (7 derece)', () {
    final deg = MusicScale.spelledDegrees(67, ScaleMode.major);
    expect(deg.length, 7);
    expect(deg.first.label, 'Sol');
    expect(deg.last.label, 'Fa diyez');
    expect(deg.first.midi, 67);
  });

  test('pentatonik majör 5 derece', () {
    final deg = MusicScale.spelledDegrees(60, ScaleMode.pentatonicMajor);
    expect(deg.length, 5);
    expect(deg.map((d) => d.label).toList(), [
      'Do',
      'Re',
      'Mi',
      'Sol',
      'La',
    ]);
  });

  test('palet tüm diyez bemol adlarını içerir', () {
    expect(TheoryNoteLabels.chromaticPalette, contains('Si bemol'));
    expect(TheoryNoteLabels.chromaticPalette, contains('Fa diyez'));
    expect(TheoryNoteLabels.pitchClassForLabel('Re bemol'), 1);
    expect(TheoryNoteLabels.pitchClassForLabel('Do diyez'), 1);
  });
}

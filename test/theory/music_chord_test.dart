import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/theory/music_chord.dart';

void main() {
  test('chordNotes majör ve minör', () {
    expect(MusicChord.chordNotes(60, ChordQuality.major), [60, 64, 67]);
    expect(MusicChord.chordNotes(60, ChordQuality.minor), [60, 63, 67]);
  });

  test('chordNotes dim aug dom7', () {
    expect(MusicChord.chordNotes(60, ChordQuality.diminished), [60, 63, 66]);
    expect(MusicChord.chordNotes(60, ChordQuality.augmented), [60, 64, 68]);
    expect(
      MusicChord.chordNotes(60, ChordQuality.dominant7),
      [60, 64, 67, 70],
    );
  });

  test('chordSymbol', () {
    expect(MusicChord.chordSymbol(60, ChordQuality.major), 'Do');
    expect(MusicChord.chordSymbol(60, ChordQuality.minor), 'Dom');
    expect(MusicChord.chordSymbol(60, ChordQuality.diminished), 'Dodim');
    expect(MusicChord.chordSymbol(60, ChordQuality.augmented), 'Doaug');
    expect(MusicChord.chordSymbol(60, ChordQuality.dominant7), 'Do7');
  });

  test('practiceSet beş kalite', () {
    expect(MusicChord.practiceSet, hasLength(5));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/utils/guitar_note_pool.dart';

void main() {
  group('GuitarNotePool', () {
    test('forMidiRange süzgeç', () {
      final notes = GuitarNotePool.forMidiRange(minMidi: 60, maxMidi: 72);
      expect(notes, isNotEmpty);
      for (final n in notes) {
        expect(n.midi, greaterThanOrEqualTo(60));
        expect(n.midi, lessThanOrEqualTo(72));
      }
    });

    test('uniqueNoteNames sıralı benzersiz', () {
      final notes = GuitarNotePool.forMidiRange(minMidi: 40, maxMidi: 84);
      final names = GuitarNotePool.uniqueNoteNames(notes);
      expect(names.toSet().length, names.length);
      expect(names, equals(names.toList()..sort()));
    });

    test('dar aralık MCQ havuzu küçültür', () {
      final wide = GuitarNotePool.forMidiRange(minMidi: 40, maxMidi: 84);
      final narrow = GuitarNotePool.forMidiRange(minMidi: 64, maxMidi: 71);
      expect(narrow.length, lessThan(wide.length));
    });
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/guitar_note.dart';
import 'package:music_theory_trainer/theory/theory_note_labels.dart';

void main() {
  group('GuitarNote', () {
    test('standart akort MIDI doğruluğu', () {
      expect(GuitarNote(string: 0, fret: 0).midi, 64);
      expect(GuitarNote(string: 1, fret: 0).midi, 59);
      expect(GuitarNote(string: 2, fret: 0).midi, 55);
      expect(GuitarNote(string: 3, fret: 0).midi, 50);
      expect(GuitarNote(string: 4, fret: 0).midi, 45);
      expect(GuitarNote(string: 5, fret: 0).midi, 40);
    });

    test('perde ekleme doğru çalışır', () {
      expect(GuitarNote(string: 5, fret: 5).midi, 45);
      expect(GuitarNote(string: 0, fret: 7).midi, 71);
    });

    test('nota adı kromatik doğru', () {
      expect(GuitarNote(string: 5, fret: 0).noteName, 'Mi');
      expect(GuitarNote(string: 4, fret: 0).noteName, 'La');
      expect(GuitarNote(string: 5, fret: 1).noteName, 'Fa');
      expect(GuitarNote(string: 5, fret: 2).noteName, 'Fa diyez');
    });

    test('Sol teli 2. perde La (Fa diyez değil)', () {
      final g2 = GuitarNote(string: 2, fret: 2);
      expect(g2.midi, 57);
      expect(g2.noteName, 'La');
      expect(g2.noteName, isNot('Fa diyez'));
      expect(g2.positionLabel, 'Sol teli · 2. perde');
    });

    test('tüm perdeler TheoryNoteLabels ile uyumlu', () {
      for (final n in GuitarNote.allNotes()) {
        expect(
          n.noteName,
          TheoryNoteLabels.label(n.midi, withOctave: false),
        );
      }
    });

    test('allNotes 0-7 arası 48 nota döner', () {
      expect(GuitarNote.allNotes().length, 48);
    });

    test('notesWithMidi La pozisyonunu bulur', () {
      final la = GuitarNote.notesWithMidi(45);
      expect(la.any((n) => n.string == 4 && n.fret == 0), isTrue);
    });

    test('mcqOptions her zaman 4 şık içerir ve hedefi kapsar', () {
      final all = GuitarNote.allNotes();
      final opts = GuitarNote.mcqOptions('Do', all, Random(1));
      expect(opts.length, 4);
      expect(opts.contains('Do'), isTrue);
    });

    test('frekans A4 için 440 Hz', () {
      final a4 = GuitarNote(string: 0, fret: 5); // MIDI 69
      expect(a4.midi, 69);
      expect(a4.frequency.round(), 440);
    });
  });
}

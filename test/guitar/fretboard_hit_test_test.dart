import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/guitar/fretboard_painter.dart';
import 'package:music_theory_trainer/guitar/fretboard_widget.dart';
import 'package:music_theory_trainer/models/guitar_note.dart';

void main() {
  group('FretboardWidget.hitTestAt', () {
    const size = Size(360, 200);

    test('Sol teli 2. perde merkezine dokunma', () {
      const note = GuitarNote(string: 2, fret: 2);
      final center = FretboardWidget.cellCenterFor(note, size);
      final hit = FretboardWidget.hitTestAt(center, size);
      expect(hit, note);
      expect(hit!.noteName, 'La');
    });

    test('painter merkezi ile hit test aynı hücre', () {
      final painter = FretboardPainter(cellStates: const {});
      for (var s = 0; s < 6; s++) {
        for (var f = 0; f <= 7; f++) {
          final note = GuitarNote(string: s, fret: f);
          final center = painter.cellCenter(size, note);
          final hit = FretboardWidget.hitTestAt(center, size);
          expect(hit, note, reason: 's=$s f=$f');
        }
      }
    });
  });
}

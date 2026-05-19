import '../theory/theory_note_labels.dart';

abstract final class StatsMidiLabel {
  static String forMidi(int midi, {required bool guitarStyle}) =>
      TheoryNoteLabels.label(midi, withOctave: true);
}

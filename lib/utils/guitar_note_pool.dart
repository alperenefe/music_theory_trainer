import '../models/guitar_note.dart';

abstract final class GuitarNotePool {
  static List<GuitarNote> forMidiRange({
    int minMidi = 40,
    int maxMidi = 84,
    int minFret = 0,
    int maxFret = 7,
  }) {
    final lo = minMidi < maxMidi ? minMidi : maxMidi;
    final hi = minMidi < maxMidi ? maxMidi : minMidi;
    return GuitarNote.allNotes(minFret: minFret, maxFret: maxFret)
        .where((n) => n.midi >= lo && n.midi <= hi)
        .toList();
  }

  static List<String> uniqueNoteNames(List<GuitarNote> notes) {
    return notes.map((e) => e.noteName).toSet().toList()..sort();
  }
}

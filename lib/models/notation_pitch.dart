import 'dart:math' as math;

import '../theory/theory_note_labels.dart';

final class NotationPitch {
  const NotationPitch({
    required this.midi,
    required this.staffSlot,
    required this.displayTurkish,
  });

  /// Gitarın **duyduğu** perde (MIDI).
  final int midi;

  /// Sol anahtarında **yazılan** konum (gitar: bir oktav yukarı yazılır).
  final int staffSlot;
  final String displayTurkish;

  /// Gitar partisyonu: portede yazılan = duyulan + 12.
  static const int guitarWrittenTransposition = 12;

  static int octaveNumber(int midi) => (midi ~/ 12) - 1;

  /// Slot → yazılan MIDI (sol anahtarı konser pitch).
  static const Map<int, int> _slotWrittenMidi = {
    -14: 40,
    -13: 41,
    -12: 43,
    -11: 45,
    -10: 47,
    -9: 48,
    -8: 50,
    -7: 52,
    -6: 53,
    -5: 55,
    -4: 57,
    -3: 59,
    -2: 60,
    -1: 62,
    0: 64,
    1: 65,
    2: 67,
    3: 69,
    4: 71,
    5: 72,
    6: 74,
    7: 76,
    8: 77,
    9: 79,
    10: 81,
    11: 83,
    12: 84,
  };

  static const Map<int, String> _pitchClassTurkish = {
    0: 'Do',
    2: 'Re',
    4: 'Mi',
    5: 'Fa',
    7: 'Sol',
    9: 'La',
    11: 'Si',
  };

  static bool isNaturalPitchClass(int midi) =>
      _pitchClassTurkish.containsKey(midi % 12);

  static String naturalNameForMidi(int midi) =>
      TheoryNoteLabels.label(midi, withOctave: false);

  static String buildDisplayLabel(int midi) =>
      TheoryNoteLabels.label(midi, withOctave: true);

  static int writtenMidiForSounding(int soundingMidi) =>
      soundingMidi + guitarWrittenTransposition;

  static int? staffSlotForSoundingMidi(int soundingMidi) {
    final written = writtenMidiForSounding(soundingMidi);
    for (final e in _slotWrittenMidi.entries) {
      if (e.value == written) {
        return e.key;
      }
    }
    return null;
  }

  static List<NotationPitch> poolForMidiRange(int minMidi, int maxMidi) {
    final lo = math.min(minMidi, maxMidi);
    final hi = math.max(minMidi, maxMidi);
    return trainingPool().where((e) => e.midi >= lo && e.midi <= hi).toList();
  }

  static List<NotationPitch> trainingPool() {
    final list = <NotationPitch>[];
    final slots = _slotWrittenMidi.keys.toList()..sort();
    for (final slot in slots) {
      final written = _slotWrittenMidi[slot]!;
      final sounding = written - guitarWrittenTransposition;
      if (sounding < 40 || sounding > 84) {
        continue;
      }
      if (!isNaturalPitchClass(sounding)) {
        continue;
      }
      list.add(
        NotationPitch(
          midi: sounding,
          staffSlot: slot,
          displayTurkish: buildDisplayLabel(sounding),
        ),
      );
    }
    list.sort((a, b) => a.midi.compareTo(b.midi));
    return list;
  }

  /// Seçilen porte slotunun gitar **duyulan** MIDI değeri.
  static int? midiAtSlot(int staffSlot) {
    final written = _slotWrittenMidi[staffSlot];
    if (written == null) {
      return null;
    }
    return written - guitarWrittenTransposition;
  }

  static String displayLabelForSlot(int staffSlot) {
    final m = midiAtSlot(staffSlot);
    if (m == null) {
      return '';
    }
    return buildDisplayLabel(m);
  }

  static List<int> allStaffSlots() => _slotWrittenMidi.keys.toList()..sort();

  static String displayForMidi(int midi, List<NotationPitch> pool) {
    for (final p in pool) {
      if (p.midi == midi) {
        return p.displayTurkish;
      }
    }
    return buildDisplayLabel(midi);
  }
}

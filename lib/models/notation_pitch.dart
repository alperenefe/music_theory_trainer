import 'dart:math' as math;

final class NotationPitch {
  const NotationPitch({
    required this.midi,
    required this.staffSlot,
    required this.displayTurkish,
  });

  final int midi;
  final int staffSlot;
  final String displayTurkish;

  static int octaveNumber(int midi) => (midi ~/ 12) - 1;

  static const Map<int, int> _slotNaturalMidi = {
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

  static const List<String> _stepNames = [
    'Do',
    'Re',
    'Mi',
    'Fa',
    'Sol',
    'La',
    'Si',
  ];

  static String _letterForSlot(int staffSlot) {
    final i = staffSlot + 2;
    return _stepNames[i % 7];
  }

  static String _buildLabel(int midi, int staffSlot) {
    final base = _letterForSlot(staffSlot);
    return '$base (${octaveNumber(midi)}. oktav)';
  }

  static List<NotationPitch> poolForMidiRange(int minMidi, int maxMidi) {
    final lo = math.min(minMidi, maxMidi);
    final hi = math.max(minMidi, maxMidi);
    return trainingPool().where((e) => e.midi >= lo && e.midi <= hi).toList();
  }

  static List<NotationPitch> trainingPool() {
    final list = <NotationPitch>[];
    final slots = _slotNaturalMidi.keys.toList()..sort();
    for (final slot in slots) {
      final base = _slotNaturalMidi[slot]!;
      if (base < 40 || base > 84) {
        continue;
      }
      list.add(
        NotationPitch(
          midi: base,
          staffSlot: slot,
          displayTurkish: _buildLabel(base, slot),
        ),
      );
    }
    list.sort((a, b) => a.midi.compareTo(b.midi));
    return list;
  }

  static int? midiAtSlot(int staffSlot) => _slotNaturalMidi[staffSlot];

  static List<NotationPitch>? _shared;

  static List<NotationPitch> sharedPool() {
    return _shared ??= trainingPool();
  }

  static void resetSharedPool() {
    _shared = null;
  }

  static String displayLabelForSlot(int staffSlot) {
    final m = midiAtSlot(staffSlot);
    if (m == null) {
      return '';
    }
    return _buildLabel(m, staffSlot);
  }

  static List<int> allStaffSlots() => _slotNaturalMidi.keys.toList()..sort();

  static String displayForMidi(int midi, List<NotationPitch> pool) {
    for (final p in pool) {
      if (p.midi == midi) {
        return p.displayTurkish;
      }
    }
    return 'MIDI $midi';
  }
}

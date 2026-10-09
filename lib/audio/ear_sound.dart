import 'ear_audio_types.dart';

/// Çalınacak bir kulak eğitimi sesinin veri tanımı.
///
/// Soru üretimi (test edilebilir, saf Dart) ile ses çalma
/// ([GuitarAudioService.playSound]) birbirinden ayrılır.
sealed class EarSound {
  const EarSound();
}

final class NoteSound extends EarSound {
  const NoteSound(this.midi);
  final int midi;
}

final class IntervalSound extends EarSound {
  const IntervalSound({
    required this.rootMidi,
    required this.interval,
    this.harmonic = false,
    this.descending = false,
  });

  final int rootMidi;
  final EarIntervalType interval;

  /// true: iki nota birlikte; false: önce kök sonra üst nota (melodik).
  final bool harmonic;

  /// Melodik çalışta önce üst nota, sonra kök (yukarıdan aşağı).
  final bool descending;

  IntervalSound withHarmonic(bool value) => IntervalSound(
        rootMidi: rootMidi,
        interval: interval,
        harmonic: value,
        descending: descending,
      );
}

final class ChordSound extends EarSound {
  const ChordSound({
    required this.rootMidi,
    required this.quality,
    this.arpeggio = false,
  });

  final int rootMidi;
  final EarChordQuality quality;

  /// true: notalar tek tek (arpej) çalınır — akorun içini duymak için.
  final bool arpeggio;

  List<int> get midis => [for (final s in quality.voicing) rootMidi + s];

  ChordSound withArpeggio(bool value) =>
      ChordSound(rootMidi: rootMidi, quality: quality, arpeggio: value);
}

final class CadenceSound extends EarSound {
  const CadenceSound({required this.rootMidi, required this.cadence});

  final int rootMidi;
  final EarCadenceType cadence;

  List<List<int>> get chordMidis => [
        for (final chord in cadence.chords) [for (final s in chord) rootMidi + s],
      ];
}

/// Bir gam veya melodik nota dizisini sırayla çalan ses.
final class ScaleSound extends EarSound {
  const ScaleSound({
    required this.notes,
    this.stepDurationMs = 360,
  });

  /// Sırayla çalınacak MIDI notaları (ör. [48, 50, 52, 53, 55, 57, 59, 60] - Do Majör).
  final List<int> notes;
  final int stepDurationMs;
}

/// Akorların ritmik değişim hızını (harmonik ritim) dinleten ses.
final class HarmonicRhythmSound extends EarSound {
  const HarmonicRhythmSound({
    required this.chords,
    required this.beatsPerChord,
    this.bpm = 96,
  });

  /// Sırayla çalınacak her akorun MIDI listesi.
  final List<List<int>> chords;

  /// Her akorun kaç vuruş sürdüğü (ör. 2 vuruş veya 4 vuruş).
  final int beatsPerChord;
  final int bpm;
}

/// Bas notası kökten farklı olan slash akor (ör. C/E: bas Mi, üst yapı C).
final class SlashChordSound extends EarSound {
  const SlashChordSound({
    required this.bassMidi,
    required this.upperMidis,
    this.arpeggio = false,
  });

  /// Bas gitarın çaldığı en pes ses (kökten farklı).
  final int bassMidi;

  /// Üst yapı akorunun notaları.
  final List<int> upperMidis;
  final bool arpeggio;

  List<int> get allMidis => [bassMidi, ...upperMidis];

  SlashChordSound withArpeggio(bool value) =>
      SlashChordSound(bassMidi: bassMidi, upperMidis: upperMidis, arpeggio: value);
}

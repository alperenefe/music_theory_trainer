import 'dart:math' as math;

abstract final class PitchFromHz {
  static double octaveNestForGuitar(double hz) {
    if (!hz.isFinite || hz <= 0) {
      return hz;
    }
    var x = hz;
    const minClassify = 70.0;
    const maxClassify = 520.0;
    const floorIn = 22.0;
    while (x < minClassify && x >= floorIn) {
      x *= 2;
    }
    while (x > maxClassify) {
      x *= 0.5;
    }
    return x;
  }

  static int? midiFromHz(double hz, {double referenceA4 = 440}) {
    if (!hz.isFinite || hz <= 0) {
      return null;
    }
    if (hz < 70 || hz > 520) {
      return null;
    }
    final m = 69 + 12 * math.log(hz / referenceA4) / math.ln2;
    return m.round().clamp(0, 127);
  }

  static double hzFromMidi(int midi, double referenceA4) {
    return referenceA4 * math.pow(2.0, (midi - 69) / 12.0);
  }

  static double? centsDelta(double detectedHz, double referenceHz) {
    if (!detectedHz.isFinite || detectedHz <= 0) {
      return null;
    }
    if (!referenceHz.isFinite || referenceHz <= 0) {
      return null;
    }
    return 1200 * math.log(detectedHz / referenceHz) / math.ln2;
  }
}

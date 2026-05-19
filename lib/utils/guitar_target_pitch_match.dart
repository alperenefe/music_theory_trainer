import 'dart:math' as math;

import 'pitch_from_hz.dart';

/// Tuner uygulamaları gibi: hedef perdeye göre oktav + harmonik katlama.
abstract final class GuitarTargetPitchMatch {
  /// Algılanan Hz’yi hedef notanın oktavlarıyla karşılaştırır (±[maxCents]).
  static int? matchMidi({
    required double hz,
    required int targetMidi,
    required double referenceA4,
    double maxCents = 90,
  }) {
    if (!hz.isFinite || hz <= 0) {
      return null;
    }
    final pitchClass = targetMidi % 12;
    var bestMidi = targetMidi;
    var bestCents = double.infinity;
    var bestOctaveDist = 999;

    for (var m = 24; m <= 96; m++) {
      if (m % 12 != pitchClass) {
        continue;
      }
      final tHz = PitchFromHz.hzFromMidi(m, referenceA4);
      if (tHz < 70 || tHz > 520) {
        continue;
      }
      for (final factor in _detectorFactors) {
        final det = hz * factor;
        if (det < 70 || det > 520) {
          continue;
        }
        final c = PitchFromHz.centsDelta(det, tHz)?.abs();
        if (c == null) {
          continue;
        }
        final octaveDist = (m - targetMidi).abs();
        final better = c < bestCents - 0.5 ||
            (c <= bestCents + 0.5 && octaveDist < bestOctaveDist);
        if (better) {
          bestCents = c;
          bestOctaveDist = octaveDist;
          bestMidi = m;
        }
      }
    }
    if (bestCents > maxCents) {
      return null;
    }
    return bestMidi;
  }

  /// Harmonik yanılgısını azalt: hedefe en yakın temel bileşeni seç.
  static double foldToFundamental({
    required double hz,
    required int targetMidi,
    required double referenceA4,
  }) {
    if (!hz.isFinite || hz <= 0) {
      return hz;
    }
    var bestHz = hz;
    var bestCents = double.infinity;
    for (var shift = 0; shift <= 3; shift++) {
      final candidate = hz / math.pow(2, shift);
      if (candidate < 70) {
        break;
      }
      final m = matchMidi(
        hz: candidate,
        targetMidi: targetMidi,
        referenceA4: referenceA4,
        maxCents: 120,
      );
      if (m == null) {
        continue;
      }
      final tHz = PitchFromHz.hzFromMidi(m, referenceA4);
      final c = PitchFromHz.centsDelta(candidate, tHz)?.abs() ?? double.infinity;
      if (c < bestCents ||
          (c <= bestCents + 0.01 && candidate < bestHz)) {
        bestCents = c;
        bestHz = candidate;
      }
    }
    return bestHz;
  }

  static double? centsToTargetMidi({
    required double hz,
    required int targetMidi,
    required double referenceA4,
  }) {
    final m = matchMidi(
      hz: hz,
      targetMidi: targetMidi,
      referenceA4: referenceA4,
    );
    if (m == null) {
      return null;
    }
    return PitchFromHz.centsDelta(hz, PitchFromHz.hzFromMidi(m, referenceA4));
  }

  static const List<double> _detectorFactors = [
    1.0,
    0.5,
    2.0,
    1 / 3,
    3.0,
  ];
}

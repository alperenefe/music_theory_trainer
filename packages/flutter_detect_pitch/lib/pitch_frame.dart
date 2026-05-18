final class PitchFrame {
  const PitchFrame({required this.hz, required this.rms});

  final double hz;
  final double rms;

  static PitchFrame fromEvent(dynamic e) {
    if (e is Map) {
      final hzRaw = e['hz'];
      final rmsRaw = e['rms'];
      final hz = hzRaw is num ? hzRaw.toDouble() : double.parse('$hzRaw');
      final rms = rmsRaw is num
          ? rmsRaw.toDouble().clamp(0.0, 1.0)
          : 1.0;
      return PitchFrame(hz: hz, rms: rms);
    }
    if (e is num) {
      return PitchFrame(hz: e.toDouble(), rms: 1.0);
    }
    throw ArgumentError('pitch_stream: beklenmeyen olay: $e');
  }
}

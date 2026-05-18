import 'dart:async';

export 'pitch_frame.dart';
import 'flutter_detect_pitch_interface.dart';
import 'pitch_frame.dart';

class IosPitchDetector {
  static Stream<PitchFrame> get pitchStream =>
      IosPitchDetectorPlatform.instance.pitchStream;
}

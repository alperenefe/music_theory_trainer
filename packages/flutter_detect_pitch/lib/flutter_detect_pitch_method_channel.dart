import 'dart:async';
import 'package:flutter/services.dart';
import 'flutter_detect_pitch_interface.dart';
import 'pitch_frame.dart';

class MethodChannelIosPitchDetector extends IosPitchDetectorPlatform {
  static const EventChannel _pitchEventChannel = EventChannel('pitch_stream');

  @override
  Stream<PitchFrame> get pitchStream =>
      _pitchEventChannel.receiveBroadcastStream().map(PitchFrame.fromEvent);
}

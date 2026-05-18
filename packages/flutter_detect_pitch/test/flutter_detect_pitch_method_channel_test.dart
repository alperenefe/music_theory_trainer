import 'package:flutter_detect_pitch/flutter_detect_pitch_method_channel.dart';
import 'package:flutter_detect_pitch/pitch_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelIosPitchDetector platform = MethodChannelIosPitchDetector();

  test('stream can be initialized', () async {
    final stream = platform.pitchStream;
    expect(stream, isA<Stream<PitchFrame>>());
  });
}

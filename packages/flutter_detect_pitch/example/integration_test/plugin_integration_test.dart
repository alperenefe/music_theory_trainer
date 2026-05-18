import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pitch stream emits values', (WidgetTester tester) async {
    final stream = IosPitchDetector.pitchStream;

    final frame = await stream.first;

    expect(frame, isA<PitchFrame>());
    expect(frame.hz, isA<double>());
    expect(frame.hz > 0, true);
    expect(frame.rms, isA<double>());
    expect(frame.rms >= 0, true);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';

void main() => runApp(const PitchTestApp());

class PitchTestApp extends StatelessWidget {
  const PitchTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PitchHomePage());
  }
}

class PitchHomePage extends StatefulWidget {
  const PitchHomePage({super.key});

  @override
  PitchHomePageState createState() => PitchHomePageState();
}

class PitchHomePageState extends State<PitchHomePage> {
  double? _frequency;
  double? _rms;

  @override
  void initState() {
    super.initState();
    IosPitchDetector.pitchStream.listen((frame) {
      setState(() {
        _frequency = frame.hz;
        _rms = frame.rms;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pitch Detector Example')),
      body: Center(
        child: Text(
          _frequency != null && _rms != null
              ? 'Detected: ${_frequency!.toStringAsFixed(2)} Hz, rms ${_rms!.toStringAsFixed(3)}'
              : 'Listening...',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

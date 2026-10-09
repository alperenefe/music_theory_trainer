import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';
import 'package:permission_handler/permission_handler.dart';

import '../dsp/yin_pitch.dart';

/// Mikrofon stream yaşam döngüsü: ekran dispose / arka plan → kayıt durur.
///
/// Ham ses (PCM) gönderen platformlarda frekans, eklentinin kaba sıfır-geçiş
/// tahmini yerine YIN ile bulunur: gitarın pes tellerinde sıfır-geçiş oktav ya
/// da harmonik yanılgısı yapar (bkz. test/dsp/yin_pitch_test.dart). Perdesiz
/// (sessiz / gürültü) karelerde hz 0 döner.
final class MicPitchSession with WidgetsBindingObserver {
  StreamSubscription<PitchFrame>? _sub;
  var _active = false;
  YinPitchDetector? _yin;
  int? _yinRate;

  /// Mikrofon durduğunda (dispose, arka plan, manuel stop) UI senkronu.
  VoidCallback? onStopped;

  bool get isActive => _active;

  Future<bool> start({
    required void Function(PitchFrame frame) onFrame,
    Future<void> Function()? onShowRationale,
    Future<void> Function()? onPermissionDenied,
  }) async {
    if (_active) {
      return true;
    }
    await onShowRationale?.call();
    final st = await Permission.microphone.request();
    if (!st.isGranted) {
      await onPermissionDenied?.call();
      return false;
    }
    _sub?.cancel();
    _sub = IosPitchDetector.pitchStream.listen((f) => onFrame(_refine(f)));
    _active = true;
    return true;
  }

  PitchFrame _refine(PitchFrame f) {
    final pcm = f.pcm;
    final sr = f.sampleRate;
    if (pcm == null || sr == null) return f;
    if (_yin == null || _yinRate != sr) {
      _yin = YinPitchDetector(sampleRate: sr, minHz: 60, maxHz: 700, minClarity: 0.7);
      _yinRate = sr;
    }
    final est = _yin!.detect(pcm);
    return f.withHz(est?.hz ?? 0);
  }

  void stop() {
    final wasActive = _active;
    _sub?.cancel();
    _sub = null;
    _active = false;
    if (wasActive) {
      onStopped?.call();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      stop();
    }
  }

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
  }
}

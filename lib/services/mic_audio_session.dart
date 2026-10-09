import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mikrofondan gelen bir ham ses parçası (−1…1, tek kanal).
final class AudioChunk {
  const AudioChunk(this.samples, this.sampleRate);

  final Float64List samples;
  final int sampleRate;

  double get rms {
    if (samples.isEmpty) return 0;
    var e = 0.0;
    for (final v in samples) {
      e += v * v;
    }
    return e == 0 ? 0 : (e / samples.length).clamp(0.0, 1.0);
  }
}

enum MicStartResult {
  started,
  permissionDenied,

  /// Platform ham ses göndermiyor (iOS'ta eklenti yalnızca kaba frekans verir).
  rawAudioUnavailable,
}

/// Ham mikrofon akışının yaşam döngüsü: izin, ekran kapanınca / uygulama
/// arka plana gidince durma. Akor, vuruş ve perde analizörleri bunun üstüne
/// kurulur ([MicPitchSession]'ın ham ses veren karşılığı).
final class MicAudioSession with WidgetsBindingObserver {
  MicAudioSession({
    Stream<PitchFrame> Function()? frames,
    Future<bool> Function()? requestPermission,
  })  : _frames = frames ?? (() => IosPitchDetector.pitchStream),
        _requestPermission =
            requestPermission ?? (() async => (await Permission.microphone.request()).isGranted);

  final Stream<PitchFrame> Function() _frames;
  final Future<bool> Function() _requestPermission;

  StreamSubscription<PitchFrame>? _sub;
  var _active = false;
  var _sawAnyFrame = false;

  VoidCallback? onStopped;
  VoidCallback? onRawAudioUnavailable;

  bool get isActive => _active;

  Future<MicStartResult> start({
    required void Function(AudioChunk chunk) onChunk,
    Future<void> Function()? onShowRationale,
    Future<void> Function()? onPermissionDenied,
  }) async {
    if (_active) return MicStartResult.started;
    await onShowRationale?.call();
    final ok = await _requestPermission();
    if (!ok) {
      await onPermissionDenied?.call();
      return MicStartResult.permissionDenied;
    }
    _sawAnyFrame = false;
    _sub?.cancel();
    _sub = _frames().listen((f) {
      _sawAnyFrame = true;
      final pcm = f.pcm;
      final sr = f.sampleRate;
      if (pcm == null || sr == null) {
        onRawAudioUnavailable?.call();
        return;
      }
      onChunk(AudioChunk(pcm, sr));
    });
    _active = true;
    return MicStartResult.started;
  }

  /// Hiç kare gelmediyse mikrofon açılmamış olabilir (cihaz sorunu).
  bool get receivedAnyFrame => _sawAnyFrame;

  void stop() {
    final was = _active;
    _sub?.cancel();
    _sub = null;
    _active = false;
    if (was) onStopped?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  void attach() => WidgetsBinding.instance.addObserver(this);

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
  }
}

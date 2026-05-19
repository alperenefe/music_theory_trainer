import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mikrofon stream yaşam döngüsü: ekran dispose / arka plan → kayıt durur.
final class MicPitchSession with WidgetsBindingObserver {
  StreamSubscription<PitchFrame>? _sub;
  var _active = false;

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
    _sub = IosPitchDetector.pitchStream.listen(onFrame);
    _active = true;
    return true;
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

import 'package:flutter/material.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';

import '../l10n/app_strings.dart';
import '../models/guitar_note.dart';
import '../models/practice_prefs.dart';
import '../services/guitar_audio_service.dart';
import '../services/practice_prefs_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../utils/guitar_open_string_match.dart';
import '../utils/mic_energy_gate.dart';
import '../utils/mic_pitch_session.dart';
import '../utils/microphone_pitch_smoother.dart';
import '../utils/pitch_from_hz.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/tuner/tuner_gauge_painter.dart';
import '../widgets/tuner/tuner_open_string_strip.dart';
import '../widgets/tuner/tuner_readout_cards.dart';

final class GuitarTunerScreen extends StatefulWidget {
  const GuitarTunerScreen({super.key});

  @override
  State<GuitarTunerScreen> createState() => _GuitarTunerScreenState();
}

final class _GuitarTunerScreenState extends State<GuitarTunerScreen> {
  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
  final _mic = MicPitchSession();
  final _hzSmoother = PitchReadingSmoother(
    alpha: 0.07,
    maxJumpCents: 260,
    invalidStreakToReset: 14,
  );
  final _stringLock = PitchStringLock(framesToSwitch: 20);
  PracticePrefs _prefs = const PracticePrefs();
  var _autoString = 5;
  double? _displayHz;
  double? _activeTargetHz;
  int? _activeTargetMidi;
  var _listening = false;
  double? _cents;
  var _quietStreak = 0;

  @override
  void initState() {
    super.initState();
    _mic.attach();
    _mic.onStopped = () {
      if (mounted && _listening) {
        setState(() {
          _listening = false;
          _displayHz = null;
          _cents = null;
          _activeTargetHz = null;
          _activeTargetMidi = null;
        });
      } else {
        _listening = false;
      }
    };
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await _prefsRepo.load();
    if (!mounted) {
      return;
    }
    setState(() => _prefs = p);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryStartMic();
    });
  }

  @override
  void dispose() {
    _mic.detach();
    super.dispose();
  }

  Future<void> _showMicRationale() async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.micPermissionRationale)),
    );
  }

  Future<void> _tryStartMic() async {
    if (!mounted || _listening) {
      return;
    }
    _quietStreak = 0;
    _hzSmoother.reset();
    _stringLock.reset();
    final ok = await _mic.start(
      onFrame: _onPitch,
      onShowRationale: _showMicRationale,
      onPermissionDenied: () async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.guitarPlayDenied)),
          );
        }
      },
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      setState(() {
        _listening = true;
        _displayHz = null;
        _cents = null;
        _activeTargetHz = null;
        _activeTargetMidi = null;
      });
    }
  }

  void _stopMic() {
    _mic.stop();
    _quietStreak = 0;
    _hzSmoother.reset();
    _stringLock.reset();
    if (_listening && mounted) {
      setState(() {
        _listening = false;
        _displayHz = null;
        _cents = null;
        _activeTargetHz = null;
        _activeTargetMidi = null;
      });
    } else {
      _listening = false;
    }
  }

  GuitarNote get _openNote => GuitarNote(string: _autoString, fret: 0);

  void _onPitch(PitchFrame frame) {
    if (!mounted || !_listening) {
      return;
    }
    if (frame.rms < MicEnergyGate.tunerMinRms) {
      _quietStreak++;
      if (_quietStreak >= MicEnergyGate.quietFramesToClearTuner) {
        setState(() {
          _displayHz = null;
          _cents = null;
          _activeTargetHz = null;
          _activeTargetMidi = null;
        });
      }
      return;
    }
    _quietStreak = 0;
    final hz = frame.hz;
    if (!hz.isFinite) {
      return;
    }
    final refined = PitchFromHz.refineForGuitar(
      hz,
      referenceA4: _prefs.referenceA4Hz,
    );
    final smoothed = _hzSmoother.push(refined);
    if (smoothed == null) {
      setState(() {
        _displayHz = null;
        _cents = null;
        _activeTargetHz = null;
        _activeTargetMidi = null;
      });
      return;
    }
    final cand = GuitarOpenStringMatch.bestForHz(
      smoothed,
      _prefs.referenceA4Hz,
      preferString: _autoString,
    );
    final locked = _stringLock.push(cand.stringIndex);
    final m = GuitarOpenStringMatch.bestForHzOnString(
      smoothed,
      _prefs.referenceA4Hz,
      locked,
    );
    final c = PitchFromHz.centsDelta(smoothed, m.targetHz);
    setState(() {
      _displayHz = smoothed;
      _autoString = locked;
      _activeTargetHz = m.targetHz;
      _activeTargetMidi = m.targetMidi;
      _cents = c;
    });
  }

  Future<void> _saveRef(double v) async {
    final clamped = v.clamp(415.0, 455.0);
    final p = await _prefsRepo.load();
    await _prefsRepo.save(p.copyWith(referenceA4Hz: clamped));
    if (mounted) {
      setState(() => _prefs = p.copyWith(referenceA4Hz: clamped));
    }
  }

  Future<void> _playReference() async {
    await _audio.playMidi(_openNote.midi);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gaugeCents = _cents ?? 0;
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.screenH.copyWith(top: AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: DesignTokens.slate200,
                      tooltip: AppStrings.back,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        AppStrings.tunerTitle,
                        style: t.titleLarge?.copyWith(
                          color: DesignTokens.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_listening)
                      IconButton(
                        onPressed: _stopMic,
                        tooltip: AppStrings.guitarPlayStop,
                        icon: const Icon(Icons.mic_off_rounded),
                        color: DesignTokens.slate200,
                      )
                    else
                      IconButton(
                        onPressed: _tryStartMic,
                        tooltip: AppStrings.tunerMicResume,
                        icon: const Icon(Icons.mic_rounded),
                        color: DesignTokens.blue500,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: AppSpacing.screenHV,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Text(
                      AppStrings.tunerDesc,
                      style: t.bodyMedium?.copyWith(
                        color: DesignTokens.slate400,
                        height: 1.4,
                      ),
                    ),
                    if (_listening) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppStrings.tunerMicActive,
                        style: t.labelLarge?.copyWith(
                          color: DesignTokens.green400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    TunerOpenStringStrip(
                      textTheme: t,
                      listening: _listening,
                      hasPitch: _displayHz != null,
                      autoStringIndex: _autoString,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 220,
                      child: CustomPaint(
                        painter: TunerGaugePainter(cents: gaugeCents),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TunerReadingsCard(
                      textTheme: t,
                      listening: _listening,
                      openNote: _openNote,
                      displayHz: _displayHz,
                      activeTargetHz: _activeTargetHz,
                      activeTargetMidi: _activeTargetMidi,
                      cents: _cents,
                      onPlayReference: _playReference,
                      onStartMic: _tryStartMic,
                      onStopMic: _stopMic,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TunerReferenceSliderCard(
                      textTheme: t,
                      prefs: _prefs,
                      onSliderChanged: (v) => setState(
                        () => _prefs = _prefs.copyWith(referenceA4Hz: v),
                      ),
                      onSliderChangeEnd: _saveRef,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

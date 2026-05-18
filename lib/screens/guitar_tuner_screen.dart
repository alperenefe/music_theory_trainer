import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_strings.dart';
import '../models/guitar_note.dart';
import '../models/practice_prefs.dart';
import '../services/guitar_audio_service.dart';
import '../services/practice_prefs_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../utils/guitar_open_string_match.dart';
import '../utils/mic_energy_gate.dart';
import '../utils/microphone_pitch_smoother.dart';
import '../utils/pitch_from_hz.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/tuner/tuner_gauge_painter.dart';

final class GuitarTunerScreen extends StatefulWidget {
  const GuitarTunerScreen({super.key});

  @override
  State<GuitarTunerScreen> createState() => _GuitarTunerScreenState();
}

final class _GuitarTunerScreenState extends State<GuitarTunerScreen> {
  static const List<int> _stringOrder = [5, 4, 3, 2, 1, 0];
  static const List<Color> _stringColors = [
    Color(0xFFE85D2C),
    Color(0xFFEF4444),
    Color(0xFFFBBF24),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
  ];

  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
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
  StreamSubscription<PitchFrame>? _pitchSub;
  var _listening = false;
  double? _cents;
  var _quietStreak = 0;

  @override
  void initState() {
    super.initState();
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
    _stopMic();
    super.dispose();
  }

  Future<void> _tryStartMic() async {
    if (!mounted || _listening) {
      return;
    }
    final st = await Permission.microphone.request();
    if (!mounted) {
      return;
    }
    if (!st.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.guitarPlayDenied)),
      );
      return;
    }
    _startMic();
  }

  void _startMic() {
    if (_listening) {
      return;
    }
    _quietStreak = 0;
    _hzSmoother.reset();
    _stringLock.reset();
    _pitchSub?.cancel();
    _pitchSub = IosPitchDetector.pitchStream.listen(_onPitch);
    setState(() {
      _listening = true;
      _displayHz = null;
      _cents = null;
      _activeTargetHz = null;
      _activeTargetMidi = null;
    });
  }

  void _stopMic() {
    _pitchSub?.cancel();
    _pitchSub = null;
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
    final nested = PitchFromHz.octaveNestForGuitar(hz);
    final smoothed = _hzSmoother.push(nested);
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
    final cents = _cents ?? 0;
    final centsLabel = _cents == null
        ? '—'
        : '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)}';
    String tuneWord() {
      if (_cents == null) {
        return '';
      }
      if (cents.abs() <= 8) {
        return AppStrings.tunerInTune;
      }
      return cents > 0 ? AppStrings.tunerSharp : AppStrings.tunerFlat;
    }

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
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: List.generate(_stringOrder.length, (i) {
                        final s = _stringOrder[i];
                        final active =
                            _listening && _displayHz != null && s == _autoString;
                        final n = GuitarNote(string: s, fret: 0);
                        final col = _stringColors[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                col.withValues(alpha: active ? 1 : 0.55),
                                col.withValues(alpha: active ? 0.75 : 0.4),
                              ],
                            ),
                            border: Border.all(
                              color: active
                                  ? DesignTokens.white
                                  : Colors.transparent,
                              width: active ? 2.5 : 0,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: col.withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                n.noteName,
                                style: t.titleLarge?.copyWith(
                                  color: DesignTokens.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                n.stringLabel.toUpperCase(),
                                style: t.labelSmall?.copyWith(
                                  color: DesignTokens.white.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 220,
                      child: CustomPaint(
                        painter: TunerGaugePainter(cents: cents),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SoftCard(
                      padding: AppSpacing.cardPad,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.tunerStringLine,
                                style: t.bodySmall?.copyWith(
                                  color: DesignTokens.slate400,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _listening && _displayHz != null
                                      ? '${_openNote.openStringName} (${_openNote.stringLabel})'
                                      : '—',
                                  textAlign: TextAlign.end,
                                  style: t.titleMedium?.copyWith(
                                    color: DesignTokens.slate200,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.tunerTargetHz,
                                style: t.bodySmall?.copyWith(
                                  color: DesignTokens.slate400,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _activeTargetHz != null &&
                                          _activeTargetMidi != null
                                      ? '${_activeTargetHz!.toStringAsFixed(1)} Hz · ${GuitarNote.noteNameForMidi(_activeTargetMidi!)}'
                                      : _activeTargetHz != null
                                          ? '${_activeTargetHz!.toStringAsFixed(1)} Hz'
                                          : '—',
                                  textAlign: TextAlign.end,
                                  style: t.titleMedium?.copyWith(
                                    color: DesignTokens.slate200,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.tunerDetected,
                                style: t.bodySmall?.copyWith(
                                  color: DesignTokens.slate400,
                                ),
                              ),
                              Text(
                                _displayHz != null
                                    ? '${_displayHz!.toStringAsFixed(1)} Hz'
                                    : '—',
                                style: t.titleMedium?.copyWith(
                                  color: DesignTokens.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${AppStrings.tunerCents}: $centsLabel ${tuneWord().isEmpty ? '' : '· ${tuneWord()}'}',
                            textAlign: TextAlign.center,
                            style: t.headlineSmall?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.tonalIcon(
                            onPressed: _playReference,
                            icon: const Icon(Icons.graphic_eq_rounded),
                            label: Text(AppStrings.tunerPlayRef),
                          ),
                          if (!_listening) ...[
                            const SizedBox(height: AppSpacing.sm),
                            FilledButton.icon(
                              onPressed: _tryStartMic,
                              icon: const Icon(Icons.mic_rounded),
                              label: Text(AppStrings.tunerMicResume),
                            ),
                          ] else ...[
                            const SizedBox(height: AppSpacing.sm),
                            FilledButton.icon(
                              onPressed: _stopMic,
                              icon: const Icon(Icons.stop_rounded),
                              label: Text(AppStrings.guitarPlayStop),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SoftCard(
                      padding: AppSpacing.cardPad,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.tunerRefA4,
                            style: t.titleSmall?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Slider.adaptive(
                            min: 415,
                            max: 455,
                            divisions: 40,
                            value: _prefs.referenceA4Hz.clamp(415, 455),
                            label: _prefs.referenceA4Hz.toStringAsFixed(1),
                            onChanged: (v) =>
                                setState(() => _prefs = _prefs.copyWith(
                                      referenceA4Hz: v,
                                    )),
                            onChangeEnd: _saveRef,
                          ),
                          Text(
                            '${_prefs.referenceA4Hz.toStringAsFixed(1)} Hz',
                            textAlign: TextAlign.center,
                            style: t.bodySmall?.copyWith(
                              color: DesignTokens.slate400,
                            ),
                          ),
                        ],
                      ),
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

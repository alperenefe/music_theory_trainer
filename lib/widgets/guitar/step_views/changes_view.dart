import 'dart:async';

import 'package:flutter/material.dart';

import '../../../dsp/chord_change_counter.dart';
import '../../../models/chord_shape.dart';
import '../../../models/guitar_path.dart';
import '../../../services/mic_audio_session.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/design_tokens.dart';
import '../chord_diagram.dart';
import '../step_env.dart';

/// Bir dakikada akor değişimi (JustinGuitar'ın temel egzersizi).
///
/// Mikrofon vuruşları ve çalınan akoru dinleyip her gerçek A↔B geçişini sayar.
/// Mikrofon yoksa "+1" ile elle sayılır; elle sayılan sonuç en fazla 1 yıldız verir.
final class ChangesView extends StatefulWidget {
  const ChangesView({
    super.key,
    required this.step,
    required this.env,
    required this.onFinished,
    required this.onNext,
    required this.onBest,
    this.bestSoFar,
    this.duration = const Duration(seconds: 60),
  });

  final GuitarStep step;
  final StepEnv env;
  final void Function(int stars) onFinished;
  final VoidCallback onNext;

  /// Rekor anahtarı (`changes:A-D`) ve yeni değer.
  final void Function(String key, int value) onBest;
  final int? bestSoFar;
  final Duration duration;

  @override
  State<ChangesView> createState() => _ChangesViewState();
}

enum _Phase { ready, countdown, running, done }

final class _ChangesViewState extends State<ChangesView> with MicStepMixin {
  late final ChordShape _a = widget.step.chords[0];
  late final ChordShape _b = widget.step.chords[1];
  late final int _target = widget.step.target ?? 20;
  String get _bestKey => 'changes:${_a.id}-${_b.id}';

  ChordChangeCounter? _counter;
  _Phase _phase = _Phase.ready;
  Timer? _timer;
  var _countdown = 3;
  late var _remaining = widget.duration.inSeconds;
  var _count = 0;
  var _manualCount = 0;
  ChordShape? _current;
  int _stars = 0;
  var _usedManual = false;

  @override
  void initState() {
    super.initState();
    initMic(widget.env);
  }

  @override
  void dispose() {
    _timer?.cancel();
    disposeMic();
    super.dispose();
  }

  @override
  void onAudio(AudioChunk chunk) {
    if (_phase != _Phase.running) return;
    final c = _counter ??= ChordChangeCounter(sampleRate: chunk.sampleRate, a: _a, b: _b);
    final events = c.process(chunk.samples);
    if (events.isNotEmpty) {
      setState(() {
        _count = c.changes;
        _current = c.current;
      });
    }
  }

  Future<void> _begin() async {
    await startMic(); // reddedilse de elle sayımla devam edilir
    if (!mounted) return;
    setState(() {
      _phase = _Phase.countdown;
      _countdown = 3;
      _count = 0;
      _manualCount = 0;
      _current = null;
      _usedManual = false;
      _remaining = widget.duration.inSeconds;
      _counter?.reset();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_phase == _Phase.countdown) {
        if (_countdown <= 1) {
          setState(() => _phase = _Phase.running);
        } else {
          setState(() => _countdown--);
        }
      } else if (_phase == _Phase.running) {
        if (_remaining <= 1) {
          t.cancel();
          _finish();
        } else {
          setState(() => _remaining--);
        }
      }
    });
  }

  void _finish() {
    final c = _counter;
    if (c != null) {
      c.flush();
      _count = c.changes;
    }
    final micOk = micState != MicUiState.denied && micState != MicUiState.unsupported;
    stopMic();
    final manualOnly = !micOk || _manualCount > 0;
    final used = manualOnly ? _manualCount : _count;
    var stars = used >= _target
        ? 3
        : (used >= _target * 0.7 ? 2 : (used >= _target * 0.4 ? 1 : 0));
    if (manualOnly && stars > 1) stars = 1;
    setState(() {
      _phase = _Phase.done;
      _stars = stars;
      _usedManual = manualOnly;
      _count = used;
    });
    if (!manualOnly) widget.onBest(_bestKey, used);
    widget.onFinished(stars);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final shown = _phase == _Phase.running && _manualCount > 0 ? _manualCount : _count;
    return ListView(
      padding: AppSpacing.screenHV,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChordDiagram(
              chord: _a,
              width: 110,
              accent: _current?.id == _a.id ? DesignTokens.green400 : DesignTokens.blue500,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 60, left: 8, right: 8),
              child: Icon(Icons.swap_horiz_rounded, color: DesignTokens.slate400),
            ),
            ChordDiagram(
              chord: _b,
              width: 110,
              accent: _current?.id == _b.id ? DesignTokens.green400 : DesignTokens.blue500,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_phase == _Phase.ready) ...[
          Text(
            'Hedef: bir dakikada $_target değişim'
            '${widget.bestSoFar != null ? '  •  Rekorun: ${widget.bestSoFar}' : ''}',
            textAlign: TextAlign.center,
            style: t.titleSmall?.copyWith(color: DesignTokens.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${_a.symbol} çal, ${_b.symbol} akoruna geç, tekrar ${_a.symbol}… Her akoru bir kez '
            'çal (vuruş), sonra değiştir. Hız değil temizlik önce: ses kötü çıkıyorsa yavaşla.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: DesignTokens.slate300, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _begin,
            icon: const Icon(Icons.timer_rounded),
            label: const Text('Başla (3 sn geri sayım)'),
          ),
          if (micState == MicUiState.denied || micState == MicUiState.unsupported)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: MicProblemNote(state: micState),
            ),
        ] else if (_phase == _Phase.countdown)
          Center(
            child: Text(
              '$_countdown',
              style: t.displayLarge?.copyWith(color: DesignTokens.earGold, fontWeight: FontWeight.w900),
            ),
          )
        else if (_phase == _Phase.running) ...[
          Center(
            child: Text(
              '$shown',
              style: t.displayLarge?.copyWith(color: DesignTokens.white, fontWeight: FontWeight.w900),
            ),
          ),
          Center(
            child: Text(
              'değişim  •  $_remaining sn  •  hedef $_target',
              style: t.bodyMedium?.copyWith(color: DesignTokens.slate400),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: (shown / _target).clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: DesignTokens.green400,
            backgroundColor: DesignTokens.slate700,
          ),
          const SizedBox(height: AppSpacing.sm),
          MicLevelBar(level: micLevel, active: micState == MicUiState.listening),
          if (micState == MicUiState.denied || micState == MicUiState.unsupported) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => setState(() => _manualCount++),
              child: const Text('+1 değişim (elle say)'),
            ),
          ],
        ] else
          StepResultCard(
            stars: _stars,
            title: '$_count değişim / dakika',
            lines: [
              if (_usedManual) 'Elle sayıldığı için en fazla 1 yıldız verildi.',
              if (!_usedManual && _count < _target)
                'Hedef $_target. Parmakları bir sonraki akora hazır tut: değişimden önce parmak şeklini zihninde kur.',
              if (!_usedManual && _count >= _target) 'Hedefe ulaştın. Sıradaki adıma geçebilirsin.',
            ],
            onRetry: () => setState(() => _phase = _Phase.ready),
            onContinue: widget.onNext,
          ),
      ],
    );
  }
}

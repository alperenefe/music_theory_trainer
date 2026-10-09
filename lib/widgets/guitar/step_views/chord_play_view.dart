import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/chord_shape.dart';
import '../../../models/guitar_path.dart';
import '../../../services/chord_listener.dart';
import '../../../services/diag_recorder.dart';
import '../../../services/mic_audio_session.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/design_tokens.dart';
import '../chord_diagram.dart';
import '../step_env.dart';

/// Tek bir akoru tut ve çal: akor algılayıcı doğrular, eksik / fazla telleri söyler.
final class ChordPlayView extends StatefulWidget {
  const ChordPlayView({
    super.key,
    required this.step,
    required this.env,
    required this.onFinished,
    required this.onNext,
  });

  final GuitarStep step;
  final StepEnv env;
  final void Function(int stars) onFinished;
  final VoidCallback onNext;

  @override
  State<ChordPlayView> createState() => _ChordPlayViewState();
}

final class _ChordPlayViewState extends State<ChordPlayView> with MicStepMixin {
  late final ChordShape _chord = widget.step.chords.first;
  ChordListener? _listener;
  int? _stars;
  var _manual = false;
  List<int> _missing = const [];
  List<int> _extra = const [];
  double? _score;

  final _diag = DiagRecorder();

  @override
  void initState() {
    super.initState();
    initMic(widget.env);
  }

  @override
  void dispose() {
    disposeMic();
    super.dispose();
  }

  @override
  void onAudio(AudioChunk chunk) {
    if (_stars != null) return;
    final l = _listener ??= ChordListener(sampleRate: chunk.sampleRate, target: _chord);
    if (kDebugMode) _diag.add(chunk.samples, chunk.sampleRate);
    final res = l.feed(chunk.samples);
    var changed = false;
    if (res != null) {
      _missing = res.missingStrings;
      _extra = res.extraStrings;
      _score = res.score;
      changed = true;
    }
    if (l.confirmed && res != null) {
      final problems = res.missingStrings.length + res.extraStrings.length;
      _finish(problems == 0 ? 3 : (problems == 1 ? 2 : 1));
      return;
    }
    if (changed || (micLevel - l.level).abs() > 0.05) {
      setState(() => micLevel = l.level);
    }
  }

  Future<void> _saveDiag() async {
    final path = await _diag.save(_chord.id);
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedildi: ${path.split('/').last}')),
      );
    }
  }

  String _diagText() {
    final l = _listener;
    if (l == null) return 'tanı: dinleme başlamadı';
    final a = l.last;
    final rms = l.lastRms.toStringAsFixed(4);
    if (a == null) return 'tanı: ses çok sessiz (rms $rms < ${l.minRms})';
    return 'tanı: rms $rms  skor ${a.score.toStringAsFixed(2)}  '
        'en iyi ${a.best?.id} ${a.bestScore.toStringAsFixed(2)}  '
        'eşleşme ${a.isMatch}  seri ${l.streak}\n'
        'eksik ${a.missingStrings}  fazla ${a.extraStrings}';
  }

  void _finish(int stars, {bool manual = false}) {
    stopMic();
    setState(() {
      _stars = stars;
      _manual = manual;
    });
    widget.onFinished(stars);
  }

  void _retry() {
    _listener?.reset();
    setState(() {
      _stars = null;
      _manual = false;
      _missing = const [];
      _extra = const [];
      _score = null;
    });
    startMic();
  }

  String _feedback() {
    if (_stars != null) return '';
    if (_listener?.last == null && micState == MicUiState.listening) {
      return 'Akoru tut ve tüm telleri tek seferde, yavaşça aşağı doğru çal.';
    }
    final parts = <String>[];
    if (_missing.isNotEmpty) {
      parts.add('Duyulmayan: ${_missing.map((s) => ChordShape.stringNamesTr[s]).join(', ')}');
    }
    if (_extra.isNotEmpty) {
      parts.add('Susturulmalı ama çınlıyor: ${_extra.map((s) => ChordShape.stringNamesTr[s]).join(', ')}');
    }
    if (parts.isEmpty && _score != null) {
      parts.add('Neredeyse… parmakları biraz daha dik tut ve telleri yavaş çal.');
    }
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final listening = micState == MicUiState.listening;
    final problems = [..._missing, ..._extra];
    return ListView(
      padding: AppSpacing.screenHV,
      children: [
        Center(child: ChordDiagram(chord: _chord, width: 170, problemStrings: problems)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _chord.tip,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: DesignTokens.slate300, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_stars == null) ...[
          MicLevelBar(level: micLevel, active: listening),
          const SizedBox(height: AppSpacing.sm),
          if (micState == MicUiState.denied || micState == MicUiState.unsupported)
            MicProblemNote(state: micState, onRetry: startMic),
          if (_feedback().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                _feedback(),
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: DesignTokens.streakOrange),
              ),
            ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_diagText(), style: t.bodySmall?.copyWith(color: DesignTokens.slate500, fontFamily: 'monospace')),
            TextButton.icon(
              onPressed: _saveDiag,
              icon: const Icon(Icons.save_alt_rounded, size: 18),
              label: const Text('Tanı kaydı (son 4 sn)'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: listening || micState == MicUiState.starting ? null : startMic,
            icon: const Icon(Icons.mic_rounded),
            label: Text(listening ? 'Dinliyorum… akoru çal' : 'Dinlemeyi başlat'),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => _finish(1, manual: true),
            child: const Text('Elle onayla (en fazla 1 yıldız)'),
          ),
        ] else
          StepResultCard(
            stars: _stars!,
            title: _manual
                ? 'Elle onaylandı'
                : switch (_stars!) {
                    3 => 'Temiz ve tam bir ${_chord.symbol}!',
                    2 => '${_chord.symbol} duyuldu, bir tel zayıftı.',
                    _ => '${_chord.symbol} duyuldu ama pürüzlü.',
                  },
            lines: [
              if (!_manual && _stars! < 3) 'Üç yıldız için tüm tellerin net çınlaması gerekir.',
              if (_manual) 'Mikrofonla doğrulanmadığı için 1 yıldız verildi.',
            ],
            onRetry: _retry,
            onContinue: widget.onNext,
          ),
      ],
    );
  }
}

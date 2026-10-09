import 'package:flutter/material.dart';

import '../../../audio/ear_sound.dart';
import '../../../models/chord_shape.dart';
import '../../../models/guitar_path.dart';
import '../../../services/chord_listener.dart';
import '../../../services/guitar_audio_service.dart';
import '../../../services/mic_audio_session.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/design_tokens.dart';
import '../chord_diagram.dart';
import '../step_env.dart';

/// Duy → Çal: uygulama bir akor döngüsü çalar (adlar gizli); sen kulaktan
/// bulup gitarında çalarsın. Bulunan akorun adı açılır.
final class EarPlayView extends StatefulWidget {
  const EarPlayView({
    super.key,
    required this.step,
    required this.env,
    required this.onFinished,
    required this.onNext,
    this.playLoop,
  });

  final GuitarStep step;
  final StepEnv env;
  final void Function(int stars) onFinished;
  final VoidCallback onNext;

  /// Testte döngü sesini taklit etmek için; verilmezse gerçek ses çalınır.
  final Future<void> Function(HarmonicRhythmSound sound)? playLoop;

  @override
  State<EarPlayView> createState() => _EarPlayViewState();
}

final class _EarPlayViewState extends State<EarPlayView> with MicStepMixin {
  late final List<ChordShape> _loop = widget.step.chords;
  late final List<ChordShape> _distinct = _loop.toSet().toList();
  final _found = <String>{};
  final _streaks = <String, int>{};
  final _revealed = <String>{};
  var _hints = 0;
  var _playing = false;
  var _plays = 0;
  ChordListener? _listener;
  int? _stars;
  var _manual = false;

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

  HarmonicRhythmSound get _sound => HarmonicRhythmSound(
        chords: [for (final c in _loop) c.midis],
        beatsPerChord: 4,
        bpm: widget.step.bpm ?? 70,
      );

  Future<void> _listen() async {
    if (_playing) return;
    setState(() {
      _playing = true;
      _plays++;
    });
    // Hoparlörden çıkan döngü mikrofona girip "çalındı" sanılmasın.
    final f = widget.playLoop;
    if (f != null) {
      await f(_sound);
    } else {
      await GuitarAudioService.instance.playSound(_sound);
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _listener?.reset();
    _streaks.clear();
    if (mounted) setState(() => _playing = false);
  }

  @override
  void onAudio(AudioChunk chunk) {
    if (_stars != null || _playing) return;
    final l = _listener ??= ChordListener(
      sampleRate: chunk.sampleRate,
      target: _distinct.first,
      candidates: _distinct,
    );
    l.feed(chunk.samples);
    final spec = l.lastSpectrum;
    var dirty = (micLevel - l.level).abs() > 0.05;
    micLevel = l.level;
    if (spec != null) {
      for (final c in _distinct) {
        if (_found.contains(c.id)) continue;
        final res = l.detector.check(c, spec, candidates: _distinct);
        _streaks[c.id] = res.isMatch ? (_streaks[c.id] ?? 0) + 1 : 0;
        if ((_streaks[c.id] ?? 0) >= 2) {
          _found.add(c.id);
          dirty = true;
        }
      }
      // Her analiz adımında yalnızca bir kez sayılsın diye akış sıfırlanır.
      l.lastSpectrum = null;
    }
    if (_found.length == _distinct.length) {
      _complete();
      return;
    }
    if (dirty) setState(() {});
  }

  void _complete() {
    stopMic();
    final stars = _hints == 0 ? 3 : (_hints == 1 ? 2 : 1);
    setState(() => _stars = stars);
    widget.onFinished(stars);
  }

  void _manualDone() {
    stopMic();
    setState(() {
      _stars = 1;
      _manual = true;
    });
    widget.onFinished(1);
  }

  void _hint() {
    for (final c in _distinct) {
      if (!_found.contains(c.id) && !_revealed.contains(c.id)) {
        setState(() {
          _revealed.add(c.id);
          _hints++;
        });
        return;
      }
    }
  }

  void _retry() {
    _found.clear();
    _revealed.clear();
    _streaks.clear();
    _listener?.reset();
    setState(() {
      _hints = 0;
      _plays = 0;
      _stars = null;
      _manual = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final listening = micState == MicUiState.listening;
    return ListView(
      padding: AppSpacing.screenHV,
      children: [
        Text(
          'Döngüde ${_distinct.length} farklı akor var. Dinle, kulağınla bul, gitarında çal.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: DesignTokens.slate300, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < _loop.length; i++) _slot(t, i, _loop[i]),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_stars == null) ...[
          FilledButton.icon(
            onPressed: _playing ? null : _listen,
            icon: Icon(_playing ? Icons.graphic_eq_rounded : Icons.headphones_rounded),
            label: Text(_playing ? 'Çalıyor… (mikrofon bekliyor)' : (_plays == 0 ? 'Döngüyü dinle' : 'Tekrar dinle')),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_plays > 0 && !listening)
            OutlinedButton.icon(
              onPressed: micState == MicUiState.starting ? null : startMic,
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Çalmaya başla (mikrofon)'),
            ),
          if (listening) MicLevelBar(level: micLevel, active: true),
          if (micState == MicUiState.denied || micState == MicUiState.unsupported)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: MicProblemNote(state: micState, onRetry: startMic),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _hint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: Text('İpucu ($_hints)'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _manualDone,
                  child: const Text('Elle onayla (1 yıldız)'),
                ),
              ),
            ],
          ),
        ] else
          StepResultCard(
            stars: _stars!,
            title: _manual ? 'Elle onaylandı' : 'Döngüyü kulaktan buldun!',
            lines: [
              if (!_manual && _hints > 0) 'İpucu kullanımı: $_hints (üç yıldız için ipucusuz bul).',
              if (!_manual) 'Aynı kulak becerisi: 8. hafta (I–V–vi–IV) ile birebir bağlantılı.',
              if (_manual) 'Mikrofonla doğrulanmadığı için 1 yıldız verildi.',
            ],
            onRetry: _retry,
            onContinue: widget.onNext,
          ),
      ],
    );
  }

  Widget _slot(TextTheme t, int i, ChordShape c) {
    final known = _found.contains(c.id) || _revealed.contains(c.id) || _stars != null;
    final ok = _found.contains(c.id);
    return Container(
      width: 84,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: DesignTokens.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: ok ? DesignTokens.green400 : DesignTokens.borderSubtle),
      ),
      child: known
          ? ChordDiagram(
              chord: c,
              width: 64,
              accent: ok ? DesignTokens.green400 : DesignTokens.blue500,
            )
          : SizedBox(
              height: 112,
              child: Center(
                child: Text(
                  '${i + 1}\n?',
                  textAlign: TextAlign.center,
                  style: t.headlineSmall?.copyWith(color: DesignTokens.slate500),
                ),
              ),
            ),
    );
  }
}

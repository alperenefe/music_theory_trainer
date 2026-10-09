import 'package:flutter/material.dart';

import '../../../models/chord_shape.dart';
import '../../../models/guitar_path.dart';
import '../../../services/mic_audio_session.dart';
import '../../../services/open_string_listener.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/design_tokens.dart';
import '../step_env.dart';

/// Altı açık teli sırayla (6. telden 1. tele) çal; uygulama her telin perdesini
/// (YIN) ve akort sapmasını gösterir.
final class OpenStringsView extends StatefulWidget {
  const OpenStringsView({
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
  State<OpenStringsView> createState() => _OpenStringsViewState();
}

final class _OpenStringsViewState extends State<OpenStringsView> with MicStepMixin {
  static const _names = ['Mi (E)', 'La (A)', 'Re (D)', 'Sol (G)', 'Si (B)', 'mi (e)'];

  OpenStringListener? _listener;
  var _next = 0;
  final _cents = List<double?>.filled(6, null);
  String? _hint;
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

  @override
  void onAudio(AudioChunk chunk) {
    if (_stars != null) return;
    final l = _listener ??= OpenStringListener(sampleRate: chunk.sampleRate);
    final h = l.feed(chunk.samples);
    var dirty = (micLevel - l.level).abs() > 0.05;
    micLevel = l.level;
    if (h != null) {
      if (h.string == _next) {
        _cents[h.string] = h.cents;
        _next++;
        _hint = null;
        dirty = true;
        if (_next >= 6) {
          _complete();
          return;
        }
      } else {
        _hint = 'Şimdi ${ChordShape.stringNamesTr[_next]} çalınmalıydı; ${ChordShape.stringNamesTr[h.string]} duyuldu.';
        dirty = true;
      }
    }
    if (dirty) setState(() {});
  }

  void _complete() {
    stopMic();
    final worst = _cents.whereType<double>().fold<double>(0, (m, c) => c.abs() > m ? c.abs() : m);
    final stars = worst <= 15 ? 3 : 2;
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

  void _retry() {
    _listener?.reset();
    for (var i = 0; i < 6; i++) {
      _cents[i] = null;
    }
    setState(() {
      _next = 0;
      _stars = null;
      _manual = false;
      _hint = null;
    });
    startMic();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final listening = micState == MicUiState.listening;
    return ListView(
      padding: AppSpacing.screenHV,
      children: [
        for (var s = 0; s < 6; s++) _row(t, s),
        const SizedBox(height: AppSpacing.md),
        if (_stars == null) ...[
          MicLevelBar(level: micLevel, active: listening),
          if (micState == MicUiState.denied || micState == MicUiState.unsupported)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: MicProblemNote(state: micState, onRetry: startMic),
            ),
          if (_hint != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(_hint!, style: t.bodyMedium?.copyWith(color: DesignTokens.streakOrange)),
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: listening || micState == MicUiState.starting ? null : startMic,
            icon: const Icon(Icons.mic_rounded),
            label: Text(
              listening
                  ? 'Dinliyorum… ${ChordShape.stringNamesTr[_next]}'
                  : 'Dinlemeyi başlat',
            ),
          ),
          TextButton(
            onPressed: _manualDone,
            child: const Text('Elle onayla (en fazla 1 yıldız)'),
          ),
        ] else
          StepResultCard(
            stars: _stars!,
            title: _manual
                ? 'Elle onaylandı'
                : (_stars == 3 ? 'Altı tel de akortlu!' : 'Altı tel duyuldu, bazıları akortsuz'),
            lines: [
              if (!_manual && _stars! < 3) 'Sapması 15 sentten fazla olan telleri akort cihazıyla düzelt.',
              if (_manual) 'Mikrofonla doğrulanmadığı için 1 yıldız verildi.',
            ],
            onRetry: _retry,
            onContinue: widget.onNext,
          ),
      ],
    );
  }

  Widget _row(TextTheme t, int s) {
    final done = _cents[s];
    final active = s == _next && _stars == null;
    final off = done != null && done.abs() > 15;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? DesignTokens.blue600.withValues(alpha: 0.18) : DesignTokens.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: active ? DesignTokens.blue500 : DesignTokens.borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${6 - s}.',
              style: t.titleMedium?.copyWith(color: DesignTokens.slate400, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              _names[s],
              style: t.titleMedium?.copyWith(color: DesignTokens.white, fontWeight: FontWeight.w700),
            ),
          ),
          if (done != null) ...[
            Text(
              '${done >= 0 ? '+' : ''}${done.round()} sent',
              style: t.bodyMedium?.copyWith(
                color: off ? DesignTokens.streakOrange : DesignTokens.green400,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              off ? Icons.tune_rounded : Icons.check_circle_rounded,
              color: off ? DesignTokens.streakOrange : DesignTokens.green400,
              size: 20,
            ),
          ] else if (active)
            const Icon(Icons.hearing_rounded, color: DesignTokens.blue500, size: 20),
        ],
      ),
    );
  }
}

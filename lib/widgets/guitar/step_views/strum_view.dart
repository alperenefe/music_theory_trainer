import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../dsp/metronome_track.dart';
import '../../../dsp/onset_detector.dart';
import '../../../dsp/strum_session.dart';
import '../../../models/chord_shape.dart';
import '../../../models/guitar_path.dart';
import '../../../models/strum_pattern.dart';
import '../../../services/mic_audio_session.dart';
import '../../../services/progression_judge.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/design_tokens.dart';
import '../chord_diagram.dart';
import '../step_env.dart';

/// Vuruş kalıbı (strum) ve akor döngüsü (progression) egzersizi.
///
/// Metronom tüm egzersiz için tek parça olarak çalınır; mikrofondan gelen
/// vuruşlar bu ızgarayla karşılaştırılır (gecikme otomatik çıkarılır).
/// Döngü adımlarında ayrıca her ölçüde DOĞRU akorun çalındığı denetlenir.
final class StrumView extends StatefulWidget {
  const StrumView({
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
  State<StrumView> createState() => _StrumViewState();
}

enum _SPhase { setup, preparing, running, done }

final class _StrumViewState extends State<StrumView> with MicStepMixin {
  late final StrumPattern _pattern = StrumPatterns.byId(widget.step.patternId ?? 'quarters');
  late final bool _isProgression = widget.step.kind == GuitarStepKind.progression;
  late int _bpm = (widget.step.bpm ?? 70).clamp(_pattern.minBpm, _pattern.maxBpm);
  late final int _bars = widget.step.bars ?? 4;
  late final List<ChordShape> _chords = widget.step.chords;

  StepPlayer? _player;
  StreamSubscription<Duration>? _posSub;
  Timer? _originFallback;
  late StrumSession _session;

  _SPhase _phase = _SPhase.setup;
  OnsetDetector? _onsets;
  final _found = <Onset>[];
  final _recorded = <Float64List>[];
  var _sampleRate = 44100;
  var _consumed = 0;
  var _playCallSamples = 0;
  int? _originSample;
  double _timelineMs = 0;

  StrumReport? _report;
  ProgressionReport? _progression;
  int _stars = 0;
  var _manual = false;

  @override
  void initState() {
    super.initState();
    initMic(widget.env);
    _session = _newSession();
  }

  StrumSession _newSession() => StrumSession(pattern: _pattern, bpm: _bpm, bars: _bars);

  @override
  void dispose() {
    _cancelRun();
    _player?.dispose();
    disposeMic();
    super.dispose();
  }

  void _cancelRun() {
    _originFallback?.cancel();
    _posSub?.cancel();
    _posSub = null;
    _player?.stop();
  }

  @override
  void onAudio(AudioChunk chunk) {
    if (_phase != _SPhase.preparing && _phase != _SPhase.running) return;
    _sampleRate = chunk.sampleRate;
    final det = _onsets ??= OnsetDetector(sampleRate: chunk.sampleRate);
    for (final o in det.process(chunk.samples)) {
      _found.add(o);
    }
    if (_isProgression) _recorded.add(Float64List.fromList(chunk.samples));
    _consumed += chunk.samples.length;
    final lvl = chunk.rms.clamp(0.0, 1.0) * 40;
    micLevel = lvl.clamp(0.0, 1.0);
    final origin = _originSample;
    if (origin != null) {
      // Zaman, gerçek saatten değil ses örneklerinden ölçülür: vuruşlarla aynı eksende.
      final t = (_consumed - origin) * 1000 / _sampleRate;
      if (t >= _session.totalMs + 450) {
        _finish();
      } else {
        setState(() => _timelineMs = t < 0 ? 0 : t);
      }
    }
  }

  Future<void> _start() async {
    final ok = await startMic();
    if (!ok || !mounted) return;
    _session = _newSession();
    _onsets = null;
    _found.clear();
    _recorded.clear();
    _consumed = 0;
    _originSample = null;
    setState(() {
      _phase = _SPhase.preparing;
      _timelineMs = 0;
    });
    final track = MetronomeTrack.generate(bpm: _bpm, totalBars: _session.totalBars);
    final player = _player ??= widget.env.player();
    _posSub?.cancel();
    _posSub = player.positions.listen((pos) {
      if (_originSample != null) return;
      _setOrigin(_consumed - (pos.inMicroseconds * _sampleRate / 1e6).round());
    });
    _playCallSamples = _consumed;
    // Konum olayı hiç gelmezse (bazı cihazlarda) çalma çağrısı anını kullan.
    _originFallback?.cancel();
    _originFallback = Timer(const Duration(milliseconds: 1500), () {
      if (_originSample == null && mounted) _setOrigin(_playCallSamples);
    });
    await player.playWav(track.wav);
  }

  void _setOrigin(int sample) {
    _originSample = sample;
    if (!mounted) return;
    setState(() => _phase = _SPhase.running);
  }

  void _finish() {
    if (_phase == _SPhase.done) return;
    _originFallback?.cancel();
    _posSub?.cancel();
    _player?.stop();
    stopMic();
    final origin = _originSample ?? 0;
    final detected = [
      for (final o in _found)
        if (o.sample >= origin) DetectedStrum((o.sample - origin) * 1000 / _sampleRate, o.strength),
    ];
    final report = _session.evaluate(detected);
    ProgressionReport? prog;
    var stars = report.result.stars;
    if (_isProgression) {
      final total = _recorded.fold<int>(0, (s, c) => s + c.length);
      final all = Float64List(total);
      var o = 0;
      for (final c in _recorded) {
        all.setRange(o, o + c.length, c);
        o += c.length;
      }
      final from = origin.clamp(0, all.length);
      prog = ProgressionJudge.judge(
        audio: Float64List.sublistView(all, from),
        sampleRate: _sampleRate,
        session: _session,
        barChords: _chords,
        latencyMs: report.result.latencyMs,
      );
      stars = ProgressionJudge.stars(
        rhythmScore: report.result.score,
        chordFraction: prog.fraction,
      );
    }
    setState(() {
      _phase = _SPhase.done;
      _report = report;
      _progression = prog;
      _stars = stars;
    });
    widget.onFinished(stars);
  }

  void _manualDone() {
    _cancelRun();
    stopMic();
    setState(() {
      _phase = _SPhase.done;
      _manual = true;
      _stars = 1;
    });
    widget.onFinished(1);
  }

  void _retry() {
    setState(() {
      _phase = _SPhase.setup;
      _report = null;
      _progression = null;
      _manual = false;
    });
  }

  List<String> _resultLines() {
    if (_manual) return ['Mikrofonla doğrulanmadığı için 1 yıldız verildi.'];
    final r = _report!.result;
    final lines = <String>[
      'Bulunan vuruş: ${r.hit} / ${r.expected}'
          '${r.extraHits > 0 ? '  •  fazladan: ${r.extraHits}' : ''}',
    ];
    if (r.hit > 0) {
      lines.add('Ritim sapman ortalama ${r.jitterMs.round()} ms (40 ms altı çok iyi).');
    }
    if (r.latencyMs > 220) {
      lines.add(
        'Cihaz/kulaklık gecikmen yüksek (~${r.latencyMs.round()} ms). Bluetooth kulaklık '
        'kullanıyorsan telli kulaklık ya da hoparlör dene; ritim puanı gecikmeyi zaten düzeltir.',
      );
    }
    final p = _progression;
    if (p != null) {
      lines.add('Doğru akor çalınan ölçü: ${p.matched} / ${p.bars}');
      for (var b = 0; b < p.bars; b++) {
        final a = p.perBar[b];
        if (a != null && !a.isMatch) {
          lines.add('${b + 1}. ölçü: ${_chords[b % _chords.length].symbol} beklenirdi'
              '${a.best != null && a.best!.id != _chords[b % _chords.length].id ? ', ${a.best!.symbol} duyuldu' : ''}.');
          break;
        }
      }
    }
    if (r.hit < r.expected * 0.5) {
      lines.add('Çok az vuruş algılandı: telefonu gitara yaklaştır, sessiz bir yerde dene, telleri biraz daha sert vur.');
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final running = _phase == _SPhase.running || _phase == _SPhase.preparing;
    final barMs = _session.barMs;
    final inCount = _timelineMs < _session.playStartMs;
    final barIdx = ((_timelineMs - _session.playStartMs) / barMs).floor().clamp(0, _bars - 1);
    final currentChord = _chords[(inCount ? 0 : barIdx) % _chords.length];
    final nextChord = _chords[((inCount ? 0 : barIdx) + 1) % _chords.length];
    final slot = running && !inCount
        ? (((_timelineMs - _session.playStartMs) % barMs) / _session.eighthMs).floor().clamp(0, 7)
        : -1;
    return ListView(
      padding: AppSpacing.screenHV,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChordDiagram(chord: currentChord, width: 130, accent: DesignTokens.green400),
            if (_isProgression) ...[
              const SizedBox(width: AppSpacing.md),
              Opacity(
                opacity: 0.7,
                child: Column(
                  children: [
                    Text('sıradaki', style: t.labelSmall?.copyWith(color: DesignTokens.slate400)),
                    ChordDiagram(chord: nextChord, width: 80),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SlotRow(pattern: _pattern, activeSlot: slot),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            _pattern.description,
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_phase == _SPhase.setup) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                tooltip: 'Yavaşlat',
                onPressed: _bpm > _pattern.minBpm
                    ? () => setState(() => _bpm = (_bpm - 5).clamp(_pattern.minBpm, _pattern.maxBpm))
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    Text('$_bpm',
                        style: t.headlineMedium
                            ?.copyWith(color: DesignTokens.white, fontWeight: FontWeight.w900)),
                    Text('BPM', style: t.labelSmall?.copyWith(color: DesignTokens.slate400)),
                  ],
                ),
              ),
              IconButton.outlined(
                tooltip: 'Hızlandır',
                onPressed: _bpm < _pattern.maxBpm
                    ? () => setState(() => _bpm = (_bpm + 5).clamp(_pattern.minBpm, _pattern.maxBpm))
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '1 ölçü geri sayım + $_bars ölçü. Kulaklık önerilir: metronom mikrofona '
            'karışmaz. Yavaş başla; temiz çalmak hızlı çalmaktan önemli.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: DesignTokens.slate300, height: 1.4),
          ),
          if (micState == MicUiState.denied || micState == MicUiState.unsupported)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: MicProblemNote(state: micState, onRetry: _start),
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Başla'),
          ),
          TextButton(
            onPressed: _manualDone,
            child: const Text('Elle onayla (en fazla 1 yıldız)'),
          ),
        ] else if (running) ...[
          Center(
            child: Text(
              _phase == _SPhase.preparing
                  ? 'Hazırlanıyor…'
                  : (inCount ? 'Geri sayım — dinle' : '${barIdx + 1} / $_bars. ölçü'),
              style: t.titleMedium?.copyWith(
                color: inCount ? DesignTokens.earGold : DesignTokens.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          MicLevelBar(level: micLevel, active: true),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: _retry, child: const Text('Durdur')),
        ] else
          StepResultCard(
            stars: _stars,
            title: _manual
                ? 'Elle onaylandı'
                : switch (_stars) {
                    3 => 'Mükemmel ritim!',
                    2 => 'İyi gidiyor',
                    1 => 'Başlangıç oldu, tekrar dene',
                    _ => 'Pek algılanamadı',
                  },
            lines: _resultLines(),
            onRetry: _retry,
            onContinue: widget.onNext,
          ),
      ],
    );
  }
}

final class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.pattern, required this.activeSlot});

  final StrumPattern pattern;
  final int activeSlot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vuruş kalıbı: ${pattern.name}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < pattern.slots.length; i++)
              Container(
                width: 34,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == activeSlot
                      ? DesignTokens.green400.withValues(alpha: 0.35)
                      : DesignTokens.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: i == activeSlot ? DesignTokens.green400 : DesignTokens.borderSubtle,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  switch (pattern.slots[i]) {
                    StrumSlot.down => Icons.arrow_downward_rounded,
                    StrumSlot.up => Icons.arrow_upward_rounded,
                    StrumSlot.rest => Icons.remove_rounded,
                  },
                  size: 20,
                  color: pattern.slots[i] == StrumSlot.rest
                      ? DesignTokens.slate600
                      : (pattern.slots[i] == StrumSlot.down
                          ? DesignTokens.white
                          : DesignTokens.slate400),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

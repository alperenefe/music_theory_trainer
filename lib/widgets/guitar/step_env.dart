import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../services/mic_audio_session.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'star_row.dart';

/// Metronom parçasını çalan ve konumunu bildiren çalar (testte sahtesi kullanılır).
abstract class StepPlayer {
  /// WAV baytlarını çalar. [positions] çalarken oynatma konumunu yayar.
  Future<void> playWav(Uint8List wav);
  Stream<Duration> get positions;
  Future<void> stop();
  Future<void> dispose();
}

final class AudioplayersStepPlayer implements StepPlayer {
  AudioplayersStepPlayer() : _p = AudioPlayer();

  final AudioPlayer _p;

  @override
  Stream<Duration> get positions => _p.onPositionChanged;

  @override
  Future<void> playWav(Uint8List wav) async {
    await _p.setReleaseMode(ReleaseMode.stop);
    await _p.play(BytesSource(wav, mimeType: 'audio/wav'));
  }

  @override
  Future<void> stop() => _p.stop();

  @override
  Future<void> dispose() => _p.dispose();
}

/// Adım ekranlarının dışarıdan verilen bağımlılıkları (testte değiştirilir).
final class StepEnv {
  const StepEnv({this.micFactory, this.playerFactory});

  final MicAudioSession Function()? micFactory;
  final StepPlayer Function()? playerFactory;

  MicAudioSession mic() => (micFactory ?? MicAudioSession.new)();
  StepPlayer player() => (playerFactory ?? AudioplayersStepPlayer.new)();
}

/// Adım ekranlarının ortak mikrofon durumu.
enum MicUiState { idle, starting, listening, denied, unsupported }

/// Mikrofon seviyesi çubuğu.
final class MicLevelBar extends StatelessWidget {
  const MicLevelBar({super.key, required this.level, required this.active});

  final double level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: active ? 'Mikrofon seviyesi' : 'Mikrofon kapalı',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(
              active ? Icons.mic_rounded : Icons.mic_off_rounded,
              size: 18,
              color: active ? DesignTokens.green400 : DesignTokens.slate500,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: active ? level.clamp(0.0, 1.0) : 0,
                  minHeight: 6,
                  backgroundColor: DesignTokens.slate700,
                  color: level > 0.9 ? DesignTokens.rose400 : DesignTokens.green400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mikrofon açılamadığında / desteklenmediğinde gösterilen açıklama.
final class MicProblemNote extends StatelessWidget {
  const MicProblemNote({super.key, required this.state, this.onRetry});

  final MicUiState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (state) {
      MicUiState.denied => (
          Icons.mic_off_rounded,
          'Mikrofon izni verilmedi. Ayarlardan izin verebilir ya da aşağıdaki '
              '“Elle onayla” düğmesiyle devam edebilirsin (elle onaylı adımlar en fazla 1 yıldız verir).',
        ),
      MicUiState.unsupported => (
          Icons.phone_iphone_rounded,
          'Bu cihaz ham mikrofon sesi vermiyor (şimdilik yalnızca Android). '
              'Adımı “Elle onayla” ile tamamlayabilirsin; en fazla 1 yıldız verir.',
        ),
      _ => (Icons.info_outline_rounded, ''),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: DesignTokens.rose400.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: DesignTokens.rose400.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DesignTokens.rose400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.slate200),
            ),
          ),
          if (onRetry != null && state == MicUiState.denied)
            TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ],
      ),
    );
  }
}

/// Bir adımın sonucu: yıldızlar, başlık, açıklama ve eylemler.
final class StepResultCard extends StatelessWidget {
  const StepResultCard({
    super.key,
    required this.stars,
    required this.title,
    required this.lines,
    required this.onRetry,
    required this.onContinue,
    this.continueLabel = 'Devam',
  });

  final int stars;
  final String title;
  final List<String> lines;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPad,
      decoration: BoxDecoration(
        color: DesignTokens.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: stars > 0 ? DesignTokens.earGold.withValues(alpha: 0.6) : DesignTokens.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          StarRow(stars: stars, size: 40),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(color: DesignTokens.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: DesignTokens.slate300),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(onPressed: onContinue, child: Text(continueLabel)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mikrofon başlatma ve durdurma için ortak mantık.
mixin MicStepMixin<T extends StatefulWidget> on State<T> {
  late final MicAudioSession mic;
  MicUiState micState = MicUiState.idle;
  double micLevel = 0;

  /// Alt sınıf kendi analizörüne ham sesi iletir.
  void onAudio(AudioChunk chunk);

  void initMic(StepEnv env) {
    mic = env.mic();
    mic.attach();
    mic.onStopped = () {
      if (mounted && micState == MicUiState.listening) {
        setState(() => micState = MicUiState.idle);
      }
    };
    mic.onRawAudioUnavailable = () {
      if (mounted && micState != MicUiState.unsupported) {
        mic.stop();
        setState(() => micState = MicUiState.unsupported);
      }
    };
  }

  Future<bool> startMic() async {
    if (micState == MicUiState.starting) return false;
    setState(() => micState = MicUiState.starting);
    final r = await mic.start(onChunk: (c) {
      if (!mounted) return;
      onAudio(c);
    });
    if (!mounted) return false;
    switch (r) {
      case MicStartResult.started:
        setState(() => micState = MicUiState.listening);
        return true;
      case MicStartResult.permissionDenied:
        setState(() => micState = MicUiState.denied);
        return false;
      case MicStartResult.rawAudioUnavailable:
        setState(() => micState = MicUiState.unsupported);
        return false;
    }
  }

  void stopMic() => mic.stop();

  void disposeMic() {
    mic.onStopped = null;
    mic.detach();
  }
}

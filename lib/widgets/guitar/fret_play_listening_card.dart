import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';
import '../tuner/tuner_gauge_painter.dart';

final class FretPlayListeningCard extends StatelessWidget {
  const FretPlayListeningCard({
    super.key,
    required this.textTheme,
    required this.listening,
    required this.feedback,
    required this.lastNoteName,
    required this.lastHz,
    required this.cents,
    required this.onToggleMic,
  });

  final TextTheme textTheme;
  final bool listening;
  final bool feedback;
  final String? lastNoteName;
  final double? lastHz;
  final double? cents;
  final VoidCallback? onToggleMic;

  String _centsLabel(double? c) {
    if (c == null) {
      return '—';
    }
    final v = c.round();
    if (v.abs() <= 8) {
      return AppStrings.tunerInTune;
    }
    if (v < 0) {
      return '${v.abs()} ${AppStrings.tunerFlat}';
    }
    return '$v ${AppStrings.tunerSharp}';
  }

  @override
  Widget build(BuildContext context) {
    final t = textTheme;
    final hasPitch = lastHz != null && lastNoteName != null;
    final gaugeCents = cents ?? 0;
    final inTune = cents != null && cents!.abs() <= 8;

    return SoftCard(
      padding: AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.guitarPlayMicHint,
            style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            listening ? AppStrings.tunerMicActive : AppStrings.guitarPlayIdle,
            style: t.titleSmall?.copyWith(
              color: listening ? DesignTokens.green400 : DesignTokens.slate300,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: TunerGaugePainter(cents: hasPitch ? gaugeCents : 0),
              child: const SizedBox.expand(),
            ),
          ),
          if (inTune) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.guitarPlayInTuneHint,
              textAlign: TextAlign.center,
              style: t.labelMedium?.copyWith(
                color: DesignTokens.green400,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            hasPitch
                ? '${AppStrings.guitarPlayDetected}: '
                      '$lastNoteName · '
                      '${lastHz!.toStringAsFixed(0)} Hz'
                : '—',
            style: t.headlineSmall?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${AppStrings.tunerCents}: ${_centsLabel(cents)}',
            style: t.titleMedium?.copyWith(
              color: hasPitch ? DesignTokens.slate200 : DesignTokens.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonalIcon(
            onPressed: feedback ? null : onToggleMic,
            icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
            label: Text(
              listening ? AppStrings.guitarPlayStop : AppStrings.tunerMicResume,
            ),
          ),
        ],
      ),
    );
  }
}

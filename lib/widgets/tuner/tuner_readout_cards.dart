import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/guitar_note.dart';
import '../../models/practice_prefs.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

String tunerCentsLine(double? cents) {
  if (cents == null) {
    return '${AppStrings.tunerCents}: —';
  }
  final sign = cents >= 0 ? '+' : '';
  final label = '$sign${cents.toStringAsFixed(1)}';
  if (cents.abs() <= 8) {
    return '${AppStrings.tunerCents}: $label · ${AppStrings.tunerInTune}';
  }
  final word = cents > 0 ? AppStrings.tunerSharp : AppStrings.tunerFlat;
  return '${AppStrings.tunerCents}: $label · $word';
}

final class TunerReadingsCard extends StatelessWidget {
  const TunerReadingsCard({
    super.key,
    required this.textTheme,
    required this.listening,
    required this.openNote,
    required this.displayHz,
    required this.activeTargetHz,
    required this.activeTargetMidi,
    required this.cents,
    required this.onPlayReference,
    required this.onStartMic,
    required this.onStopMic,
  });

  final TextTheme textTheme;
  final bool listening;
  final GuitarNote openNote;
  final double? displayHz;
  final double? activeTargetHz;
  final int? activeTargetMidi;
  final double? cents;
  final VoidCallback onPlayReference;
  final VoidCallback onStartMic;
  final VoidCallback onStopMic;

  @override
  Widget build(BuildContext context) {
    final t = textTheme;
    return SoftCard(
      padding: AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.tunerStringLine,
                style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
              ),
              Flexible(
                child: Text(
                  listening && displayHz != null
                      ? '${openNote.openStringName} (${openNote.stringLabel})'
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
                style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
              ),
              Flexible(
                child: Text(
                  activeTargetHz != null && activeTargetMidi != null
                      ? '${activeTargetHz!.toStringAsFixed(1)} Hz · '
                            '${GuitarNote.noteNameForMidi(activeTargetMidi!)}'
                      : activeTargetHz != null
                      ? '${activeTargetHz!.toStringAsFixed(1)} Hz'
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
                style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
              ),
              Text(
                displayHz != null ? '${displayHz!.toStringAsFixed(1)} Hz' : '—',
                style: t.titleMedium?.copyWith(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tunerCentsLine(cents),
            textAlign: TextAlign.center,
            style: t.headlineSmall?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonalIcon(
            onPressed: onPlayReference,
            icon: const Icon(Icons.graphic_eq_rounded),
            label: Text(AppStrings.tunerPlayRef),
          ),
          if (!listening) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: onStartMic,
              icon: const Icon(Icons.mic_rounded),
              label: Text(AppStrings.tunerMicResume),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: onStopMic,
              icon: const Icon(Icons.stop_rounded),
              label: Text(AppStrings.guitarPlayStop),
            ),
          ],
        ],
      ),
    );
  }
}

final class TunerReferenceSliderCard extends StatelessWidget {
  const TunerReferenceSliderCard({
    super.key,
    required this.textTheme,
    required this.prefs,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
  });

  final TextTheme textTheme;
  final PracticePrefs prefs;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double> onSliderChangeEnd;

  @override
  Widget build(BuildContext context) {
    final t = textTheme;
    return SoftCard(
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
            value: prefs.referenceA4Hz.clamp(415, 455),
            label: prefs.referenceA4Hz.toStringAsFixed(1),
            onChanged: onSliderChanged,
            onChangeEnd: onSliderChangeEnd,
          ),
          Text(
            '${prefs.referenceA4Hz.toStringAsFixed(1)} Hz',
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../models/guitar_path.dart';
import '../../../screens/guitar_tuner_screen.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/design_tokens.dart';
import '../chord_diagram.dart';

/// Okunacak kartlar (info) ve akort adımı (tuner).
final class InfoStepView extends StatelessWidget {
  const InfoStepView({
    super.key,
    required this.step,
    required this.onFinished,
    required this.onNext,
  });

  final GuitarStep step;
  final void Function(int stars) onFinished;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isTuner = step.kind == GuitarStepKind.tuner;
    return ListView(
      padding: AppSpacing.screenHV,
      children: [
        if (step.chordIds.isNotEmpty) ...[
          Center(
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              alignment: WrapAlignment.center,
              children: [
                for (final c in step.chords)
                  ChordDiagram(chord: c, width: step.chordIds.length > 2 ? 96 : 130),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final b in step.blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: AppSpacing.cardPadDense,
              decoration: BoxDecoration(
                color: DesignTokens.cardBg,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: DesignTokens.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.heading,
                    style: t.titleSmall?.copyWith(
                      color: DesignTokens.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.body,
                    style: t.bodyMedium?.copyWith(color: DesignTokens.slate300, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        if (isTuner) ...[
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const GuitarTunerScreen()),
            ),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Akort cihazını aç'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        FilledButton(
          onPressed: () {
            onFinished(1);
            onNext();
          },
          child: Text(isTuner ? 'Akort ettim' : 'Okudum, devam'),
        ),
      ],
    );
  }
}

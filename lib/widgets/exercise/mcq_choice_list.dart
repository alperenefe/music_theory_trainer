import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class McqChoiceList extends StatelessWidget {
  const McqChoiceList({
    super.key,
    required this.options,
    required this.correctLabel,
    required this.feedback,
    required this.picked,
    required this.onPick,
  });

  final List<String> options;
  final String correctLabel;
  final bool feedback;
  final String? picked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 92,
      ),
      itemCount: options.length,
      itemBuilder: (context, i) => _McqChoiceTile(
        label: options[i],
        correctLabel: correctLabel,
        feedback: feedback,
        picked: picked,
        onPick: onPick,
      ),
    );
  }
}

final class _McqChoiceTile extends StatelessWidget {
  const _McqChoiceTile({
    required this.label,
    required this.correctLabel,
    required this.feedback,
    required this.picked,
    required this.onPick,
  });

  final String label;
  final String correctLabel;
  final bool feedback;
  final String? picked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isPicked = picked == label;
    final showOk = feedback && label == correctLabel;
    final showBad = feedback && isPicked && label != correctLabel;
    var border = DesignTokens.borderSubtle;
    var bg = DesignTokens.slate900.withValues(alpha: 0.35);
    if (showOk) {
      border = DesignTokens.green400.withValues(alpha: 0.55);
      bg = DesignTokens.green400.withValues(alpha: 0.12);
    } else if (showBad) {
      border = DesignTokens.rose400.withValues(alpha: 0.55);
      bg = DesignTokens.rose400.withValues(alpha: 0.12);
    } else if (isPicked && !feedback) {
      border = DesignTokens.blue500;
    }
    return Semantics(
      button: true,
      label: 'Şık: $label',
      selected: isPicked,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: feedback ? null : () => onPick(label),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              color: bg,
              border: Border.all(color: border),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: t.titleSmall?.copyWith(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

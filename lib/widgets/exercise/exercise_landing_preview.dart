import 'package:flutter/material.dart';

import '../../config/goal_kind.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

/// Landing'de egzersiz türüne göre görsel önizleme.
final class ExerciseLandingPreview extends StatelessWidget {
  const ExerciseLandingPreview({
    super.key,
    required this.goalKind,
    this.compact = false,
  });

  final String? goalKind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final previewH = compact ? 52.0 : 72.0;
    return SoftCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact)
            Text(
              AppStrings.landingPreviewTitle,
              style: t.labelMedium?.copyWith(
                color: DesignTokens.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (!compact) const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: previewH,
            child: Center(child: _PreviewBody(kind: goalKind)),
          ),
        ],
      ),
    );
  }
}

final class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.kind});

  final String? kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      GoalKind.interval => const _IntervalPreview(),
      GoalKind.chord => const _ChordPreview(),
      GoalKind.scale => const _ScalePreview(),
      _ => const _StaffPairPreview(),
    };
  }
}

final class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.label, this.accent = DesignTokens.blue500});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: DesignTokens.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

final class _StaffPairPreview extends StatelessWidget {
  const _StaffPairPreview();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NoteBubble(label: 'Do', accent: DesignTokens.blue500),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(Icons.arrow_forward_rounded, color: DesignTokens.slate500),
        ),
        _NoteBubble(label: '?', accent: DesignTokens.violet400),
      ],
    );
  }
}

final class _IntervalPreview extends StatelessWidget {
  const _IntervalPreview();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _NoteBubble(label: 'Do', accent: DesignTokens.green400),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.slate800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '3',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: DesignTokens.tunerCyan,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const _NoteBubble(label: 'Mi', accent: DesignTokens.green400),
      ],
    );
  }
}

final class _ChordPreview extends StatelessWidget {
  const _ChordPreview();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NoteBubble(label: 'Do', accent: DesignTokens.violet400),
        SizedBox(width: AppSpacing.xs),
        _NoteBubble(label: 'Mi', accent: DesignTokens.violet400),
        SizedBox(width: AppSpacing.xs),
        _NoteBubble(label: 'Sol', accent: DesignTokens.violet400),
      ],
    );
  }
}

final class _ScalePreview extends StatelessWidget {
  const _ScalePreview();

  @override
  Widget build(BuildContext context) {
    const steps = ['Do', 'Re', 'Mi', 'Fa'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.only(bottom: 12, left: 2, right: 2),
              child: Icon(
                Icons.north_east_rounded,
                size: 14,
                color: DesignTokens.slate600,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: i * 6.0),
            child: _NoteBubble(
              label: steps[i],
              accent: DesignTokens.tunerCyan,
            ),
          ),
        ],
      ],
    );
  }
}

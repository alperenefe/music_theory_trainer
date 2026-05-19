import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

/// Hedef MIDI aralığında hiç perde yoksa gösterilir.
final class GuitarRangeEmptyBody extends StatelessWidget {
  const GuitarRangeEmptyBody({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: AppSpacing.screenHV,
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 48,
                color: DesignTokens.slate500,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.guitarRangeEmptyTitle,
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.guitarRangeEmptyBody,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(
                  color: DesignTokens.slate400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.guitarRangeEmptyBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

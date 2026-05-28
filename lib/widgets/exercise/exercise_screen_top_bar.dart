import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class ExerciseScreenTopBar extends StatelessWidget {
  const ExerciseScreenTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.modeLabel,
    this.sessionCorrect,
    this.sessionTotal,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? modeLabel;
  final int? sessionCorrect;
  final int? sessionTotal;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final showScore =
        sessionCorrect != null &&
        sessionTotal != null &&
        sessionTotal! > 0;
    return Padding(
      padding: AppSpacing.screenH.copyWith(top: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: DesignTokens.slate200,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: t.titleLarge?.copyWith(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(
                      color: DesignTokens.slate400,
                      height: 1.35,
                    ),
                  ),
                if (modeLabel != null && modeLabel!.isNotEmpty)
                  Text(
                    modeLabel!,
                    style: t.labelSmall?.copyWith(
                      color: DesignTokens.slate500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (showScore) ...[
            if (trailing != null) const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.slate800.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DesignTokens.borderSubtle),
              ),
              child: Text(
                AppStrings.sessionScore(sessionCorrect!, sessionTotal!),
                style: t.labelMedium?.copyWith(
                  color: DesignTokens.green400,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

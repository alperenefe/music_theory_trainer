import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

/// Boş veri durumları için tutarlı illüstrasyon + metin.
final class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  factory AppEmptyState.noData({Widget? action}) => AppEmptyState(
        icon: Icons.insights_outlined,
        title: AppStrings.noData,
        subtitle: AppStrings.emptyStateHint,
        action: action,
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SoftCard(
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  DesignTokens.blue500.withValues(alpha: 0.22),
                  DesignTokens.violet500.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Icon(icon, size: 44, color: DesignTokens.slate300),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.titleSmall?.copyWith(
              color: DesignTokens.slate200,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(
                color: DesignTokens.slate500,
                height: 1.45,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

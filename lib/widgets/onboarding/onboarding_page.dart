import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.body,
    required this.textTheme,
  });

  final String title;
  final String body;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final t = textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: t.titleLarge?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          body,
          style: t.bodyMedium?.copyWith(
            color: DesignTokens.slate400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

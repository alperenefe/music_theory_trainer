import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.body,
    required this.textTheme,
    required this.icon,
    this.gradientColors = const [
      DesignTokens.blue500,
      DesignTokens.violet500,
    ],
  });

  final String title;
  final String body;
  final TextTheme textTheme;
  final IconData icon;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final t = textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, size: 56, color: DesignTokens.white),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: t.titleLarge?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          body,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(
            color: DesignTokens.slate400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

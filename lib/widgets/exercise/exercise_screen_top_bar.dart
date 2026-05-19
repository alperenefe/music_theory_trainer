import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class ExerciseScreenTopBar extends StatelessWidget {
  const ExerciseScreenTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
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
            child: Text(
              title,
              style: t.titleLarge?.copyWith(
                color: DesignTokens.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// 0–3 yıldız.
final class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 18, this.max = 3});

  final int stars;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars / $max yıldız',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < max; i++)
              Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i < stars ? DesignTokens.earGold : DesignTokens.slate600,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

final class MeshGradientBackdrop extends StatelessWidget {
  const MeshGradientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [
                      DesignTokens.slate950,
                      const Color(0xFF0B1224),
                      DesignTokens.slate900,
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFEFF6FF),
                      const Color(0xFFF1F5F9),
                    ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.85, -0.9),
              radius: 1.1,
              colors: [
                DesignTokens.violet500.withValues(alpha: dark ? 0.18 : 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.0, 0.2),
              radius: 1.0,
              colors: [
                DesignTokens.blue600.withValues(alpha: dark ? 0.14 : 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

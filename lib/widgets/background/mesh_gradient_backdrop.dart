import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

final class MeshGradientBackdrop extends StatelessWidget {
  const MeshGradientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.slate950,
                const Color(0xFF0B1224),
                DesignTokens.slate900,
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
                DesignTokens.violet500.withValues(alpha: 0.18),
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
                DesignTokens.blue600.withValues(alpha: 0.14),
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

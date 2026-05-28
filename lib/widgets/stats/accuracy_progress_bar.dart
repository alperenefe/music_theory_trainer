import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// Doğruluk oranı (0–1) için yatay çubuk; ana sayfa + istatistik özeti.
final class AccuracyProgressBar extends StatelessWidget {
  const AccuracyProgressBar({
    super.key,
    required this.accuracy,
    this.height = 8,
    this.useGradient = true,
  });

  final double accuracy;
  final double height;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final v = accuracy.clamp(0.0, 1.0);
    final bar = LinearProgressIndicator(
      value: v,
      minHeight: height,
      backgroundColor: DesignTokens.slate800,
      color: useGradient ? DesignTokens.white : _barColor(v),
      borderRadius: BorderRadius.circular(6),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: useGradient && v > 0
          ? ShaderMask(
              shaderCallback: (bounds) =>
                  DesignTokens.statsProgressGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              blendMode: BlendMode.srcIn,
              child: bar,
            )
          : bar,
    );
  }

  static Color _barColor(double v) {
    if (v >= 0.8) {
      return DesignTokens.green400;
    }
    if (v >= 0.5) {
      return DesignTokens.streakOrange;
    }
    return DesignTokens.rose400;
  }
}

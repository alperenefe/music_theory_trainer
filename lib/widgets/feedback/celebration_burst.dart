import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/design_tokens.dart';

/// Hedef tamamlanınca kısa konfeti benzeri parçacıklar (Duolingo dopamin).
final class CelebrationBurst extends StatelessWidget {
  const CelebrationBurst({super.key});

  static const _colors = [
    DesignTokens.green400,
    DesignTokens.violet400,
    DesignTokens.blue500,
    DesignTokens.streakOrange,
    DesignTokens.rose400,
  ];

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Icon(
            Icons.celebration_rounded,
            size: 48,
            color: DesignTokens.green400,
          ),
        ),
      );
    }
    final rnd = Random(7);
    return SizedBox(
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 18; i++)
            _Particle(
              color: _colors[i % _colors.length],
              dx: (rnd.nextDouble() - 0.5) * 220,
              dy: -40 - rnd.nextDouble() * 70,
              delay: (30 * i).ms,
              size: 6 + rnd.nextDouble() * 6,
            ),
        ],
      ),
    );
  }
}

final class _Particle extends StatelessWidget {
  const _Particle({
    required this.color,
    required this.dx,
    required this.dy,
    required this.delay,
    required this.size,
  });

  final Color color;
  final double dx;
  final double dy;
  final Duration delay;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    )
        .animate()
        .fadeIn(duration: 160.ms, delay: delay)
        .moveY(
          begin: 24,
          end: dy,
          duration: 820.ms,
          delay: delay,
          curve: Curves.easeOutCubic,
        )
        .moveX(
          begin: 0,
          end: dx,
          duration: 820.ms,
          delay: delay,
          curve: Curves.easeOut,
        )
        .scale(
          begin: const Offset(0.35, 0.35),
          end: const Offset(1, 1),
          duration: 280.ms,
          delay: delay,
        )
        .then(delay: 500.ms)
        .fadeOut(duration: 320.ms);
  }
}

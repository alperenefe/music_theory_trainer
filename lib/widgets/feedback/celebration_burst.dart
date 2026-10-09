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
    // Sabit seed (Random(7)) her kutlamada BİREBİR AYNI patlama desenini
    // oynatıyordu — ikinci hedef tamamlamadan sonra "wow" etkisini
    // kaybediyordu. Gerçek rastgelelik + parça çeşitliliği (kare/daire,
    // dönme) ile her kutlama farklı hissettiriyor.
    final rnd = Random();
    return SizedBox(
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 24; i++)
            _Particle(
              color: _colors[i % _colors.length],
              dx: (rnd.nextDouble() - 0.5) * 280,
              dy: -60 - rnd.nextDouble() * 100,
              delay: (25 * i).ms,
              size: 6 + rnd.nextDouble() * 7,
              round: rnd.nextBool(),
              turns: (rnd.nextDouble() - 0.5) * 1.4,
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
    required this.round,
    required this.turns,
  });

  final Color color;
  final double dx;
  final double dy;
  final Duration delay;
  final double size;

  /// true: daire konfeti, false: köşeli şerit — tek tip karelerden farklı,
  /// gerçek bir konfeti karışımı hissi verir.
  final bool round;

  /// Düşerken dönme miktarı (tur cinsinden), yön ve hız parçadan parçaya değişir.
  final double turns;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: round ? size : size * 1.6,
      height: round ? size : size * 0.6,
      decoration: BoxDecoration(
        color: color,
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(2),
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
        .rotate(begin: 0, end: turns, duration: 820.ms, delay: delay)
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

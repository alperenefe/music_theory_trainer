import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

final class TunerGaugePainter extends CustomPainter {
  TunerGaugePainter({
    required this.cents,
    this.listening = false,
  });

  final double cents;
  final bool listening;

  static const double _needleLen = 0.72;

  double _angleForCents(double c) {
    return -math.pi / 2 + (c / 50) * (math.pi / 2);
  }

  Color _needleColor(double c) {
    final a = c.abs();
    if (a <= 5) {
      return DesignTokens.green400;
    }
    if (a <= 15) {
      return DesignTokens.tunerCyan;
    }
    return DesignTokens.rose400;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.92;
    final r = math.min(size.width, size.height) * 0.42;
    final c = Offset(cx, cy);
    final arcRect = Rect.fromCircle(center: c, radius: r);

    if (listening) {
      final glow = Paint()
        ..color = DesignTokens.green400.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(c, 22, glow);
    }

    final track = Paint()
      ..color = DesignTokens.slate700.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi, math.pi, false, track);

    final okSpan = (5 / 50) * (math.pi / 2);
    final okZone = Paint()
      ..color = DesignTokens.green400.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi / 2 - okSpan, 2 * okSpan, false, okZone);

    final cyanSpan = (15 / 50) * (math.pi / 2);
    final cyanZone = Paint()
      ..color = DesignTokens.tunerCyan.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arcRect,
      -math.pi / 2 - cyanSpan,
      2 * cyanSpan,
      false,
      cyanZone,
    );

    for (var i = -5; i <= 5; i++) {
      final m = (i * 10).toDouble();
      final a = _angleForCents(m);
      final center = i == 0;
      final tick = Paint()
        ..color = center
            ? DesignTokens.green400
            : DesignTokens.slate500.withValues(alpha: 0.85)
        ..strokeWidth = center ? 3.5 : 2;
      final innerR = center ? r - 6 : r - 4;
      final outerR = center ? r + 14 : r + 10;
      final iPt = Offset(cx + innerR * math.cos(a), cy + innerR * math.sin(a));
      final oPt = Offset(cx + outerR * math.cos(a), cy + outerR * math.sin(a));
      canvas.drawLine(iPt, oPt, tick);
    }

    final cl = cents.clamp(-50.0, 50.0);
    final a = _angleForCents(cl);
    final needlePaint = Paint()
      ..color = _needleColor(cl)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final tip = Offset(
      cx + r * _needleLen * math.cos(a),
      cy + r * _needleLen * math.sin(a),
    );
    canvas.drawLine(c, tip, needlePaint);
    canvas.drawCircle(c, 10, Paint()..color = DesignTokens.slate800);
    canvas.drawCircle(
      c,
      10,
      Paint()
        ..color = DesignTokens.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant TunerGaugePainter oldDelegate) =>
      oldDelegate.cents != cents || oldDelegate.listening != listening;
}

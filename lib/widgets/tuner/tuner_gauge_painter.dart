import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

final class TunerGaugePainter extends CustomPainter {
  TunerGaugePainter({required this.cents});

  final double cents;

  static const double _needleLen = 0.72;

  double _angleForCents(double c) {
    return -math.pi / 2 + (c / 50) * (math.pi / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.92;
    final r = math.min(size.width, size.height) * 0.42;
    final c = Offset(cx, cy);
    final arcRect = Rect.fromCircle(center: c, radius: r);

    final track = Paint()
      ..color = DesignTokens.slate700.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi, math.pi, false, track);

    final okSpan = (8 / 50) * (math.pi / 2);
    final okZone = Paint()
      ..color = DesignTokens.green400.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arcRect,
      -math.pi / 2 - okSpan,
      2 * okSpan,
      false,
      okZone,
    );

    final tick = Paint()
      ..color = DesignTokens.slate500
      ..strokeWidth = 2;
    for (final m in [-50, -25, 0, 25, 50]) {
      final a = _angleForCents(m.toDouble());
      final i = Offset(cx + (r - 4) * math.cos(a), cy + (r - 4) * math.sin(a));
      final o = Offset(cx + (r + 10) * math.cos(a), cy + (r + 10) * math.sin(a));
      canvas.drawLine(i, o, tick);
    }

    final cl = cents.clamp(-50.0, 50.0);
    final a = _angleForCents(cl);
    final needlePaint = Paint()
      ..color = cl.abs() <= 8
          ? DesignTokens.green400
          : (cl > 0 ? const Color(0xFFF97316) : DesignTokens.blue500)
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
      oldDelegate.cents != cents;
}

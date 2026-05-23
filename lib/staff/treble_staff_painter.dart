import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'staff_geometry.dart';

enum StaffNoteFeedbackKind { normal, wrongPick, correctTarget }

final class TrebleStaffNoteSpec {
  const TrebleStaffNoteSpec({
    required this.slot,
    this.feedback = StaffNoteFeedbackKind.normal,
  });

  final int slot;
  final StaffNoteFeedbackKind feedback;
}

final class TrebleStaffPainter extends CustomPainter {
  TrebleStaffPainter({
    required this.geometry,
    required this.notes,
    this.ledgerSlots = const [],
    this.highlightSlot,
    this.wrongHighlightSlot,
    this.correctHighlightSlot,
  });

  final StaffGeometry geometry;
  final List<TrebleStaffNoteSpec> notes;
  final List<int> ledgerSlots;
  final int? highlightSlot;
  final int? wrongHighlightSlot;
  final int? correctHighlightSlot;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = DesignTokens.slate400.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    for (final y in geometry.mainLineYs()) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final ledgerPaint = Paint()
      ..color = DesignTokens.slate400.withValues(alpha: 0.48)
      ..strokeWidth = 1.15;
    _drawLedgers(canvas, ledgerPaint);
    _drawClef(canvas);
    for (final n in notes) {
      _drawNote(canvas, n);
    }
    if (highlightSlot != null) {
      _drawHighlight(canvas, highlightSlot!, DesignTokens.blue600);
    }
    if (wrongHighlightSlot != null) {
      _drawHighlight(canvas, wrongHighlightSlot!, DesignTokens.rose400);
    }
    if (correctHighlightSlot != null) {
      _drawHighlight(canvas, correctHighlightSlot!, DesignTokens.green400);
    }
  }

  void _drawLedgers(Canvas canvas, Paint ledgerPaint) {
    final lx0 = geometry.noteHeadX - 20;
    final lx1 = geometry.noteHeadX + 20;
    final slots = <int>{...ledgerSlots};
    for (final n in notes) {
      final s = n.slot;
      if (s < 0 && s.isEven) {
        slots.add(s);
      } else if (s > 8 && s.isEven) {
        slots.add(s);
      }
    }
    for (final s in slots) {
      if (s < 0 || (s > 8 && s.isEven)) {
        final y = geometry.yForSlot(s);
        _drawDashedHLine(canvas, y, lx0, lx1, ledgerPaint);
      }
    }
  }

  static const double _ledgerDash = 5;
  static const double _ledgerGap = 3.5;

  void _drawDashedHLine(
    Canvas canvas,
    double y,
    double x0,
    double x1,
    Paint paint,
  ) {
    var a = x0 < x1 ? x0 : x1;
    final b = x0 < x1 ? x1 : x0;
    while (a < b) {
      final segEnd = a + _ledgerDash;
      canvas.drawLine(Offset(a, y), Offset(segEnd > b ? b : segEnd, y), paint);
      a = segEnd + _ledgerGap;
    }
  }

  void _drawClef(Canvas canvas) {
    final fontSize = geometry.clefFontSize;
    final tp = TextPainter(
      text: TextSpan(
        text: '𝄞',
        style: TextStyle(
          color: DesignTokens.slate200,
          fontSize: fontSize,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final anchorY = (geometry.yForSlot(0) + geometry.yForSlot(8)) / 2;
    tp.paint(
      canvas,
      Offset(geometry.clefX, anchorY - tp.height * 0.5),
    );
  }

  void _drawNote(Canvas canvas, TrebleStaffNoteSpec n) {
    final cx = geometry.noteHeadX;
    final cy = geometry.yForSlot(n.slot);
    final oval = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 15));
    final Color fillColor;
    final Color strokeColor;
    switch (n.feedback) {
      case StaffNoteFeedbackKind.normal:
        fillColor = DesignTokens.white;
        strokeColor = DesignTokens.slate900;
      case StaffNoteFeedbackKind.wrongPick:
        fillColor = DesignTokens.rose400.withValues(alpha: 0.92);
        strokeColor = DesignTokens.rose400;
      case StaffNoteFeedbackKind.correctTarget:
        fillColor = DesignTokens.green400.withValues(alpha: 0.92);
        strokeColor = DesignTokens.green400;
    }
    final fill = Paint()..color = fillColor;
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(oval, fill);
    canvas.drawPath(oval, stroke);
  }

  void _drawHighlight(Canvas canvas, int slot, Color color) {
    final y = geometry.yForSlot(slot);
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(geometry.noteHeadX, y),
        width: 36,
        height: 28,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      r,
      Paint()..color = color.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant TrebleStaffPainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.notes != notes ||
        oldDelegate.ledgerSlots != ledgerSlots ||
        oldDelegate.highlightSlot != highlightSlot ||
        oldDelegate.wrongHighlightSlot != wrongHighlightSlot ||
        oldDelegate.correctHighlightSlot != correctHighlightSlot;
  }
}

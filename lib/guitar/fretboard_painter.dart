import 'package:flutter/material.dart';

import '../../models/guitar_note.dart';
import '../../theme/design_tokens.dart';

final class FretboardCellState {
  const FretboardCellState({
    this.highlighted = false,
    this.selected = false,
    this.correct = false,
    this.incorrect = false,
  });
  final bool highlighted;
  final bool selected;
  final bool correct;
  final bool incorrect;
}

final class FretboardPainter extends CustomPainter {
  FretboardPainter({
    required this.cellStates,
    this.minFret = 0,
    this.maxFret = 7,
  });

  final Map<GuitarNote, FretboardCellState> cellStates;
  final int minFret;
  final int maxFret;

  static const openStringLeft = 6.0;
  static const nutX = 38.0;
  static const fingerboardRightPad = 4.0;
  static const boardTopPad = 22.0;
  static const boardBottomPad = 10.0;

  double _fingerboardEnd(Size size) => size.width - fingerboardRightPad;

  double _fretW(Size size) {
    if (minFret != 0) {
      return (_fingerboardEnd(size) - nutX) / (maxFret - minFret + 1);
    }
    final n = maxFret - minFret;
    if (n <= 0) return 1;
    return (_fingerboardEnd(size) - nutX) / n;
  }

  double _strH(Size size) => (size.height - boardTopPad - boardBottomPad) / 5;

  double _xForFret(Size size, int fret) {
    if (minFret == 0 && fret == 0) {
      return (openStringLeft + nutX) / 2;
    }
    if (minFret == 0 && fret >= 1) {
      final fw = _fretW(size);
      return nutX + (fret - 0.5) * fw;
    }
    final fw = _fretW(size);
    return nutX + (fret - minFret) * fw + fw / 2;
  }

  double _yForString(Size size, int string) =>
      boardTopPad + string * _strH(size);

  Offset cellCenter(Size size, GuitarNote note) =>
      Offset(_xForFret(size, note.fret), _yForString(size, note.string));

  @override
  void paint(Canvas canvas, Size size) {
    final fw = _fretW(size);
    final sh = _strH(size);

    // --- Background ---
    final bgPaint = Paint()..color = const Color(0xFF1A1108);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bgPaint,
    );

    // --- Fret lines (vertical) ---
    final fretPaint = Paint()
      ..color = const Color(0xFFC9A06A).withValues(alpha: 0.58)
      ..strokeWidth = 1.05;
    final nutPaint = Paint()
      ..color = const Color(0xFFE8C78A)
      ..strokeWidth = 4.5;

    final yTop = boardTopPad;
    final yBot = boardTopPad + 5 * sh;

    if (minFret == 0) {
      canvas.drawLine(Offset(nutX, yTop), Offset(nutX, yBot), nutPaint);
      for (var j = 1; j <= maxFret; j++) {
        final x = nutX + j * fw;
        canvas.drawLine(Offset(x, yTop), Offset(x, yBot), fretPaint);
      }
    } else {
      for (var f = minFret; f <= maxFret + 1; f++) {
        final x = nutX + (f - minFret) * fw;
        final paint = (f == minFret && minFret > 0) ? nutPaint : fretPaint;
        canvas.drawLine(Offset(x, yTop), Offset(x, yBot), paint);
      }
    }

    // --- String lines (horizontal) ---
    final thicknesses = [0.8, 1.0, 1.2, 1.6, 1.9, 2.3]; // high to low
    for (var s = 0; s < 6; s++) {
      final y = _yForString(size, s);
      final sp = Paint()
        ..color = const Color(0xFFD8BE78).withValues(alpha: 0.9)
        ..strokeWidth = thicknesses[s];
      canvas.drawLine(Offset(nutX, y), Offset(_fingerboardEnd(size), y), sp);

      // Open string area line
      final openSp = Paint()
        ..color = const Color(0xFFCCB266).withValues(alpha: 0.4)
        ..strokeWidth = thicknesses[s];
      canvas.drawLine(Offset(openStringLeft, y), Offset(nutX, y), openSp);
    }

    // --- Position dots ---
    const markerFrets = [3, 5, 7];
    final dotPaint = Paint()..color = const Color(0xFF4A3820);
    for (final mf in markerFrets) {
      if (mf < minFret || mf > maxFret) continue;
      final x = _xForFret(size, mf);
      final y = _yForString(size, 2) + sh / 2;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    // --- Fret numbers ---
    for (var f = minFret; f <= maxFret; f++) {
      final x = _xForFret(size, f);
      _drawText(
        canvas,
        f == 0 ? 'O' : '$f',
        Offset(x, boardTopPad / 2),
        const TextStyle(
          color: Color(0xFF8A7050),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // --- String labels (right side) ---
    const labels = ['e', 'B', 'G', 'D', 'A', 'E'];
    for (var s = 0; s < 6; s++) {
      final y = _yForString(size, s);
      _drawText(
        canvas,
        labels[s],
        Offset(14, y),
        const TextStyle(
          color: Color(0xFF8A7050),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    // --- Cell states ---
    final noteRadius = (fw * 0.34).clamp(8.0, 18.0);
    for (final entry in cellStates.entries) {
      final note = entry.key;
      final state = entry.value;
      final center = cellCenter(size, note);
      _drawCell(canvas, center, noteRadius, state);
    }
  }

  void _drawCell(
    Canvas canvas,
    Offset center,
    double r,
    FretboardCellState state,
  ) {
    if (!state.highlighted &&
        !state.selected &&
        !state.correct &&
        !state.incorrect) {
      return;
    }

    Color fill;
    Color border;

    if (state.correct) {
      fill = DesignTokens.green400.withValues(alpha: 0.85);
      border = DesignTokens.green400;
    } else if (state.incorrect) {
      fill = DesignTokens.rose400.withValues(alpha: 0.85);
      border = DesignTokens.rose400;
    } else if (state.highlighted) {
      fill = DesignTokens.blue600.withValues(alpha: 0.9);
      border = DesignTokens.blue500;
    } else {
      fill = DesignTokens.blue500.withValues(alpha: 0.5);
      border = DesignTokens.blue500;
    }

    canvas.drawCircle(center, r, Paint()..color = fill);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant FretboardPainter old) =>
      old.cellStates != cellStates ||
      old.minFret != minFret ||
      old.maxFret != maxFret;
}

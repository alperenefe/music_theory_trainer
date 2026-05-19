import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/guitar_note.dart';
import 'fretboard_painter.dart';

final class FretboardWidget extends StatefulWidget {
  const FretboardWidget({
    super.key,
    required this.cellStates,
    required this.onCellTap,
    this.minFret = 0,
    this.maxFret = 7,
    this.height = 200,
  });

  final Map<GuitarNote, FretboardCellState> cellStates;
  final void Function(GuitarNote note) onCellTap;
  final int minFret;
  final int maxFret;
  final double height;

  /// Dokunma → tel/perde (CustomPaint ile aynı geometri).
  @visibleForTesting
  static GuitarNote? hitTestAt(
    Offset pos,
    Size size, {
    int minFret = 0,
    int maxFret = 7,
  }) {
    const openLeft = FretboardPainter.openStringLeft;
    const openW = FretboardPainter.nutX;
    const rightPad = FretboardPainter.fingerboardRightPad;
    const topPad = FretboardPainter.boardTopPad;
    const botPad = FretboardPainter.boardBottomPad;
    final endX = size.width - rightPad;
    final sh = (size.height - topPad - botPad) / 5;

    if (pos.dx < openLeft - 8 || pos.dx > endX + 2) return null;

    int fret;
    if (minFret == 0 && pos.dx < openW) {
      fret = 0;
    } else if (minFret == 0) {
      final fw = (endX - openW) / (maxFret - minFret);
      final seg = ((pos.dx - openW) / fw).floor();
      fret = (1 + seg).clamp(1, maxFret);
    } else {
      final fw = (endX - openW) / (maxFret - minFret + 1);
      fret = ((pos.dx - openW) / fw).floor() + minFret;
    }

    final string = ((pos.dy - topPad + sh / 2) / sh).floor();

    if (fret < minFret || fret > maxFret) return null;
    if (string < 0 || string > 5) return null;
    return GuitarNote(string: string, fret: fret);
  }

  /// Painter merkezine dokunma noktası (regresyon testleri).
  @visibleForTesting
  static Offset cellCenterFor(GuitarNote note, Size size) {
    final painter = FretboardPainter(cellStates: const {}, maxFret: 7);
    return painter.cellCenter(size, note);
  }

  @override
  State<FretboardWidget> createState() => _FretboardWidgetState();
}

final class _FretboardWidgetState extends State<FretboardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  int _sig = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _sig = _highlightSig(widget.cellStates);
    _pulse.value = 1;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FretboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nh = _highlightSig(widget.cellStates);
    if (nh != _sig) {
      _sig = nh;
      _pulse.forward(from: 0);
    }
  }

  int _highlightSig(Map<GuitarNote, FretboardCellState> m) {
    var h = 17;
    for (final e in m.entries) {
      if (e.value.highlighted || e.value.selected) {
        h = h * 31 + e.key.string * 13 + e.key.fret * 7;
      }
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _pulse, curve: Curves.easeOutBack);
    final scale = Tween<double>(begin: 0.96, end: 1).animate(curved);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final painter = FretboardPainter(
              cellStates: widget.cellStates,
              minFret: widget.minFret,
              maxFret: widget.maxFret,
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final note = FretboardWidget.hitTestAt(
                  d.localPosition,
                  constraints.biggest,
                  minFret: widget.minFret,
                  maxFret: widget.maxFret,
                );
                if (note != null) {
                  widget.onCellTap(note);
                }
              },
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: scale.value,
                      child: CustomPaint(
                        painter: painter,
                        size: constraints.biggest,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

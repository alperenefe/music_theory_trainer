import 'package:flutter/material.dart';

import '../../models/notation_pitch.dart';
import '../../staff/staff_geometry.dart';
import '../../staff/treble_staff_painter.dart';
import '../../theme/app_spacing.dart';

final class StaffInteractiveField extends StatelessWidget {
  const StaffInteractiveField({
    super.key,
    required this.notes,
    this.highlightSlot,
    required this.onSlot,
    this.minHeight = 200,
    this.readOnly = false,
    this.paintWidthScale = AppSpacing.staffPaintWidthScale,
  });

  final List<TrebleStaffNoteSpec> notes;
  final int? highlightSlot;
  final ValueChanged<int> onSlot;
  final double minHeight;
  final bool readOnly;
  final double paintWidthScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight.isFinite ? c.maxHeight : minHeight;
        final layoutW = c.maxWidth;
        final paintW = layoutW * paintWidthScale;
        final g = StaffGeometry(Size(paintW, h));
        final painter = TrebleStaffPainter(
          geometry: g,
          notes: notes,
          highlightSlot: highlightSlot,
        );
        final core = CustomPaint(painter: painter);
        void pickAt(Offset local) {
          final slot = g.nearestSlotForY(
            local.dy,
            NotationPitch.allStaffSlots(),
          );
          onSlot(slot);
        }

        final hitChild = readOnly
            ? core
            : Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => pickAt(e.localPosition),
                onPointerMove: (e) => pickAt(e.localPosition),
                child: core,
              );
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: const Color(0x660F172A),
            child: SizedBox(
              width: layoutW,
              height: h,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: paintW,
                maxWidth: paintW,
                child: SizedBox(width: paintW, height: h, child: hitChild),
              ),
            ),
          ),
        );
      },
    );
  }
}

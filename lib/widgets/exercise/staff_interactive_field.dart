import 'package:flutter/material.dart';

import '../../models/notation_pitch.dart';
import '../../staff/staff_geometry.dart';
import '../../staff/staff_ledger_slots.dart';
import '../../staff/treble_staff_painter.dart';
import '../../theme/app_spacing.dart';
import 'staff_scroll_blocker.dart';

final class StaffInteractiveField extends StatefulWidget {
  const StaffInteractiveField({
    super.key,
    required this.notes,
    this.highlightSlot,
    this.wrongHighlightSlot,
    this.correctHighlightSlot,
    required this.onSlot,
    this.minHeight = 200,
    this.readOnly = false,
    this.paintWidthScale = AppSpacing.staffPaintWidthScale,
    this.layoutSlots,
    this.pickableSlots,
    this.fitExercisePool = false,
  });

  final List<TrebleStaffNoteSpec> notes;
  final int? highlightSlot;
  final int? wrongHighlightSlot;
  final int? correctHighlightSlot;
  final ValueChanged<int> onSlot;
  final double minHeight;
  final bool readOnly;
  final double paintWidthScale;
  final Iterable<int>? layoutSlots;
  final Iterable<int>? pickableSlots;
  final bool fitExercisePool;

  @override
  State<StaffInteractiveField> createState() => _StaffInteractiveFieldState();
}

final class _StaffInteractiveFieldState extends State<StaffInteractiveField> {
  StaffGeometry? _geometry;
  List<int> _pickList = const [];

  void _pickAt(Offset local) {
    final g = _geometry;
    if (g == null || _pickList.isEmpty) {
      return;
    }
    widget.onSlot(g.nearestSlotForY(local.dy, _pickList));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight.isFinite ? c.maxHeight : widget.minHeight;
        final layoutW = c.maxWidth;
        final layoutList = (widget.layoutSlots ?? NotationPitch.allStaffSlots())
            .toList();
        if (layoutList.isEmpty) {
          layoutList.addAll(NotationPitch.allStaffSlots());
        }
        layoutList.sort();
        final pickList =
            (widget.pickableSlots ?? widget.layoutSlots ?? NotationPitch.allStaffSlots())
                .toList();
        if (pickList.isEmpty) {
          pickList.addAll(NotationPitch.allStaffSlots());
        }
        pickList.sort();
        _pickList = pickList;
        final g = widget.fitExercisePool
            ? StaffGeometry.forExercisePool(
                Size(layoutW, h),
                poolSlotMin: layoutList.first,
                poolSlotMax: layoutList.last,
              )
            : StaffGeometry(
                Size(layoutW, h),
                slotMin: layoutList.first,
                slotMax: layoutList.last,
              );
        _geometry = g;
        final ledgers = StaffLedgerSlots.forExerciseRange(pickList);
        final painter = TrebleStaffPainter(
          geometry: g,
          notes: widget.notes,
          ledgerSlots: ledgers,
          highlightSlot: widget.highlightSlot,
          wrongHighlightSlot: widget.wrongHighlightSlot,
          correctHighlightSlot: widget.correctHighlightSlot,
        );
        final core = Semantics(
          label: widget.readOnly
              ? 'Porte önizleme'
              : 'Porte, dokunarak veya sürükleyerek nota seç',
          child: CustomPaint(
            painter: painter,
            size: Size(layoutW, h),
          ),
        );
        final hitChild = widget.readOnly
            ? core
            : StaffScrollBlocker(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (d) => _pickAt(d.localPosition),
                  onPanUpdate: (d) => _pickAt(d.localPosition),
                  onTapDown: (d) => _pickAt(d.localPosition),
                  child: core,
                ),
              );
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: const Color(0x660F172A),
            child: SizedBox(
              width: layoutW,
              height: h,
              child: hitChild,
            ),
          ),
        );
      },
    );
  }
}

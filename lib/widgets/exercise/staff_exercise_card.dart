import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/notation_pitch.dart';
import '../../staff/treble_staff_painter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';
import 'staff_interactive_field.dart';

final class McqStaffCard extends StatelessWidget {
  const McqStaffCard({
    super.key,
    required this.pool,
    required this.targetStaffSlot,
    this.wrongHighlightSlot,
    this.correctHighlightSlot,
  });

  final List<NotationPitch> pool;
  final int targetStaffSlot;
  final int? wrongHighlightSlot;
  final int? correctHighlightSlot;

  @override
  Widget build(BuildContext context) {
    final slots = pool.map((e) => e.staffSlot);
    return SoftCard(
      padding: AppSpacing.cardPad,
      child: SizedBox(
        height: AppSpacing.mcqStaffAreaHeight,
        child: StaffInteractiveField(
          readOnly: true,
          fitExercisePool: true,
          layoutSlots: slots,
          pickableSlots: slots,
          notes: [TrebleStaffNoteSpec(slot: targetStaffSlot)],
          wrongHighlightSlot: wrongHighlightSlot,
          correctHighlightSlot: correctHighlightSlot,
          onSlot: (_) {},
        ),
      ),
    );
  }
}

final class PlacementStaffCard extends StatelessWidget {
  const PlacementStaffCard({
    super.key,
    required this.pool,
    required this.notes,
    required this.highlightSlot,
    required this.feedback,
    required this.onSlot,
    this.wrongHighlightSlot,
    this.correctHighlightSlot,
    this.expandToFill = false,
  });

  final List<NotationPitch> pool;
  final List<TrebleStaffNoteSpec> notes;
  final int? highlightSlot;
  final bool feedback;
  final ValueChanged<int> onSlot;
  final int? wrongHighlightSlot;
  final int? correctHighlightSlot;
  final bool expandToFill;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final slots = pool.map((e) => e.staffSlot);
    final staff = AbsorbPointer(
      absorbing: feedback,
      child: StaffInteractiveField(
        layoutSlots: slots,
        pickableSlots: slots,
        fitExercisePool: expandToFill,
        notes: notes,
        highlightSlot: highlightSlot,
        wrongHighlightSlot: wrongHighlightSlot,
        correctHighlightSlot: correctHighlightSlot,
        onSlot: onSlot,
      ),
    );
    return SoftCard(
      padding: expandToFill ? AppSpacing.cardPadDense : AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.tapStaff,
            style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (expandToFill)
            Expanded(child: staff)
          else
            SizedBox(height: AppSpacing.staffAreaHeight, child: staff),
        ],
      ),
    );
  }
}

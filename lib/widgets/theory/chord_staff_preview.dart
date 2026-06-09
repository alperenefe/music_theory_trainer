import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/notation_pitch.dart';
import '../../staff/treble_staff_painter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';
import '../exercise/staff_interactive_field.dart';

/// Akor tonlarını portede üst üste (yığın) gösterir.
final class ChordStaffPreview extends StatelessWidget {
  const ChordStaffPreview({
    super.key,
    required this.chordMidis,
    this.visible = true,
    this.highlightOnFeedback = false,
  });

  final List<int> chordMidis;
  final bool visible;
  final bool highlightOnFeedback;

  static List<int> layoutSlotsFor(Iterable<int> midis) {
    final slots = <int>{};
    for (final m in midis) {
      final slot = NotationPitch.staffSlotForSoundingMidi(m);
      if (slot != null) {
        slots.add(slot);
      }
    }
    if (slots.isEmpty) {
      return NotationPitch.allStaffSlots();
    }
    var lo = slots.reduce(math.min) - 2;
    var hi = slots.reduce(math.max) + 2;
    return NotationPitch.allStaffSlots()
        .where((s) => s >= lo && s <= hi)
        .toList();
  }

  static List<TrebleStaffNoteSpec> noteSpecs(
    List<int> midis, {
    bool highlight = false,
  }) {
    final specs = <TrebleStaffNoteSpec>[];
    for (final m in midis) {
      final slot = NotationPitch.staffSlotForSoundingMidi(m);
      if (slot == null) {
        continue;
      }
      specs.add(
        TrebleStaffNoteSpec(
          slot: slot,
          feedback: highlight
              ? StaffNoteFeedbackKind.correctTarget
              : StaffNoteFeedbackKind.normal,
        ),
      );
    }
    return specs;
  }

  @override
  Widget build(BuildContext context) {
    if (!visible || chordMidis.isEmpty) {
      return const SizedBox.shrink();
    }
    final notes = noteSpecs(
      chordMidis,
      highlight: highlightOnFeedback,
    );
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }
    final layout = layoutSlotsFor(chordMidis);
    return SoftCard(
      padding: AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Porte',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DesignTokens.slate500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.mcqStaffAreaHeight,
            child: StaffInteractiveField(
              readOnly: true,
              fitExercisePool: true,
              layoutSlots: layout,
              pickableSlots: layout,
              notes: notes,
              onSlot: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

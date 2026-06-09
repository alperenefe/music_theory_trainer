import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/notation_pitch.dart';
import '../../staff/treble_staff_painter.dart';
import '../../theme/app_spacing.dart';
import '../cards/soft_card.dart';
import '../exercise/staff_interactive_field.dart';

/// Aralık sorusunda kök (ve isteğe bağlı cevap) notalarını mini portede gösterir.
final class IntervalStaffPreview extends StatelessWidget {
  const IntervalStaffPreview({
    super.key,
    required this.rootMidi,
    required this.answerMidi,
    this.showAnswer = false,
  });

  final int rootMidi;
  final int answerMidi;
  final bool showAnswer;

  static List<int> layoutSlotsFor(int rootMidi, int? answerMidi) {
    final slots = <int>{};
    final rootSlot = NotationPitch.staffSlotForSoundingMidi(rootMidi);
    if (rootSlot != null) {
      slots.add(rootSlot);
    }
    if (answerMidi != null) {
      final answerSlot = NotationPitch.staffSlotForSoundingMidi(answerMidi);
      if (answerSlot != null) {
        slots.add(answerSlot);
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

  static List<TrebleStaffNoteSpec> noteSpecs({
    required int rootMidi,
    required int answerMidi,
    required bool showAnswer,
  }) {
    final rootSlot = NotationPitch.staffSlotForSoundingMidi(rootMidi);
    if (rootSlot == null) {
      return const [];
    }
    final notes = <TrebleStaffNoteSpec>[
      TrebleStaffNoteSpec(slot: rootSlot),
    ];
    if (showAnswer) {
      final answerSlot = NotationPitch.staffSlotForSoundingMidi(answerMidi);
      if (answerSlot != null && answerSlot != rootSlot) {
        notes.add(
          TrebleStaffNoteSpec(
            slot: answerSlot,
            feedback: StaffNoteFeedbackKind.correctTarget,
          ),
        );
      }
    }
    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final notes = noteSpecs(
      rootMidi: rootMidi,
      answerMidi: answerMidi,
      showAnswer: showAnswer,
    );
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }
    final layout = layoutSlotsFor(
      rootMidi,
      showAnswer ? answerMidi : null,
    );
    return SoftCard(
      padding: AppSpacing.cardPad,
      child: SizedBox(
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
    );
  }
}

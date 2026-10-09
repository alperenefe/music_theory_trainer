import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_strings.dart';
import '../models/notation_pitch.dart';
import '../services/staff_curriculum_service.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/feedback/celebration_burst.dart';

/// Yeni faz açıldığında gösterilen tam ekran kutlama.
final class PhaseUnlockScreen extends StatelessWidget {
  const PhaseUnlockScreen({super.key, required this.newPhase});

  final int newPhase;

  static Future<void> show(BuildContext context, int newPhase) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => PhaseUnlockScreen(newPhase: newPhase),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final newMidis = StaffCurriculumService.phaseMidis(newPhase).toList()
      ..sort();
    final allPool = NotationPitch.trainingPool();
    final newNotes = newMidis
        .map((m) => allPool.where((n) => n.midi == m).firstOrNull)
        .nonNulls
        .toList();

    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: ListView(
            padding: AppSpacing.screenHV,
            children: [
              const SizedBox(height: AppSpacing.md),
              // Başlık
              Text(
                AppStrings.phaseUnlockTitle(newPhase),
                textAlign: TextAlign.center,
                style: t.headlineSmall?.copyWith(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.88, 0.88),
                    end: const Offset(1, 1),
                    duration: 450.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.phaseUnlockSubtitle,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: DesignTokens.slate400),
              ).animate().fadeIn(delay: 100.ms),
              const CelebrationBurst(),
              const SizedBox(height: AppSpacing.sm),
              // Yıldız ikonu
              Icon(
                Icons.auto_awesome_rounded,
                size: 52,
                color: DesignTokens.violet400,
              )
                  .animate()
                  .fadeIn(delay: 120.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms),
              const SizedBox(height: AppSpacing.lg),
              // Yeni notalar
              Text(
                AppStrings.phaseUnlockNewNotes,
                style: t.titleSmall?.copyWith(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSpacing.sm),
              ...newNotes.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SoftCard(
                    padding: AppSpacing.cardPadDense,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: DesignTokens.violet400.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            size: 18,
                            color: DesignTokens.violet400,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            e.value.displayTurkish,
                            style: t.bodyMedium?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _slotDescription(e.value.staffSlot),
                          style: t.labelSmall?.copyWith(
                            color: DesignTokens.slate500,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: Duration(milliseconds: 250 + e.key * 60))
                      .fadeIn()
                      .slideX(begin: 0.06, end: 0),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(AppStrings.phaseUnlockContinue),
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.08, end: 0),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  String _slotDescription(int slot) {
    if (slot >= 0 && slot <= 8) {
      if (slot.isEven) {
        return '${(slot ~/ 2) + 1}. çizgi';
      } else {
        return '${(slot ~/ 2) + 1}. aralık';
      }
    } else if (slot < 0) {
      return '${(-slot ~/ 2)}. ek çizgi altı';
    } else {
      return '${((slot - 8) ~/ 2)}. ek çizgi üstü';
    }
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/notation_pitch.dart';
import '../../services/practice_prefs_repository.dart';
import '../../services/staff_curriculum_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

/// Landing ekranında müfredat fazını ve aktif notaları gösterir.
final class CurriculumPhaseCard extends StatefulWidget {
  const CurriculumPhaseCard({super.key, required this.prefsRepo});

  final PracticePrefsRepository prefsRepo;

  @override
  State<CurriculumPhaseCard> createState() => _CurriculumPhaseCardState();
}

final class _CurriculumPhaseCardState extends State<CurriculumPhaseCard> {
  int _phase = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await widget.prefsRepo.load();
    if (!mounted) return;
    setState(() {
      _phase = prefs.curriculumPhase;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final t = Theme.of(context).textTheme;
    final pool = StaffCurriculumService.activePool(_phase);
    final allPool = NotationPitch.trainingPool();
    final noteNames = pool
        .map((n) => allPool.where((a) => a.midi == n.midi).firstOrNull)
        .nonNulls
        .map((n) => _shortName(n.displayTurkish))
        .toList();

    final progressFraction = _phase / StaffCurriculumService.maxPhase;

    return SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.violet400.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.landingPhaseLabel(
                    _phase,
                    StaffCurriculumService.maxPhase,
                  ),
                  style: t.labelMedium?.copyWith(
                    color: DesignTokens.violet400,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${pool.length} nota',
                style: t.labelSmall?.copyWith(color: DesignTokens.slate500),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Faz ilerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 4,
              backgroundColor: DesignTokens.slate700,
              valueColor: AlwaysStoppedAnimation<Color>(
                DesignTokens.violet400.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.landingPhaseActiveNotes,
            style: t.labelSmall?.copyWith(
              color: DesignTokens.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: noteNames
                .map(
                  (name) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.slate700.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: DesignTokens.slate600.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      name,
                      style: t.labelSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.landingPhaseHint,
            style: t.labelSmall?.copyWith(color: DesignTokens.slate600),
          ),
        ],
      ),
    );
  }

  /// "La (4. oktav)" → "La" kısa isim.
  String _shortName(String display) {
    final idx = display.indexOf(' ');
    return idx > 0 ? display.substring(0, idx) : display;
  }
}

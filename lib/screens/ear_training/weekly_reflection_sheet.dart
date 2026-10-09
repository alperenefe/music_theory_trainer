import 'package:flutter/material.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_curriculum.dart';
import '../../models/weekly_progress.dart';
import '../../services/ear_session_recorder.dart';
import '../../services/practice_prefs_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/ear/ear_palette.dart';

/// Haftalık öz değerlendirme sayfasını açar. Kaydedilirse true döner.
Future<bool> showWeeklyReflectionSheet({
  required BuildContext context,
  required EarWeek week,
  required WeeklyProgress progress,
  required PracticePrefsRepository prefsRepo,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: EarPalette.of(context).dark ? DesignTokens.slate900 : Colors.white,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => WeeklyReflectionSheet(
      week: week,
      progress: progress,
      prefsRepo: prefsRepo,
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(EarStrings.reflectionSaved),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  return saved == true;
}

/// Metabiliş: "Ne kadar güvendeyim?" + "En çok nerede zorlandım?" — kalıcı kaydedilir.
final class WeeklyReflectionSheet extends StatefulWidget {
  const WeeklyReflectionSheet({
    super.key,
    required this.week,
    required this.progress,
    required this.prefsRepo,
  });

  final EarWeek week;
  final WeeklyProgress progress;
  final PracticePrefsRepository prefsRepo;

  @override
  State<WeeklyReflectionSheet> createState() => _WeeklyReflectionSheetState();
}

final class _WeeklyReflectionSheetState extends State<WeeklyReflectionSheet> {
  int? _confidence;
  String? _hardest;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _confidence = widget.progress.confidence;
    final h = widget.progress.hardestArea;
    _hardest = EarStrings.hardestOptions.contains(h) ? h : null;
  }

  bool get _canSave => _confidence != null && _hardest != null && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      await EarSessionRecorder(widget.prefsRepo).saveReflection(
        weekNumber: widget.week.weekNumber,
        confidence: _confidence!,
        hardestArea: _hardest!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('WeeklyReflectionSheet: kaydedilemedi: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🧠 ${EarStrings.reflectionTitle}',
              style: t.titleLarge?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${EarStrings.weekLabel(widget.week.weekNumber)}: ${widget.week.title} · '
              '${EarStrings.reflectionBest((widget.progress.bestAccuracy * 100).round())}',
              style: t.bodyMedium?.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              EarStrings.reflectionConfidence,
              style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<int>(
              showSelectedIcon: false,
              emptySelectionAllowed: true,
              segments: [
                for (var i = 1; i <= 5; i++)
                  ButtonSegment<int>(value: i, label: Text('$i')),
              ],
              selected: {?_confidence},
              onSelectionChanged: (s) =>
                  setState(() => _confidence = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(EarStrings.confidenceLow, style: t.labelSmall?.copyWith(color: p.textMuted)),
                const Spacer(),
                Text(EarStrings.confidenceHigh, style: t.labelSmall?.copyWith(color: p.textMuted)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              EarStrings.reflectionHardest,
              style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final option in EarStrings.hardestOptions)
                  ChoiceChip(
                    label: Text(option),
                    selected: _hardest == option,
                    onSelected: (_) => setState(() => _hardest = option),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.earEmerald,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(EarStrings.reflectionSave),
            ),
          ],
        ),
      ),
    );
  }
}

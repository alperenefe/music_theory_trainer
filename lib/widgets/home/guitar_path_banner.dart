import 'package:flutter/material.dart';

import '../../models/guitar_path.dart';
import '../../models/practice_prefs.dart';
import '../../services/guitar_practice_clock.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

/// Ana ekrandaki "Gitar Yolu" bandı: sıradaki adım ve günlük hedef halkası.
final class GuitarPathBanner extends StatelessWidget {
  const GuitarPathBanner({super.key, required this.prefs, required this.onTap, this.now});

  final PracticePrefs prefs;
  final VoidCallback onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final next = GuitarPath.nextStep(prefs.guitarStepStars);
    final todayMs = prefs.practiceMsOn(PracticeDay.key(now ?? DateTime.now()));
    final goalMs = prefs.dailyGoalMinutes * 60000;
    final progress = goalMs <= 0 ? 0.0 : (todayMs / goalMs).clamp(0.0, 1.0);
    final fresh = prefs.guitarStepStars.isEmpty;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.streakOrange.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardInner),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                      const Center(child: Text('🎸', style: TextStyle(fontSize: 24))),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gitar Yolu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fresh
                            ? 'Gitarını al: ilk akorlarından başla'
                            : (next == null ? 'Yolu bitirdin!' : 'Sıradaki: ${next.title}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        'Bugün ${(todayMs / 60000).floor()} / ${prefs.dailyGoalMinutes} dk',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

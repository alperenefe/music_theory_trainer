import 'package:flutter/material.dart';
import '../../models/weekly_progress.dart';
import '../../services/ear_curriculum_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class EarTrainingBanner extends StatelessWidget {
  const EarTrainingBanner({
    super.key,
    required this.earProgress,
    required this.onTap,
  });

  final List<WeeklyProgress> earProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const service = EarCurriculumService();
    final currentWeek = service.currentWeek(earProgress);
    final completedCount = earProgress.where((p) => p.isCompleted).length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.blue500.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.blue600.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Center(
                    child: Text('🎧', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: DesignTokens.earEmerald.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$completedCount / 12 HAFTA',
                              style: const TextStyle(
                                color: DesignTokens.earEmerald,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kulaktan Akor Çıkarma',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentWeek.weekNumber}. Hafta: ${currentWeek.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

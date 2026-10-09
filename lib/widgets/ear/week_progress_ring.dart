import 'package:flutter/material.dart';

import '../../models/ear_curriculum.dart';
import '../../models/weekly_progress.dart';
import '../../services/weekly_mastery_gate.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

/// Hafta düğümü: baraj ilerlemesini (doğruluk + soru + gün) halka olarak gösterir.
final class WeekProgressRing extends StatelessWidget {
  const WeekProgressRing({
    super.key,
    required this.week,
    required this.progress,
    this.size = 54.0,
    this.highlight = false,
  });

  final EarWeek week;
  final WeeklyProgress progress;
  final double size;

  /// Aktif hafta: dolu mavi zemin.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final isLocked = !progress.isUnlocked;
    final isDone = progress.isCompleted;
    final fraction = isDone
        ? 1.0
        : (isLocked ? 0.0 : WeeklyMasteryGate.status(progress, week).overallFraction);

    final ringColor = isDone
        ? DesignTokens.earEmerald
        : (week.isConsolidation ? DesignTokens.earGold : DesignTokens.blue500);

    final Color innerColor;
    if (isDone) {
      innerColor = DesignTokens.earEmerald.withValues(alpha: p.dark ? 0.22 : 0.14);
    } else if (highlight) {
      innerColor = DesignTokens.blue600;
    } else {
      innerColor = isLocked ? p.surfaceLocked : p.surface;
    }

    return Semantics(
      label: '${week.weekNumber}. hafta, %${(fraction * 100).round()}',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: p.track,
                valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              ),
            ),
            Container(
              width: size * 0.74,
              height: size * 0.74,
              decoration: BoxDecoration(shape: BoxShape.circle, color: innerColor),
              child: Center(
                child: isDone
                    ? Icon(
                        progress.bossCleared ? Icons.emoji_events_rounded : Icons.check_rounded,
                        color: progress.bossCleared ? p.gold : p.success,
                        size: size * 0.4,
                      )
                    : (isLocked
                        ? Icon(Icons.lock_rounded, color: p.textMuted, size: size * 0.32)
                        : Text(
                            '${week.weekNumber}',
                            style: TextStyle(
                              color: highlight ? DesignTokens.white : p.textPrimary,
                              fontSize: size * 0.3,
                              fontWeight: FontWeight.w900,
                            ),
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

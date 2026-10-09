import 'package:flutter/material.dart';
import '../../config/home_route_catalog.dart';
import '../../services/goal_progress_snapshot.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'home_grid_card.dart';

class HomeRoadmapNode extends StatelessWidget {
  const HomeRoadmapNode({
    super.key,
    required this.spec,
    required this.isLeft,
    required this.isLast,
    this.goalProgress,
    this.micBadge = false,
    this.phaseBadge,
    required this.onTap,
  });

  final HomeRouteSpec spec;
  final bool isLeft;
  final bool isLast;
  final GoalProgressSnapshot? goalProgress;
  final bool micBadge;
  final String? phaseBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 50% width approach with a connecting line in the center.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side
          Expanded(
            child: isLeft
                ? Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.md,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.md,
                    ),
                    child: HomeGridCard(
                      index: spec.index,
                      icon: spec.icon,
                      title: spec.title,
                      subtitle: spec.subtitle,
                      accent: spec.accent,
                      goalProgress: goalProgress,
                      micBadge: micBadge,
                      phaseBadge: phaseBadge,
                      onTap: onTap,
                    ),
                  )
                : const SizedBox(),
          ),
          
          // Center line and node
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned.fill(
                    top: 24, // Start below the node
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: DesignTokens.slate700.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: spec.accent.withValues(alpha: 0.2),
                    border: Border.all(
                      color: spec.accent,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      spec.icon,
                      size: 12,
                      color: spec.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right side
          Expanded(
            child: !isLeft
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.md,
                    ),
                    child: HomeGridCard(
                      index: spec.index,
                      icon: spec.icon,
                      title: spec.title,
                      subtitle: spec.subtitle,
                      accent: spec.accent,
                      goalProgress: goalProgress,
                      micBadge: micBadge,
                      phaseBadge: phaseBadge,
                      onTap: onTap,
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

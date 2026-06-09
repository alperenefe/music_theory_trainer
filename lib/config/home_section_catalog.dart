import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/design_tokens.dart';
import 'goal_kind.dart';
import 'home_route_catalog.dart';

enum HomeSectionKind { staff, theory, guitar, tools }

final class HomeSectionSpec {
  const HomeSectionSpec({
    required this.kind,
    required this.title,
    required this.accent,
    required this.routeIndices,
    this.fullWidthIndices = const {},
  });

  final HomeSectionKind kind;
  final String title;
  final Color accent;
  final List<int> routeIndices;
  /// Ana sayfada tam genişlik kart (ör. hedef, akort).
  final Set<int> fullWidthIndices;
}

final List<HomeSectionSpec> homeSectionSpecs = [
  HomeSectionSpec(
    kind: HomeSectionKind.staff,
    title: AppStrings.homeSectionStaff,
    accent: DesignTokens.blue500,
    routeIndices: [0, 1],
  ),
  HomeSectionSpec(
    kind: HomeSectionKind.theory,
    title: AppStrings.homeSectionTheory,
    accent: DesignTokens.violet400,
    routeIndices: [2, 3, 4],
  ),
  HomeSectionSpec(
    kind: HomeSectionKind.guitar,
    title: AppStrings.homeSectionGuitar,
    accent: DesignTokens.rose400,
    // Akort + Hedefler yalnızca üstteki twin CTA; burada tekrar gösterme.
    routeIndices: [5, 6, 7],
  ),
];

HomeRouteSpec homeRouteByIndex(int index) =>
    homeRouteSpecs.firstWhere((s) => s.index == index);

bool homeRouteShowsMicBadge(HomeRouteSpec spec) =>
    spec.goalKind == GoalKind.guitarPlay;

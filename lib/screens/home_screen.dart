import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/home_route_catalog.dart';
import '../l10n/app_strings.dart';
import '../models/notation_pitch.dart';
import '../models/practice_prefs.dart';
import '../services/app_sound_policy.dart';
import '../services/goal_progress_snapshot.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../models/practice_attempt.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/home/home_route_card.dart';
import '../widgets/loading/home_list_skeleton.dart';
import '../widgets/onboarding/app_onboarding_dialog.dart';
import '../widgets/text/section_header.dart';

final class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  final _prefsRepo = PracticePrefsRepository();
  final _statsRepo = StatsRepository();
  PracticePrefs _prefs = const PracticePrefs();
  List<PracticeAttempt> _attempts = [];
  List<NotationPitch> _pool = NotationPitch.trainingPool();
  var _loaded = false;
  var _onboardingScheduled = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final p = await _prefsRepo.load();
    final attempts = await _statsRepo.load();
    var pool = NotationPitch.poolForMidiRange(p.poolMinMidi, p.poolMaxMidi);
    if (pool.isEmpty) {
      pool = NotationPitch.trainingPool();
    }
    AppSoundPolicy.instance.setEnabled(p.soundEnabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _prefs = p;
      _pool = pool;
      _attempts = attempts;
      _loaded = true;
    });
    if (!p.onboardingDone && !_onboardingScheduled) {
      _onboardingScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await showAppOnboardingDialog(context: context, repo: _prefsRepo);
        if (mounted) {
          await _refresh();
        }
      });
    }
  }

  Future<void> _toggleSound() async {
    final next = _prefs.copyWith(soundEnabled: !_prefs.soundEnabled);
    await _prefsRepo.save(next);
    AppSoundPolicy.instance.setEnabled(next.soundEnabled);
    if (!mounted) {
      return;
    }
    setState(() => _prefs = next);
  }

  Future<void> _openRoute(HomeRouteSpec spec) async {
    final deps = HomeNavDeps(
      pool: _pool,
      prefsRepo: _prefsRepo,
      poolMinMidi: _prefs.poolMinMidi,
      poolMaxMidi: _prefs.poolMaxMidi,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => spec.pageBuilder(deps)),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/branding/app_icon.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              )
              .animate()
              .fadeIn(duration: AppMotion.medium)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: AppMotion.medium,
                curve: AppMotion.curve,
              ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                SectionHeader(
                      title: AppStrings.appTitle,
                      subtitle: AppStrings.homeSubtitle,
                    )
                    .animate()
                    .fadeIn(duration: AppMotion.medium)
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      duration: AppMotion.medium,
                      curve: AppMotion.curve,
                    ),
          ),
          IconButton(
            tooltip: _prefs.soundEnabled
                ? AppStrings.soundOn
                : AppStrings.soundOff,
            onPressed: _toggleSound,
            icon: Icon(
              _prefs.soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: DesignTokens.slate200,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sectionGap),
    ];

    for (var i = 0; i < homeRouteSpecs.length; i++) {
      final spec = homeRouteSpecs[i];
      if (i > 0) {
        children.add(const SizedBox(height: AppSpacing.cardGap));
      }
      GoalProgressSnapshot? progress;
      final gk = spec.goalKind;
      if (gk != null) {
        progress = GoalProgressSnapshot.forKind(
          kind: gk,
          prefs: _prefs,
          all: _attempts,
        );
      }
      children.add(
        HomeRouteCard(
          index: spec.index,
          icon: spec.icon,
          title: spec.title,
          subtitle: spec.subtitle,
          accent: spec.accent,
          showStartLink: spec.showStartLink,
          goalProgress: progress,
          onTap: () => _openRoute(spec),
        ),
      );
    }

    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: !_loaded
              ? const HomeListSkeleton()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: AppSpacing.screenHV,
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(children),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

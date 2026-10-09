import 'package:flutter/material.dart';
import '../config/home_route_catalog.dart';
import '../config/home_section_catalog.dart';
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
import '../screens/goals_screen.dart';
import '../screens/guitar_tuner_screen.dart';
import 'ear_training/ear_home_screen.dart';
import '../widgets/home/ear_training_banner.dart';
import '../widgets/home/guitar_path_banner.dart';
import 'guitar/guitar_path_screen.dart';
import '../widgets/home/home_roadmap_node.dart';
import '../widgets/home/home_route_card.dart';
import '../widgets/home/home_stats_banner.dart';
import '../widgets/home/home_twin_cta_row.dart';
import '../widgets/motion/motion_entrance.dart';
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

  Future<void> _openTuner() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const GuitarTunerScreen()),
    );
    await _refresh();
  }

  Future<void> _openGoals() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GoalsScreen(repo: _prefsRepo),
      ),
    );
    await _refresh();
  }

  Future<void> _openGuitarPath() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => GuitarPathScreen(repo: _prefsRepo)),
    );
    await _refresh();
  }

  Future<void> _openEarTraining() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EarHomeScreen(prefsRepo: _prefsRepo),
      ),
    );
    await _refresh();
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

  GoalProgressSnapshot? _progressFor(HomeRouteSpec spec) {
    final gk = spec.goalKind;
    if (gk == null) {
      return null;
    }
    return GoalProgressSnapshot.forKind(
      kind: gk,
      prefs: _prefs,
      all: _attempts,
    );
  }

  Widget _sectionHeader(HomeSectionSpec section) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        top: section == homeSectionSpecs.first ? AppSpacing.sm : AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: section.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            section.title,
            style: t.titleMedium?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  bool _isStaffExercise(HomeRouteSpec spec) =>
      spec.index == 0 || spec.index == 1;

  // _gridCard was removed as it's replaced by HomeRoadmapNode

  Widget _fullWidthCard(HomeRouteSpec spec) {
    return HomeRouteCard(
      index: spec.index,
      icon: spec.icon,
      title: spec.title,
      subtitle: spec.subtitle,
      accent: spec.accent,
      showStartLink: spec.showStartLink,
      goalProgress: _progressFor(spec),
      onTap: () => _openRoute(spec),
    );
  }

  List<Widget> _buildSections() {
    final out = <Widget>[];
    bool isLeft = true;
    for (int s = 0; s < homeSectionSpecs.length; s++) {
      final section = homeSectionSpecs[s];
      out.add(_sectionHeader(section));
      
      final specs = section.routeIndices.map((idx) => homeRouteByIndex(idx)).toList();
      
      for (int i = 0; i < specs.length; i++) {
        final spec = specs[i];
        final isLast = (s == homeSectionSpecs.length - 1) && (i == specs.length - 1);
        
        if (section.fullWidthIndices.contains(spec.index)) {
          out.add(const SizedBox(height: AppSpacing.cardGap));
          out.add(_fullWidthCard(spec));
          out.add(const SizedBox(height: AppSpacing.cardGap));
        } else {
          out.add(
            HomeRoadmapNode(
              spec: spec,
              isLeft: isLeft,
              isLast: isLast,
              goalProgress: _progressFor(spec),
              micBadge: homeRouteShowsMicBadge(spec),
              phaseBadge: _isStaffExercise(spec)
                  ? AppStrings.phaseCurrent(_prefs.curriculumPhase)
                  : null,
              onTap: () => _openRoute(spec),
            )
          );
          isLeft = !isLeft;
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final header = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/branding/app_icon.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              ).entranceFadeScale(context),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                SectionHeader(
                      title: AppStrings.appTitle,
                      subtitle: AppStrings.homeSubtitle,
                    ).entranceFadeSlide(context, slideY: 0.04),
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
      const SizedBox(height: AppSpacing.md),
      GuitarPathBanner(prefs: _prefs, onTap: _openGuitarPath),
      const SizedBox(height: AppSpacing.md),
      EarTrainingBanner(
        earProgress: _prefs.earWeekProgress,
        onTap: _openEarTraining,
      ),
      const SizedBox(height: AppSpacing.md),
      HomeStatsBanner(attempts: _attempts),
      const SizedBox(height: AppSpacing.md),
      HomeTwinCtaRow(onGoalsTap: _openGoals),
      const SizedBox(height: AppSpacing.md),
      ..._buildSections(),
      const SizedBox(height: AppSpacing.lg),
      Text(
        AppStrings.homePrivacyFooter,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DesignTokens.slate600,
          height: 1.4,
        ),
      ),
    ];

    return Scaffold(
      // Akort aleti yan bir araç, ana ders akışının bir parçası değil —
      // genişletilmiş (etiketli) FAB onu görsel olarak dersleri geride
      // bırakacak kadar öne çıkarıyordu. Sade, ikon tabanlı bir FAB'a
      // indirgeyip hâlâ tek dokunuşla erişilebilir tutuyoruz.
      floatingActionButton: FloatingActionButton(
        onPressed: _openTuner,
        tooltip: AppStrings.homeCtaTuner,
        backgroundColor: DesignTokens.tunerCyan,
        child: const Icon(Icons.tune_rounded, color: Colors.white),
      ),
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
                        delegate: SliverChildListDelegate(header),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

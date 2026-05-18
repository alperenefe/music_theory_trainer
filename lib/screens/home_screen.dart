import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_strings.dart';
import '../models/notation_pitch.dart';
import '../models/practice_prefs.dart';
import '../services/app_sound_policy.dart';
import '../services/practice_prefs_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/home/home_route_card.dart';
import '../widgets/loading/home_list_skeleton.dart';
import '../widgets/onboarding/app_onboarding_dialog.dart';
import '../widgets/text/section_header.dart';
import 'fret_mcq_screen.dart';
import 'fret_placement_screen.dart';
import 'fret_play_note_screen.dart';
import 'goals_screen.dart';
import 'guitar_tuner_screen.dart';
import 'mcq_screen.dart';
import 'placement_screen.dart';
import 'stats_screen.dart';

final class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  final _prefsRepo = PracticePrefsRepository();
  PracticePrefs _prefs = const PracticePrefs();
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

  String? _goalKindLabel(String? g) {
    return switch (g) {
      'placement' => AppStrings.placementTitle,
      'mcq' => AppStrings.mcqTitle,
      'gitar_mcq' => AppStrings.guitarMcqTitle,
      'gitar_bul' => AppStrings.guitarFindTitle,
      'gitar_cal' => AppStrings.guitarPlayTitle,
      _ => null,
    };
  }

  String? _goalSubtitle() {
    final g = _prefs.goalKind;
    final name = _goalKindLabel(g);
    if (name == null) {
      return null;
    }
    return '${AppStrings.goalActive}: ${_prefs.goalProgress}/${_prefs.goalTarget} · $name';
  }

  @override
  Widget build(BuildContext context) {
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
                        delegate: SliverChildListDelegate([
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
                          if (_goalSubtitle() != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            SoftCard(
                              padding: AppSpacing.cardPadDense,
                              child: Text(
                                _goalSubtitle()!,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: DesignTokens.slate200,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sectionGap),
                          HomeRouteCard(
                            index: 0,
                            icon: Icons.touch_app_rounded,
                            title: AppStrings.placementTitle,
                            subtitle: AppStrings.placementDesc,
                            accent: DesignTokens.blue500,
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => PlacementScreen(pool: _pool),
                                ),
                              );
                              await _refresh();
                            },
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                          HomeRouteCard(
                            index: 1,
                            icon: Icons.quiz_rounded,
                            title: AppStrings.mcqTitle,
                            subtitle: AppStrings.mcqDesc,
                            accent: DesignTokens.violet400,
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => McqScreen(pool: _pool),
                                ),
                              );
                              await _refresh();
                            },
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                          HomeRouteCard(
                            index: 2,
                            icon: Icons.flag_rounded,
                            title: AppStrings.goalsTitle,
                            subtitle: AppStrings.goalsDesc,
                            accent: DesignTokens.violet500,
                            showStartLink: false,
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => GoalsScreen(repo: _prefsRepo),
                                ),
                              );
                              await _refresh();
                            },
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                          HomeRouteCard(
                            index: 3,
                            icon: Icons.music_note_rounded,
                            title: AppStrings.guitarMcqTitle,
                            subtitle: AppStrings.guitarMcqDesc,
                            accent: DesignTokens.rose400,
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const FretMcqScreen(),
                                ),
                              );
                              await _refresh();
                            },
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                          HomeRouteCard(
                            index: 4,
                            icon: Icons.piano_rounded,
                            title: AppStrings.guitarFindTitle,
                            subtitle: AppStrings.guitarFindDesc,
                            accent: const Color(0xFFFC9A3A),
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const FretPlacementScreen(),
                                ),
                              );
                              await _refresh();
                            },
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                          HomeRouteCard(
                            index: 5,
                            icon: Icons.mic_rounded,
                            title: AppStrings.guitarPlayTitle,
                            subtitle: AppStrings.guitarPlayDesc,
                            accent: const Color(0xFF2DD4BF),
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const FretPlayNoteScreen(),
                                ),
                              );
                              await _refresh();
                            },
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                          HomeRouteCard(
                            index: 6,
                            icon: Icons.tune_rounded,
                            title: AppStrings.tunerTitle,
                            subtitle: AppStrings.tunerDesc,
                            accent: const Color(0xFF38BDF8),
                            showStartLink: false,
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const GuitarTunerScreen(),
                                ),
                              );
                              await _refresh();
                            },
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                          HomeRouteCard(
                            index: 7,
                            icon: Icons.insights_rounded,
                            title: AppStrings.statsTitle,
                            subtitle: AppStrings.statsDesc,
                            accent: DesignTokens.green400,
                            showStartLink: false,
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const StatsScreen(),
                                ),
                              );
                              await _refresh();
                            },
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

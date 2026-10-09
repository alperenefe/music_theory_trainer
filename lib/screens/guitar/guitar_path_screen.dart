import 'package:flutter/material.dart';

import '../../models/guitar_path.dart';
import '../../models/guitar_routine.dart';
import '../../models/practice_prefs.dart';
import '../../services/guitar_practice_clock.dart';
import '../../services/practice_prefs_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/background/mesh_gradient_backdrop.dart';
import '../../widgets/guitar/star_row.dart';
import '../../widgets/guitar/step_env.dart';
import '../ear_training/ear_home_screen.dart';
import 'chord_library_screen.dart';
import 'guitar_step_screen.dart';

/// Gitar Yolu: seviyeler, dersler, yıldızlar, günlük hedef ve günlük rutin.
///
/// Yousician'daki gibi hiçbir şey kilitli değil: istediğin adımı açabilirsin;
/// uygulama yalnızca bir sonraki önerilen adımı gösterir.
final class GuitarPathScreen extends StatefulWidget {
  const GuitarPathScreen({super.key, this.repo, this.env = const StepEnv()});

  final PracticePrefsRepository? repo;
  final StepEnv env;

  @override
  State<GuitarPathScreen> createState() => _GuitarPathScreenState();
}

final class _GuitarPathScreenState extends State<GuitarPathScreen> {
  late final PracticePrefsRepository _repo = widget.repo ?? PracticePrefsRepository();
  PracticePrefs _prefs = const PracticePrefs();
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final p = await _repo.load();
    if (!mounted) return;
    setState(() {
      _prefs = p;
      _loaded = true;
    });
  }

  Future<void> _openStep(String id) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GuitarStepScreen(stepId: id, repo: _repo, env: widget.env),
      ),
    );
    await _refresh();
  }

  Future<void> _openEar() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => EarHomeScreen(prefsRepo: _repo)),
    );
    await _refresh();
  }

  Future<void> _setGoal() async {
    var v = _prefs.dailyGoalMinutes.toDouble();
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Günlük gitar hedefi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${v.round()} dakika', style: Theme.of(ctx).textTheme.headlineSmall),
              Slider(
                value: v,
                min: PracticePrefs.minDailyGoalMinutes.toDouble(),
                max: 60,
                divisions: (60 - PracticePrefs.minDailyGoalMinutes) ~/ 5,
                onChanged: (x) => setS(() => v = (x / 5).round() * 5.0),
              ),
              const Text(
                'Gitar öğretmenleri başlangıçta günde 15–20 dakikayı, her gün, '
                'haftada bir uzun seanstan daha etkili bulur.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, v.round()), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final fresh = await _repo.load();
    final next = fresh.copyWith(dailyGoalMinutes: picked);
    await _repo.save(next);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final stars = _prefs.guitarStepStars;
    final next = GuitarPath.nextStep(stars);
    final todayMs = _prefs.practiceMsOn(PracticeDay.key(DateTime.now()));
    final goalMs = _prefs.dailyGoalMinutes * 60000;
    final progress = goalMs <= 0 ? 0.0 : (todayMs / goalMs).clamp(0.0, 1.0);
    final routine = GuitarRoutine.plan(stars);
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: AppSpacing.screenHV,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: DesignTokens.slate200,
                        ),
                        Expanded(
                          child: Text(
                            'Gitar Yolu',
                            style: t.headlineSmall?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Akor kütüphanesi',
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(builder: (_) => const ChordLibraryScreen()),
                          ),
                          icon: const Icon(Icons.library_music_rounded),
                          color: DesignTokens.slate200,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _goalCard(t, progress, todayMs, stars),
                    const SizedBox(height: AppSpacing.md),
                    if (next != null) _nextCard(t, next),
                    const SizedBox(height: AppSpacing.md),
                    _routineCard(t, routine),
                    const SizedBox(height: AppSpacing.lg),
                    for (final level in GuitarPath.levels) _levelTile(t, level, stars),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Akor, vuruş ve akor değişimi adımları gitarını mikrofonla dinler. '
                      'Ses kaydedilmez ve cihazından çıkmaz. Şimdilik Android’de çalışır.',
                      textAlign: TextAlign.center,
                      style: t.bodySmall?.copyWith(color: DesignTokens.slate500),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _goalCard(TextTheme t, double progress, int todayMs, Map<String, int> stars) {
    final minutes = todayMs / 60000;
    final done = progress >= 1;
    return Container(
      padding: AppSpacing.cardPad,
      decoration: BoxDecoration(
        color: DesignTokens.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: done ? DesignTokens.green400 : DesignTokens.borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  color: done ? DesignTokens.green400 : DesignTokens.blue500,
                  backgroundColor: DesignTokens.slate700,
                ),
                Center(
                  child: Icon(
                    done ? Icons.check_rounded : Icons.music_note_rounded,
                    color: done ? DesignTokens.green400 : DesignTokens.slate300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? 'Bugünkü hedef tamam!' : 'Bugün ${minutes.toStringAsFixed(minutes < 10 ? 1 : 0)} / '
                      '${_prefs.dailyGoalMinutes} dk',
                  style: t.titleMedium?.copyWith(color: DesignTokens.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: DesignTokens.earGold),
                    const SizedBox(width: 4),
                    Text(
                      '${GuitarPath.totalStars(stars)} / ${GuitarPath.allSteps.length * 3}',
                      style: t.bodySmall?.copyWith(color: DesignTokens.slate300),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(onPressed: _setGoal, child: const Text('Hedef')),
        ],
      ),
    );
  }

  Widget _nextCard(TextTheme t, GuitarStep next) {
    final lesson = GuitarPath.lessonOfStep(next.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => _openStep(next.id),
        child: Container(
          padding: AppSpacing.cardPad,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Önerilen sıradaki adım',
                        style: t.labelSmall?.copyWith(color: Colors.white70)),
                    Text(
                      next.title,
                      style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    if (lesson != null)
                      Text(lesson.title, style: t.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routineCard(TextTheme t, List<RoutineBlock> routine) {
    return Material(
      color: DesignTokens.cardBg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: DesignTokens.borderSubtle),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.today_rounded, color: DesignTokens.streakOrange),
          title: Text(
            'Bugünün ${GuitarRoutine.totalMinutes(routine)} dakikalık rutini',
            style: t.titleSmall?.copyWith(color: DesignTokens.white, fontWeight: FontWeight.w800),
          ),
          children: [
            for (final b in routine)
              ListTile(
                dense: true,
                title: Text(b.title, style: const TextStyle(color: DesignTokens.white)),
                subtitle: Text(
                  b.stepId == null && !b.opensEar
                      ? 'Henüz açılmadı — önce yoldaki ilk akorları çal.'
                      : b.why,
                  style: const TextStyle(color: DesignTokens.slate400, fontSize: 12),
                ),
                leading: Text('${b.minutes} dk', style: const TextStyle(color: DesignTokens.earGold)),
                trailing: (b.stepId != null || b.opensEar)
                    ? const Icon(Icons.chevron_right_rounded, color: DesignTokens.slate400)
                    : null,
                onTap: b.opensEar
                    ? _openEar
                    : (b.stepId != null ? () => _openStep(b.stepId!) : null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _levelTile(TextTheme t, GuitarLevel level, Map<String, int> stars) {
    final lessonStars = [for (final l in level.lessons) GuitarPath.lessonStars(l, stars)];
    final done = lessonStars.where((s) => s > 0).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: DesignTokens.cardBg,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: DesignTokens.borderSubtle),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: done == level.lessons.length
                  ? DesignTokens.weekDone
                  : DesignTokens.slate700,
              child: Text('${level.number}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            title: Text(level.title,
                style: t.titleSmall?.copyWith(color: DesignTokens.white, fontWeight: FontWeight.w800)),
            subtitle: Text('${level.subtitle}  •  $done/${level.lessons.length} ders',
                style: t.bodySmall?.copyWith(color: DesignTokens.slate400)),
            children: [
              for (final l in level.lessons) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l.title,
                            style: t.labelLarge?.copyWith(
                                color: DesignTokens.slate200, fontWeight: FontWeight.w800)),
                      ),
                      StarRow(stars: GuitarPath.lessonStars(l, stars), size: 16),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l.goal,
                        style: t.bodySmall?.copyWith(color: DesignTokens.slate400)),
                  ),
                ),
                for (final s in l.steps)
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(_iconOf(s.kind), size: 20, color: DesignTokens.slate300),
                    title: Text(s.title, style: const TextStyle(color: DesignTokens.white)),
                    trailing: s.isScored
                        ? StarRow(stars: stars[s.id] ?? 0, size: 16)
                        : ((stars[s.id] ?? 0) > 0
                            ? const Icon(Icons.check_circle_rounded,
                                size: 18, color: DesignTokens.green400)
                            : null),
                    onTap: () => _openStep(s.id),
                  ),
              ],
              if (level.earLink != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(level.earLink!,
                      style: t.bodySmall?.copyWith(color: DesignTokens.violet400)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconOf(GuitarStepKind k) => switch (k) {
        GuitarStepKind.info => Icons.menu_book_rounded,
        GuitarStepKind.tuner => Icons.tune_rounded,
        GuitarStepKind.openStrings => Icons.linear_scale_rounded,
        GuitarStepKind.chordPlay => Icons.back_hand_rounded,
        GuitarStepKind.changes => Icons.swap_horiz_rounded,
        GuitarStepKind.strum => Icons.waves_rounded,
        GuitarStepKind.progression => Icons.loop_rounded,
        GuitarStepKind.earPlay => Icons.hearing_rounded,
      };
}

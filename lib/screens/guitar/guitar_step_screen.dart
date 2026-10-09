import 'package:flutter/material.dart';

import '../../models/guitar_path.dart';
import '../../models/practice_prefs.dart';
import '../../services/guitar_practice_clock.dart';
import '../../services/practice_prefs_repository.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/background/mesh_gradient_backdrop.dart';
import '../../widgets/exercise/exercise_screen_top_bar.dart';
import '../../widgets/guitar/star_row.dart';
import '../../widgets/guitar/step_env.dart';
import '../../widgets/guitar/step_views/changes_view.dart';
import '../../widgets/guitar/step_views/chord_play_view.dart';
import '../../widgets/guitar/step_views/ear_play_view.dart';
import '../../widgets/guitar/step_views/info_step_view.dart';
import '../../widgets/guitar/step_views/open_strings_view.dart';
import '../../widgets/guitar/step_views/strum_view.dart';

/// Gitar yolundaki tek bir adımı çalıştırır, yıldızı kaydeder ve çalışma
/// süresini güne yazar. Adım bitince aynı dersin sıradaki adımına geçilebilir.
final class GuitarStepScreen extends StatefulWidget {
  const GuitarStepScreen({
    super.key,
    required this.stepId,
    this.repo,
    this.env = const StepEnv(),
    this.clock,
  });

  final String stepId;
  final PracticePrefsRepository? repo;
  final StepEnv env;
  final GuitarPracticeClock? clock;

  @override
  State<GuitarStepScreen> createState() => _GuitarStepScreenState();
}

final class _GuitarStepScreenState extends State<GuitarStepScreen> with WidgetsBindingObserver {
  late final PracticePrefsRepository _repo = widget.repo ?? PracticePrefsRepository();
  late final GuitarPracticeClock _clock = widget.clock ?? GuitarPracticeClock(repo: _repo);
  late GuitarStep _step = GuitarPath.stepById(widget.stepId)!;
  PracticePrefs _prefs = const PracticePrefs();
  var _loaded = false;
  var _saved = 0;
  var _viewKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock.resume();
    _load();
  }

  Future<void> _load() async {
    final p = await _repo.load();
    if (!mounted) return;
    setState(() {
      _prefs = p;
      _saved = p.guitarStepStars[_step.id] ?? 0;
      _loaded = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clock.resume();
    } else {
      _clock.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.commit();
    super.dispose();
  }

  Future<void> _onFinished(int stars) async {
    // Kayıt sürerken ekran bir sonraki adıma geçebilir: kimliği baştan al.
    final id = _step.id;
    final fresh = await _repo.load();
    final next = fresh.withStepStars(id, stars);
    await _repo.save(next);
    if (!mounted) return;
    setState(() {
      _prefs = next;
      if (_step.id == id) _saved = next.guitarStepStars[id] ?? 0;
    });
  }

  Future<void> _onBest(String key, int value) async {
    final fresh = await _repo.load();
    final next = fresh.withGuitarBest(key, value);
    await _repo.save(next);
    if (!mounted) return;
    setState(() => _prefs = next);
  }

  void _next() {
    final lesson = GuitarPath.lessonOfStep(_step.id);
    if (lesson == null) {
      Navigator.of(context).pop();
      return;
    }
    final i = lesson.steps.indexWhere((s) => s.id == _step.id);
    if (i >= 0 && i + 1 < lesson.steps.length) {
      setState(() {
        _step = lesson.steps[i + 1];
        _saved = _prefs.guitarStepStars[_step.id] ?? 0;
        _viewKey++;
      });
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('“${lesson.title}” dersi bitti. Harika!')),
    );
  }

  Widget _body() {
    final key = ValueKey('${_step.id}#$_viewKey');
    switch (_step.kind) {
      case GuitarStepKind.info:
      case GuitarStepKind.tuner:
        return InfoStepView(key: key, step: _step, onFinished: _onFinished, onNext: _next);
      case GuitarStepKind.openStrings:
        return OpenStringsView(
            key: key, step: _step, env: widget.env, onFinished: _onFinished, onNext: _next);
      case GuitarStepKind.chordPlay:
        return ChordPlayView(
            key: key, step: _step, env: widget.env, onFinished: _onFinished, onNext: _next);
      case GuitarStepKind.changes:
        final k = 'changes:${_step.chordIds[0]}-${_step.chordIds[1]}';
        return ChangesView(
          key: key,
          step: _step,
          env: widget.env,
          onFinished: _onFinished,
          onNext: _next,
          onBest: _onBest,
          bestSoFar: _prefs.guitarBests[k],
        );
      case GuitarStepKind.strum:
      case GuitarStepKind.progression:
        return StrumView(
            key: key, step: _step, env: widget.env, onFinished: _onFinished, onNext: _next);
      case GuitarStepKind.earPlay:
        return EarPlayView(
            key: key, step: _step, env: widget.env, onFinished: _onFinished, onNext: _next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              ExerciseScreenTopBar(
                title: _step.title,
                subtitle: _step.subtitle.isEmpty ? null : _step.subtitle,
                trailing: _step.isScored ? StarRow(stars: _saved, size: 18) : null,
              ),
              Expanded(
                child: _loaded
                    ? _body()
                    : const Center(
                        child: CircularProgressIndicator(color: DesignTokens.blue500),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

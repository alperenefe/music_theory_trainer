import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/practice_prefs.dart';
import '../../services/practice_prefs_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

Future<void> showAppOnboardingDialog({
  required BuildContext context,
  required PracticePrefsRepository repo,
}) async {
  final prefs = await repo.load();
  if (!context.mounted) {
    return;
  }
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim, _) {
      return _OnboardingBody(repo: repo, initial: prefs);
    },
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.96,
            end: 1,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

final class _OnboardingBody extends StatefulWidget {
  const _OnboardingBody({required this.repo, required this.initial});

  final PracticePrefsRepository repo;
  final PracticePrefs initial;

  @override
  State<_OnboardingBody> createState() => _OnboardingBodyState();
}

final class _OnboardingBodyState extends State<_OnboardingBody> {
  final _pc = PageController();
  var _page = 0;
  var _finishing = false;

  Future<void> _finish() async {
    if (_finishing) {
      return;
    }
    _finishing = true;
    try {
      final next = widget.initial.copyWith(onboardingDone: true);
      await widget.repo.save(next);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      _finishing = false;
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _finish();
      },
      child: Center(
        child: Material(
          color: DesignTokens.slate900,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: mq.size.height * 0.78,
            ),
            child: Padding(
              padding: AppSpacing.cardPad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 220,
                    child: PageView(
                      controller: _pc,
                      onPageChanged: (i) => setState(() => _page = i),
                      children: [
                        _ObPage(
                          title: AppStrings.ob1Title,
                          body: AppStrings.ob1Body,
                          t: t,
                        ),
                        _ObPage(
                          title: AppStrings.ob2Title,
                          body: AppStrings.ob2Body,
                          t: t,
                        ),
                        _ObPage(
                          title: AppStrings.ob3Title,
                          body: AppStrings.ob3Body,
                          t: t,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final on = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: on ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: on
                              ? DesignTokens.blue500
                              : DesignTokens.slate600,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (_page > 0)
                        TextButton(
                          onPressed: () => _pc.previousPage(
                            duration: AppMotion.medium,
                            curve: AppMotion.curve,
                          ),
                          child: Text(AppStrings.back),
                        ),
                      const Spacer(),
                      if (_page < 2)
                        FilledButton(
                          onPressed: () => _pc.nextPage(
                            duration: AppMotion.medium,
                            curve: AppMotion.curve,
                          ),
                          child: Text(AppStrings.obNext),
                        )
                      else
                        FilledButton(
                          onPressed: _finish,
                          child: Text(AppStrings.obStart),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ObPage extends StatelessWidget {
  const _ObPage({required this.title, required this.body, required this.t});

  final String title;
  final String body;
  final TextTheme t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: t.titleLarge?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          body,
          style: t.bodyMedium?.copyWith(
            color: DesignTokens.slate400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

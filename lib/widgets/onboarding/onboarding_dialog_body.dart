import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/practice_prefs.dart';
import '../../services/practice_prefs_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'onboarding_page.dart';

final class OnboardingDialogBody extends StatefulWidget {
  const OnboardingDialogBody({
    super.key,
    required this.repo,
    required this.initial,
  });

  final PracticePrefsRepository repo;
  final PracticePrefs initial;

  @override
  State<OnboardingDialogBody> createState() => _OnboardingDialogBodyState();
}

final class _OnboardingDialogBodyState extends State<OnboardingDialogBody> {
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
                        OnboardingPage(
                          title: AppStrings.ob1Title,
                          body: AppStrings.ob1Body,
                          textTheme: t,
                        ),
                        OnboardingPage(
                          title: AppStrings.ob2Title,
                          body: AppStrings.ob2Body,
                          textTheme: t,
                        ),
                        OnboardingPage(
                          title: AppStrings.ob3Title,
                          body: AppStrings.ob3Body,
                          textTheme: t,
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

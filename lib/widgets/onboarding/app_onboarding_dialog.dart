import 'package:flutter/material.dart';

import '../../services/practice_prefs_repository.dart';
import 'onboarding_dialog_body.dart';

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
      return OnboardingDialogBody(repo: repo, initial: prefs);
    },
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/app_distribution_update.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

/// Firebase App Distribution — «Guncellemeyi kontrol et».
final class AppUpdateCard extends StatefulWidget {
  const AppUpdateCard({super.key});

  @override
  State<AppUpdateCard> createState() => _AppUpdateCardState();
}

final class _AppUpdateCardState extends State<AppUpdateCard> {
  var _busy = false;

  Future<void> _check() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final result = await AppDistributionUpdate.checkFromApp();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    final msg = switch (result) {
      AppUpdateResult.upToDate => AppStrings.appUpdateUpToDate,
      AppUpdateResult.updateStarted => AppStrings.appUpdateStarted,
      AppUpdateResult.debugBuild => AppStrings.appUpdateDebugOnly,
      AppUpdateResult.firebaseNotConfigured =>
        AppStrings.appUpdateFirebaseMissing,
      AppUpdateResult.failed => AppStrings.appUpdateFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SoftCard(
      padding: AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.appUpdateSection,
            style: t.titleSmall?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.appUpdateHint,
            style: t.bodySmall?.copyWith(
              color: DesignTokens.slate400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _busy ? null : _check,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_rounded),
            label: Text(AppStrings.appUpdateCheck),
          ),
        ],
      ),
    );
  }
}

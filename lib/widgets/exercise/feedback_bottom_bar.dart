import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../services/ui_chime_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'result_pill.dart';

final class FeedbackBottomBar extends StatefulWidget {
  const FeedbackBottomBar({
    super.key,
    required this.show,
    required this.correct,
    required this.onNext,
    this.wrongYourAnswer,
    this.wrongCorrectAnswer,
    this.successDetail,
  });

  final bool show;
  final bool correct;
  final VoidCallback onNext;
  final String? wrongYourAnswer;
  final String? wrongCorrectAnswer;
  final String? successDetail;

  @override
  State<FeedbackBottomBar> createState() => _FeedbackBottomBarState();
}

final class _FeedbackBottomBarState extends State<FeedbackBottomBar> {
  var _prevShow = false;

  @override
  void didUpdateWidget(covariant FeedbackBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !_prevShow) {
      if (widget.correct) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
      UiChimeService.instance.play(widget.correct);
    }
    _prevShow = widget.show;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) {
      return const SizedBox.shrink();
    }
    final t = Theme.of(context).textTheme;
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.curve,
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.slate900.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(
              color: DesignTokens.borderSubtle.withValues(alpha: 0.85),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: AppSpacing.screenH.copyWith(
              top: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResultPill(correct: widget.correct, visible: true),
                if (widget.correct &&
                    widget.successDetail != null &&
                    widget.successDetail!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.successDetail!,
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(
                      color: DesignTokens.slate300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (!widget.correct &&
                    (widget.wrongYourAnswer != null ||
                        widget.wrongCorrectAnswer != null)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (widget.wrongYourAnswer != null &&
                      widget.wrongYourAnswer!.isNotEmpty)
                    Text(
                      '${AppStrings.wrongYourPick}: ${widget.wrongYourAnswer}',
                      style: t.bodyMedium?.copyWith(
                        color: DesignTokens.slate300,
                        height: 1.45,
                      ),
                    ),
                  if (widget.wrongCorrectAnswer != null &&
                      widget.wrongCorrectAnswer!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${AppStrings.wrongCorrectIs}: ${widget.wrongCorrectAnswer}',
                      style: t.bodyMedium?.copyWith(
                        color: DesignTokens.green400,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: widget.onNext,
                  child: Text(AppStrings.next),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

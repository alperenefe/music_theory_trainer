import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../services/ui_chime_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'result_pill.dart';

/// [placementCompact]: cevap portede gösterilir; altta yalnızca özet + Sonraki.
/// [inlineCompact]: tek satır bordered kutu + sağda Sonraki (MCQ vb.).
enum FeedbackBottomBarStyle { standard, placementCompact, inlineCompact }

final class FeedbackBottomBar extends StatefulWidget {
  const FeedbackBottomBar({
    super.key,
    required this.show,
    required this.correct,
    required this.onNext,
    this.wrongYourAnswer,
    this.wrongCorrectAnswer,
    this.successDetail,
    this.placementOffsetHint,
    this.style = FeedbackBottomBarStyle.standard,
    this.embedded = false,
  });

  final bool show;
  final bool correct;
  final VoidCallback onNext;
  final String? wrongYourAnswer;
  final String? wrongCorrectAnswer;
  final String? successDetail;
  /// Porte yerleştir: «2 alt» / «1 üst» gibi.
  final String? placementOffsetHint;
  final FeedbackBottomBarStyle style;
  /// Sabit alt slotta; overlay değil — porte yüksekliği değişmez.
  final bool embedded;

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
    final placementCompact =
        widget.style == FeedbackBottomBarStyle.placementCompact;
    final inlineCompact = widget.style == FeedbackBottomBarStyle.inlineCompact;
    final compact = placementCompact || inlineCompact;
    final showWrongLines =
        !widget.correct && !compact && !inlineCompact;
    final showPlacementHint = !widget.correct &&
        placementCompact &&
        widget.placementOffsetHint != null &&
        widget.placementOffsetHint!.isNotEmpty;

    if (inlineCompact) {
      final summary = widget.correct
          ? (widget.successDetail?.isNotEmpty == true
              ? widget.successDetail!
              : AppStrings.correct)
          : [
              if (widget.wrongYourAnswer?.isNotEmpty == true)
                '${AppStrings.wrongYourPick}: ${widget.wrongYourAnswer}',
              if (widget.wrongCorrectAnswer?.isNotEmpty == true)
                '${AppStrings.wrongCorrectIs}: ${widget.wrongCorrectAnswer}',
            ].join(' · ');
      final borderColor = widget.correct
          ? DesignTokens.green400.withValues(alpha: 0.65)
          : DesignTokens.streakOrange.withValues(alpha: 0.65);
      final fill = widget.correct
          ? DesignTokens.green400.withValues(alpha: 0.12)
          : DesignTokens.streakOrange.withValues(alpha: 0.12);

      final inlineBody = Padding(
        padding: AppSpacing.screenH.copyWith(
          top: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: widget.onNext,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.white,
                foregroundColor: DesignTokens.slate900,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              child: Text(AppStrings.next),
            ),
          ],
        ),
      );
      if (widget.embedded) {
        return inlineBody;
      }
      return Container(
        decoration: BoxDecoration(
          color: DesignTokens.slate900.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(
              color: DesignTokens.borderSubtle.withValues(alpha: 0.85),
            ),
          ),
        ),
        child: SafeArea(top: false, child: inlineBody),
      );
    }

    final body = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResultPill(correct: widget.correct, visible: true),
        if (widget.correct &&
            widget.successDetail != null &&
            widget.successDetail!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.successDetail!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall?.copyWith(
              color: DesignTokens.slate300,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (showPlacementHint) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${AppStrings.placementOffsetLabel}: ${widget.placementOffsetHint}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall?.copyWith(
              color: DesignTokens.slate400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (showWrongLines &&
            (widget.wrongYourAnswer != null ||
                widget.wrongCorrectAnswer != null)) ...[
          const SizedBox(height: AppSpacing.xs),
          if (widget.wrongYourAnswer != null &&
              widget.wrongYourAnswer!.isNotEmpty)
            Text(
              '${AppStrings.wrongYourPick}: ${widget.wrongYourAnswer}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(
                color: DesignTokens.slate300,
                height: 1.35,
              ),
            ),
          if (widget.wrongCorrectAnswer != null &&
              widget.wrongCorrectAnswer!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${AppStrings.wrongCorrectIs}: ${widget.wrongCorrectAnswer}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(
                color: DesignTokens.green400,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: widget.onNext,
          child: Text(AppStrings.next),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Container(
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
          child: body,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/ear_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

/// Cevaptan sonra alttan kayan geri bildirim paneli (Duolingo / Perfect Ear
/// tarzı): doğru/yanlış, doğru cevap, kısa teori notu, karşılaştırmalı dinleme
/// ve kullanıcının kendi hızında "Devam".
final class EarFeedbackPanel extends StatelessWidget {
  const EarFeedbackPanel({
    super.key,
    required this.correct,
    required this.correctLabel,
    required this.onContinue,
    this.yourLabel,
    this.explanation,
    this.contrastTip,
    this.yourSong,
    this.onAddSong,
    this.onListenYours,
    this.onListenCorrect,
    this.comboMessage,
    this.compareHint,
    this.continueLabel = EarStrings.continueLabel,
  });

  final bool correct;
  final String correctLabel;
  final String? yourLabel;
  final String? explanation;

  /// Yalnızca yanlış cevapta: seçilen ile doğru cevap arasındaki fark.
  final String? contrastTip;

  /// Kullanıcının bu aralık için kaydettiği kendi şarkısı (yalnızca yanlışta).
  final String? yourSong;

  /// Kayıtlı şarkı yoksa "Kendi şarkını ekle" düğmesinin eylemi.
  final VoidCallback? onAddSong;
  final VoidCallback onContinue;
  final VoidCallback? onListenYours;
  final VoidCallback? onListenCorrect;
  final String? comboMessage;
  final String? compareHint;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final accent = correct ? DesignTokens.earEmerald : DesignTokens.earRose;
    final textAccent = correct ? p.success : p.danger;

    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: p.dark ? 0.16 : 0.1),
          p.dark ? DesignTokens.slate900 : Colors.white,
        ),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.7), width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    child: Icon(
                      correct ? Icons.check_rounded : Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          correct ? EarStrings.correctTitle : EarStrings.wrongTitle,
                          style: t.titleLarge?.copyWith(color: textAccent, fontWeight: FontWeight.w900),
                        ),
                        if (!correct)
                          Text(
                            EarStrings.correctAnswerIs(correctLabel),
                            style: t.bodyMedium?.copyWith(
                              color: p.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else if (comboMessage != null)
                          Text(
                            comboMessage!,
                            style: t.bodyMedium?.copyWith(
                              color: DesignTokens.streakOrange,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!correct && contrastTip != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: DesignTokens.earGold.withValues(alpha: p.dark ? 0.12 : 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: const Border(left: BorderSide(color: DesignTokens.earGold, width: 3)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          EarStrings.contrastTitle,
                          style: t.labelMedium?.copyWith(
                            color: DesignTokens.earGold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (yourSong != null) ...[
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '🎵 ${EarStrings.yourSong}: ',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                TextSpan(text: yourSong),
                              ],
                            ),
                            style: t.bodyMedium?.copyWith(color: p.textPrimary, height: 1.4),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          contrastTip!,
                          style: t.bodySmall?.copyWith(color: p.textPrimary, height: 1.4),
                        ),
                        if (yourSong == null && onAddSong != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: onAddSong,
                              icon: const Icon(Icons.library_music_rounded, size: 18),
                              label: const Text(EarStrings.addYourSong),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: DesignTokens.earGold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (explanation != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  explanation!,
                  style: t.bodySmall?.copyWith(color: p.textSecondary, height: 1.4),
                ),
              ],
              if (!correct && (onListenYours != null || onListenCorrect != null)) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (onListenYours != null)
                      _ListenChip(
                        label: yourLabel == null
                            ? EarStrings.listenYours
                            : '${EarStrings.listenYours}: $yourLabel',
                        color: DesignTokens.earRose,
                        onTap: onListenYours!,
                      ),
                    if (onListenCorrect != null)
                      _ListenChip(
                        label: EarStrings.listenCorrect,
                        color: DesignTokens.earEmerald,
                        onTap: onListenCorrect!,
                      ),
                  ],
                ),
              ],
              if (compareHint != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(compareHint!, style: t.labelSmall?.copyWith(color: p.textMuted)),
              ],
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                autofocus: false,
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  textStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.4),
                ),
                child: Text(continueLabel),
              ),
            ],
          ),
        ),
      ),
    );

    if (!AppMotion.reduced(context)) {
      panel = panel
          .animate()
          .slideY(begin: 0.35, end: 0, duration: 260.ms, curve: Curves.easeOutCubic)
          .fadeIn(duration: 180.ms);
    }
    return panel;
  }
}

final class _ListenChip extends StatelessWidget {
  const _ListenChip({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    return ActionChip(
      avatar: Icon(Icons.volume_up_rounded, size: 18, color: color),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
          ),
      side: BorderSide(color: color.withValues(alpha: 0.6)),
      backgroundColor: color.withValues(alpha: 0.1),
      onPressed: onTap,
    );
  }
}

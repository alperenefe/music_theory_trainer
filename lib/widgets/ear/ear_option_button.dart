import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

enum EarOptionState {
  /// Henüz cevaplanmadı.
  idle,

  /// Kullanıcı bunu seçti ve doğru.
  correct,

  /// Kullanıcı bunu seçti ve yanlış.
  wrong,

  /// Kullanıcı yanlış seçti; doğru cevap bu (vurgulanır).
  revealedCorrect,

  /// Cevaplandıktan sonra ilgisiz seçenek (soluk, ama dinlenebilir).
  dimmed,
}

final class EarOptionButton extends StatelessWidget {
  const EarOptionButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.state,
    required this.onTap,
    this.shortcutLabel,
    this.showListenIcon = false,
    this.accentColor = DesignTokens.blue500,
  });

  final String title;
  final String? subtitle;
  final EarOptionState state;

  /// Cevap öncesi: seçim. Cevap sonrası: seçeneğin sesini dinletme.
  final VoidCallback? onTap;

  /// Masaüstünde klavye kısayolu rozeti (ör. "1").
  final String? shortcutLabel;

  /// Cevap sonrası karşılaştırmalı dinleme ikonu.
  final bool showListenIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;

    final (Color bg, Color border, Color titleColor, IconData? icon, Color? iconColor) =
        switch (state) {
      EarOptionState.idle => (p.surface, p.border, p.textPrimary, null, null),
      EarOptionState.correct => (
          DesignTokens.earEmerald.withValues(alpha: p.dark ? 0.24 : 0.14),
          DesignTokens.earEmerald,
          p.textPrimary,
          Icons.check_circle_rounded,
          p.success,
        ),
      EarOptionState.wrong => (
          DesignTokens.earRose.withValues(alpha: p.dark ? 0.24 : 0.12),
          DesignTokens.earRose,
          p.textPrimary,
          Icons.cancel_rounded,
          p.danger,
        ),
      EarOptionState.revealedCorrect => (
          DesignTokens.earEmerald.withValues(alpha: p.dark ? 0.12 : 0.08),
          DesignTokens.earEmerald.withValues(alpha: 0.8),
          p.success,
          Icons.check_circle_outline_rounded,
          p.success,
        ),
      EarOptionState.dimmed => (
          p.surface.withValues(alpha: p.dark ? 0.55 : 0.7),
          p.border.withValues(alpha: 0.6),
          p.textMuted,
          null,
          null,
        ),
    };
    final emphasized = state != EarOptionState.idle && state != EarOptionState.dimmed;
    final radius = BorderRadius.circular(AppRadii.md);

    Widget button = Semantics(
      button: true,
      selected: state == EarOptionState.correct || state == EarOptionState.wrong,
      label: subtitle == null ? title : '$title. $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.dur(context, const Duration(milliseconds: 220)),
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: border, width: emphasized ? 2 : 1.2),
          boxShadow: [
            if (state == EarOptionState.correct) ...[
              BoxShadow(
                color: DesignTokens.earEmerald.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: DesignTokens.earEmerald.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ] else if (state == EarOptionState.idle)
              BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            splashColor: accentColor.withValues(alpha: 0.12),
            highlightColor: accentColor.withValues(alpha: 0.06),
            onTap: onTap == null
                ? null
                : () {
                    if (state == EarOptionState.idle) HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    if (shortcutLabel != null) ...[
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: p.border, width: 1.2),
                        ),
                        child: Text(
                          shortcutLabel!,
                          style: t.labelMedium?.copyWith(
                            color: p.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: t.titleSmall?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(color: p.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showListenIcon) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.volume_up_rounded, size: 18, color: p.textMuted),
                    ],
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: iconColor, size: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!AppMotion.reduced(context)) {
      button = button
          .animate(target: state == EarOptionState.wrong ? 1 : 0)
          .shakeX(hz: 5, amount: 5, duration: 380.ms)
          .animate(target: state == EarOptionState.correct ? 1 : 0)
          .scaleXY(begin: 1, end: 1.06, duration: 180.ms, curve: Curves.easeOutBack)
          .then()
          .scaleXY(begin: 1.06, end: 1, duration: 220.ms, curve: Curves.easeInOut);
    }
    return button;
  }
}

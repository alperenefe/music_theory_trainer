import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_question.dart';
import '../../theme/design_tokens.dart';
import 'ear_option_button.dart';

/// Bas avcısı için gerçekçi mini gitar klavyesi (5. ve 6. tel).
///
/// Tab okuma alışkanlığına uygun olarak kalın tel (6) altta durur. Dar
/// ekranda perdeler yatay kaydırılır; genişte tüm alanı doldurur.
final class EarFretAnswerBoard extends StatelessWidget {
  const EarFretAnswerBoard({
    super.key,
    required this.options,
    required this.stateOf,
    required this.onTap,
  });

  final List<EarAnswerOption> options;
  final EarOptionState Function(String optionId) stateOf;
  final void Function(String optionId) onTap;

  static const _labelWidth = 44.0;
  static const _minCell = 46.0;
  static const _rowHeight = 56.0;
  static const _inlays = {3, 5, 7, 9, 12};

  @override
  Widget build(BuildContext context) {
    final frets = <int>[];
    final strings = <int>[];
    for (final o in options) {
      if (o.fret != null && !frets.contains(o.fret)) frets.add(o.fret!);
      if (o.stringNumber != null && !strings.contains(o.stringNumber)) {
        strings.add(o.stringNumber!);
      }
    }
    frets.sort();
    strings.sort(); // 5 üstte, 6 altta

    EarAnswerOption? find(int s, int f) {
      for (final o in options) {
        if (o.stringNumber == s && o.fret == f) return o;
      }
      return null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - _labelWidth;
        final cell = math.max(_minCell, available / math.max(1, frets.length));
        final boardWidth = cell * frets.length;
        final t = Theme.of(context).textTheme;

        final board = Container(
          width: boardWidth,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [DesignTokens.fretboardWoodMid, DesignTokens.fretboardWoodDark],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
            children: [
              // Perde numaraları + inlay noktaları
              Row(
                children: [
                  for (final f in frets)
                    SizedBox(
                      width: cell,
                      height: 24,
                      child: Center(
                        child: Text(
                          f == 0 ? EarStrings.openString : '$f',
                          style: t.labelSmall?.copyWith(
                            color: _inlays.contains(f)
                                ? DesignTokens.fretboardFretGold
                                : DesignTokens.fretboardStringTint,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (final s in strings)
                SizedBox(
                  height: _rowHeight,
                  child: Stack(
                    children: [
                      // Tel çizgisi (kalın tel daha kalın)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            height: s == 6 ? 3.2 : 2.4,
                            color: DesignTokens.fretboardFretLine.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final f in frets)
                            _FretCell(
                              width: cell,
                              isNut: f == 0,
                              option: find(s, f),
                              stateOf: stateOf,
                              onTap: onTap,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
          ),
        );

        final labels = SizedBox(
          width: _labelWidth,
          child: Column(
            children: [
              const SizedBox(height: 24),
              for (final s in strings)
                SizedBox(
                  height: _rowHeight,
                  child: Center(
                    child: Text(
                      s == 6 ? 'E' : 'A',
                      semanticsLabel: EarStrings.stringLabel(s),
                      style: t.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labels,
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: board,
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _FretCell extends StatelessWidget {
  const _FretCell({
    required this.width,
    required this.isNut,
    required this.option,
    required this.stateOf,
    required this.onTap,
  });

  final double width;
  final bool isNut;
  final EarAnswerOption? option;
  final EarOptionState Function(String) stateOf;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final o = option;
    final state = o == null ? EarOptionState.idle : stateOf(o.id);
    final (Color fill, Color ring) = switch (state) {
      EarOptionState.correct => (DesignTokens.earEmerald, Colors.white),
      EarOptionState.wrong => (DesignTokens.earRose, Colors.white),
      EarOptionState.revealedCorrect => (
          DesignTokens.earEmerald.withValues(alpha: 0.35),
          DesignTokens.earEmerald,
        ),
      EarOptionState.dimmed => (
          const Color(0x33000000),
          DesignTokens.fretboardStringTint.withValues(alpha: 0.5),
        ),
      EarOptionState.idle => (
          const Color(0x4D000000),
          DesignTokens.fretboardFretGold.withValues(alpha: 0.7),
        ),
    };

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: isNut ? const Color(0xFFF1E6D0) : DesignTokens.fretboardFretGold.withValues(alpha: 0.65),
            width: isNut ? 4 : 2,
          ),
        ),
      ),
      child: o == null
          ? null
          : Semantics(
              button: true,
              label: EarStrings.fretPosition(o.stringNumber ?? 0, o.fret ?? 0),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(o.id);
                },
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                      border: Border.all(color: ring, width: 2),
                    ),
                    child: switch (state) {
                      EarOptionState.correct ||
                      EarOptionState.revealedCorrect =>
                        const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      EarOptionState.wrong =>
                        const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      _ => null,
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

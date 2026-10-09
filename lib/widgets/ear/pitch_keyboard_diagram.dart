import 'package:flutter/material.dart';

import '../../audio/ear_sound.dart';
import '../../theme/design_tokens.dart';

/// Bir [EarSound]'un içerdiği notaları basit, salt-görsel bir piyano
/// klavyesi üzerinde gösterir.
///
/// Amaç: ders ekranında sesi dinlerken notaların birbirine göre konumunu
/// göze de göstermek (kulak + göz + metin). Etkileşimsizdir, sadece
/// [midis] listesindeki notaları vurgular; ilk eleman kök nota kabul edilir
/// ve farklı renkte gösterilir.
final class PitchKeyboardDiagram extends StatelessWidget {
  const PitchKeyboardDiagram({super.key, required this.midis, this.accent});

  /// En az 1 eleman. İlk eleman kök (root) nota olarak vurgulanır.
  final List<int> midis;

  /// Kök notanın rengi; verilmezse [DesignTokens.blue500] kullanılır.
  final Color? accent;

  static const _ivory = Color(0xFFF7F2E7);
  static const _keyLine = Color(0xFFCBBFA0);
  static const _blackKey = Color(0xFF20242C);

  static const _whitePc = {0, 2, 4, 5, 7, 9, 11};
  static const _blackOffsetInOctave = {1: 0.65, 3: 1.65, 6: 3.65, 8: 4.65, 10: 5.65};
  static const _pcSolfege = {
    0: 'Do', 1: 'Do#', 2: 'Re', 3: 'Re#', 4: 'Mi', 5: 'Fa',
    6: 'Fa#', 7: 'Sol', 8: 'Sol#', 9: 'La', 10: 'La#', 11: 'Si',
  };

  /// [sound]'dan diyagram için nota listesi üretir. Kadans (CadenceSound)
  /// zamanla değişen çoklu akor içerdiği için statik bir diyagramla iyi
  /// anlatılamaz — bu durumda null döner (çağıran taraf diyagramı gizler).
  static List<int>? of(EarSound sound) => switch (sound) {
        NoteSound(:final midi) => [midi],
        IntervalSound(:final rootMidi, :final interval) => [
            rootMidi,
            rootMidi + interval.semitones,
          ],
        ChordSound(:final midis) => midis,
        ScaleSound(:final notes) => notes,
        SlashChordSound(:final bassMidi, :final upperMidis) => [bassMidi, ...upperMidis],
        CadenceSound() => null,
        HarmonicRhythmSound() => null,
      };

  @override
  Widget build(BuildContext context) {
    if (midis.isEmpty) return const SizedBox.shrink();
    final rootMidi = midis.first;
    final highlight = midis.toSet();
    final rootColor = accent ?? DesignTokens.blue500;
    const otherColor = DesignTokens.earViolet;

    final sorted = [...midis]..sort();
    final minMidi = sorted.first;
    final maxMidi = sorted.last;
    var floorC = minMidi - (minMidi % 12);
    var ceilC = maxMidi % 12 == 0 ? maxMidi : maxMidi + (12 - maxMidi % 12);
    if (ceilC <= floorC) ceilC = floorC + 12;

    final whiteMidis = <int>[];
    final blackMidis = <int>[];
    for (var m = floorC; m <= ceilC; m++) {
      if (_whitePc.contains(m % 12)) {
        whiteMidis.add(m);
      } else {
        blackMidis.add(m);
      }
    }

    const whiteWidth = 32.0;
    const blackWidth = whiteWidth * 0.6;
    const height = 88.0;
    const blackHeight = height * 0.58;
    final boardWidth = whiteMidis.length * whiteWidth;

    double blackX(int m) {
      final octaveIndex = (m - floorC) ~/ 12;
      final pc = m % 12;
      return (octaveIndex * 7 + _blackOffsetInOctave[pc]!) * whiteWidth - blackWidth / 2;
    }

    Color? highlightColorOf(int m) {
      if (!highlight.contains(m)) return null;
      return m == rootMidi ? rootColor : otherColor;
    }

    final noteNames = [for (final m in midis) _pcSolfege[m % 12]];

    return Semantics(
      label: 'Nota diyagramı: ${noteNames.join(', ')}',
      image: true,
      child: SizedBox(
        height: height,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: boardWidth,
            height: height,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (final m in whiteMidis)
                      _WhiteKey(
                        width: whiteWidth,
                        height: height,
                        color: highlightColorOf(m),
                        label: highlight.contains(m) ? _pcSolfege[m % 12]! : null,
                      ),
                  ],
                ),
                for (final m in blackMidis)
                  Positioned(
                    left: blackX(m),
                    top: 0,
                    child: _BlackKey(
                      width: blackWidth,
                      height: blackHeight,
                      color: highlightColorOf(m),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _WhiteKey extends StatelessWidget {
  const _WhiteKey({
    required this.width,
    required this.height,
    required this.color,
    required this.label,
  });

  final double width;
  final double height;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width - 1.5,
      height: height,
      margin: const EdgeInsets.only(right: 1.5),
      decoration: BoxDecoration(
        color: PitchKeyboardDiagram._ivory,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(color: PitchKeyboardDiagram._keyLine, width: 1),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 6),
      child: color == null
          ? null
          : Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                label ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

final class _BlackKey extends StatelessWidget {
  const _BlackKey({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? PitchKeyboardDiagram._blackKey,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(3),
          bottomRight: Radius.circular(3),
        ),
        border: color == null ? null : Border.all(color: Colors.white, width: 1.2),
      ),
    );
  }
}

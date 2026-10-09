import 'package:flutter/material.dart';

import '../../models/chord_shape.dart';
import '../../services/guitar_audio_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/background/mesh_gradient_backdrop.dart';
import '../../widgets/exercise/exercise_screen_top_bar.dart';
import '../../audio/ear_sound.dart';
import '../../widgets/guitar/chord_diagram.dart';

/// Tüm akor şemaları; dokununca akorun sesi çalınır.
final class ChordLibraryScreen extends StatelessWidget {
  const ChordLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              const ExerciseScreenTopBar(
                title: 'Akor kütüphanesi',
                subtitle: 'Şemaya dokun, akorun sesini dinle',
              ),
              Expanded(
                child: GridView.count(
                  padding: AppSpacing.screenHV,
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.78,
                  children: [
                    for (final c in ChordLibrary.all)
                      Material(
                        color: DesignTokens.cardBg,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          onTap: () => GuitarAudioService.instance
                              .playSound(
                                HarmonicRhythmSound(chords: [c.midis], beatsPerChord: 1),
                                awaitRing: false,
                              ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Center(child: ChordDiagram(chord: c, width: 110)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

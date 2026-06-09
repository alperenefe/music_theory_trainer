import 'package:flutter/material.dart';

import '../background/mesh_gradient_backdrop.dart';
import 'home_list_skeleton.dart';

/// Egzersiz ekranlarında spinner yerine iskelet yükleme.
final class ExerciseLoadingBody extends StatelessWidget {
  const ExerciseLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(child: HomeListSkeleton()),
      ),
    );
  }
}

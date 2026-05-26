import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

abstract final class GuitarTunerConstants {
  static const List<int> stringOrder = [5, 4, 3, 2, 1, 0];

  static List<Color> get stringColors => DesignTokens.tunerStringColors;
}

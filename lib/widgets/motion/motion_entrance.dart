import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_spacing.dart';

extension MotionEntrance on Widget {
  Widget entranceFadeSlide(
    BuildContext context, {
    Duration duration = AppMotion.medium,
    Duration delay = Duration.zero,
    double slideY = 0.05,
    double? slideX,
  }) {
    if (AppMotion.reduced(context)) {
      return this;
    }
    var animated = animate().fadeIn(
      duration: duration,
      delay: delay,
      curve: AppMotion.curve,
    );
    if (slideX != null) {
      animated = animated.slideX(
        begin: slideX,
        end: 0,
        duration: duration,
        delay: delay,
        curve: AppMotion.curve,
      );
    } else {
      animated = animated.slideY(
        begin: slideY,
        end: 0,
        duration: duration,
        delay: delay,
        curve: AppMotion.curve,
      );
    }
    return animated;
  }

  Widget entranceFadeScale(
    BuildContext context, {
    Duration duration = AppMotion.medium,
    Offset begin = const Offset(0.92, 0.92),
  }) {
    if (AppMotion.reduced(context)) {
      return this;
    }
    return animate()
        .fadeIn(duration: duration, curve: AppMotion.curve)
        .scale(
          begin: begin,
          end: const Offset(1, 1),
          duration: duration,
          curve: AppMotion.curve,
        );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_spacing.dart';

/// Kart ve CTA'larda Duolingo/Things tarzı basma geri bildirimi.
final class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.haptic = true,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool haptic;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

final class _PressableScaleState extends State<PressableScale> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || widget.onTap == null) {
      return;
    }
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) {
      return;
    }
    if (widget.haptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: active ? (_) => _setPressed(true) : null,
      onTapUp: active ? (_) => _setPressed(false) : null,
      onTapCancel: active ? () => _setPressed(false) : null,
      onTap: active ? _handleTap : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}

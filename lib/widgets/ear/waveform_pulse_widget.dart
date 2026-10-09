import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

/// Büyük "dinle" butonu; ses çalarken dışa doğru yayılan halkalar çizer.
///
/// Animasyon yalnızca çalarken döner (boşta pil harcamaz) ve
/// "animasyonları azalt" ayarında tamamen durur.
final class WaveformPulseWidget extends StatefulWidget {
  const WaveformPulseWidget({
    super.key,
    required this.isPlaying,
    required this.onPlayTap,
    this.accentColor = DesignTokens.earAmber,
    this.size = 130.0,
    this.label = 'Dinle',
  });

  final bool isPlaying;
  final VoidCallback onPlayTap;
  final Color accentColor;
  final double size;
  final String label;

  @override
  State<WaveformPulseWidget> createState() => _WaveformPulseWidgetState();
}

final class _WaveformPulseWidgetState extends State<WaveformPulseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant WaveformPulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _sync();
  }

  void _sync() {
    final animate = widget.isPlaying && !AppMotion.reduced(context);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final size = widget.size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    size: Size(size, size),
                    painter: _WaveformPulsePainter(
                      progress: _controller.value,
                      isPlaying: widget.isPlaying,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: widget.label,
                child: Material(
                  color: widget.accentColor.withValues(alpha: p.dark ? 0.2 : 0.14),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onPlayTap,
                    child: Container(
                      width: size * 0.6,
                      height: size * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.accentColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.3),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isPlaying
                            ? Icons.graphic_eq_rounded
                            : Icons.play_arrow_rounded,
                        color: p.dark ? DesignTokens.white : widget.accentColor,
                        size: size * 0.28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: p.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

final class _WaveformPulsePainter extends CustomPainter {
  const _WaveformPulsePainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
  });

  final double progress;
  final bool isPlaying;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final minRadius = size.width * 0.3;

    if (!isPlaying) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, minRadius + (maxRadius - minRadius) * 0.45, paint);
      return;
    }

    const ringCount = 3;
    for (var i = 0; i < ringCount; i++) {
      final ringProgress = (progress + (i / ringCount)) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * ringProgress;
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.45;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPulsePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isPlaying != isPlaying ||
      oldDelegate.color != color;
}

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Porte üzerinde sürüklerken üstteki ScrollView kaymasın.
final class StaffScrollBlocker extends StatelessWidget {
  const StaffScrollBlocker({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
          VerticalDragGestureRecognizer.new,
          (VerticalDragGestureRecognizer i) {
            i.onStart = (_) {};
            i.onUpdate = (_) {};
            i.onEnd = (_) {};
          },
        ),
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

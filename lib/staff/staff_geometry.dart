import 'package:flutter/material.dart';

final class StaffGeometry {
  StaffGeometry(this.size);

  final Size size;

  double get bottomLineY => size.height * 0.78;

  double get lineGap => size.height * 0.095;

  double get halfStep => lineGap * 0.5;

  double yForSlot(int slot) => bottomLineY - slot * halfStep;

  double get clefX => size.width * 0.11;

  double get noteHeadX => size.width * 0.52;

  List<double> mainLineYs() => [0, 2, 4, 6, 8].map(yForSlot).toList();

  int nearestSlotForY(double y, Iterable<int> slots) {
    var best = slots.first;
    var bestD = (y - yForSlot(best)).abs();
    for (final s in slots) {
      final d = (y - yForSlot(s)).abs();
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return best;
  }

  @override
  bool operator ==(Object other) =>
      other is StaffGeometry && other.size == size;

  @override
  int get hashCode => Object.hash(size.width, size.height);
}

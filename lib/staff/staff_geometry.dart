import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/notation_pitch.dart';

final class StaffGeometry {
  StaffGeometry._(
    this.size,
    this.slotMin,
    this.slotMax, {
    this.exercisePoolMin,
    this.exercisePoolMax,
  });

  // Sol anahtarı 5 ana çizgi: slot 0 (yazılan E4) … slot 8; ince Mi açık yazımı slot 7 (üst aralık).
  static const int _staffLineMin = 0;
  static const int _staffLineMax = 8;

  final Size size;
  final int slotMin;
  final int slotMax;
  final int? exercisePoolMin;
  final int? exercisePoolMax;

  bool get _isExerciseLayout =>
      exercisePoolMin != null && exercisePoolMax != null;

  factory StaffGeometry(Size size, {int? slotMin, int? slotMax}) {
    final all = [...NotationPitch.allStaffSlots()]..sort();
    var lo = (slotMin ?? all.first) - 3;
    var hi = (slotMax ?? all.last) + 3;
    if (lo > _staffLineMin) lo = _staffLineMin;
    if (hi < _staffLineMax) hi = _staffLineMax;
    return StaffGeometry._(size, lo, hi);
  }

  /// Mi2…La4: tek tip dikey aralık (çizgi–aralık–çizgi), porte altı doğru sırada.
  factory StaffGeometry.forExercisePool(
    Size size, {
    required int poolSlotMin,
    required int poolSlotMax,
  }) {
    final lo = math.min(poolSlotMin - 1, _staffLineMin - 1);
    final hi = math.max(_staffLineMax, poolSlotMax);
    return StaffGeometry._(
      size,
      lo,
      hi,
      exercisePoolMin: poolSlotMin,
      exercisePoolMax: poolSlotMax,
    );
  }

  static const double _padV = 10;
  static const double _headClear = 8;
  static const double _noteHeadHalfH = 10;

  double get _span => (slotMax - slotMin).clamp(1, 999).toDouble();

  /// Porte üstündeki La/Si için ekstra üst boşluk (nota kafası kırpılmasın).
  double get _extraTopForLedgersAbove =>
      _isExerciseLayout && slotMax > _staffLineMax
          ? _noteHeadHalfH + 10
          : 0;

  double get _drawTop => _padV + _headClear + _extraTopForLedgersAbove;

  double get _drawBottom => size.height - _padV - _headClear;

  double get _drawH => _drawBottom - _drawTop;

  double yForSlot(int slot) {
    if (_isExerciseLayout) {
      return _yForSlotExercise(slot);
    }
    return _drawTop + (slotMax - slot) / _span * _drawH;
  }

  /// En yüksek slot (poolSlotMax, örn. 11 Si) üstte; slot 0 alt çizgi.
  double _yForSlotExercise(int slot) {
    final hi = slotMax;
    final lo = slotMin;
    final span = (hi - lo).clamp(1, 999);
    return _drawTop + (hi - slot) / span * _drawH;
  }

  /// Nota kafası tamamen görünür mü (layout testleri).
  bool slotFitsVertically(int slot, {double margin = _noteHeadHalfH}) {
    final y = yForSlot(slot);
    return y >= margin && y <= size.height - margin;
  }

  double get clefX => size.width * 0.1;

  double get noteHeadX => size.width * 0.52;

  List<double> mainLineYs() {
    return [0, 2, 4, 6, 8]
        .where((s) => s >= slotMin && s <= slotMax)
        .map(yForSlot)
        .toList();
  }

  double get clefFontSize {
    if (_isExerciseLayout) {
      final gap = (yForSlot(0) - yForSlot(2)).abs();
      return (gap * 5.5).clamp(48.0, 72.0);
    }
    final gap = (yForSlot(0) - yForSlot(2)).abs();
    return (gap * 5.5).clamp(40.0, 64.0);
  }

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
      other is StaffGeometry &&
      other.size == size &&
      other.slotMin == slotMin &&
      other.slotMax == slotMax &&
      other.exercisePoolMin == exercisePoolMin &&
      other.exercisePoolMax == exercisePoolMax;

  @override
  int get hashCode => Object.hash(
        size.width,
        size.height,
        slotMin,
        slotMax,
        exercisePoolMin,
        exercisePoolMax,
      );
}

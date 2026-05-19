/// Porte altı/üstü kesikli yardımcı çizgileri — yalnızca çizgi slotlarında.

abstract final class StaffLedgerSlots {

  /// Çift slot = çizgi, tek slot = aralık (çizgi çizilmez).

  /// Porte altında: -2, -4, … en düşük çizgi notasına kadar (boşluk–çizgi sırası korunur).

  static List<int> forExerciseRange(Iterable<int> pickableSlots) {

    final list = pickableSlots.toList();

    if (list.isEmpty) {

      return const [];

    }

    final ledgers = <int>{};

    var minBelow = 0;

    var maxAbove = 8;

    for (final s in list) {

      if (s < minBelow) {

        minBelow = s;

      }

      if (s > maxAbove) {

        maxAbove = s;

      }

    }

    if (minBelow < 0) {

      for (var line = -2; line >= minBelow; line -= 2) {

        ledgers.add(line);

      }

    }

    if (maxAbove > 8) {

      for (var line = 10; line <= maxAbove; line += 2) {

        ledgers.add(line);

      }

    }

    final out = ledgers.toList()..sort();

    return out;

  }

}


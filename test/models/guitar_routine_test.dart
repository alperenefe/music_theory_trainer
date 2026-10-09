import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/guitar_path.dart';
import 'package:music_theory_trainer/models/guitar_routine.dart';

void main() {
  test('rutin 15 dakikadır', () {
    expect(GuitarRoutine.totalMinutes(GuitarRoutine.plan(const {})), 15);
  });

  test('hiçbir akor öğrenilmemişse akor değişimi/vuruş/döngü adımı önerilmez', () {
    final plan = GuitarRoutine.plan(const {});
    expect(plan[0].stepId, 'l0b.open');
    expect(plan[1].stepId, isNull);
    expect(plan[2].stepId, isNull);
    expect(plan[3].stepId, isNull);
    expect(plan.last.opensEar, isTrue);
  });

  test('D ve A çalınınca D–A değişimi ve D vuruşu açılır', () {
    final plan = GuitarRoutine.plan(const {'l1a.play': 2, 'l1b.play': 1});
    expect(plan[1].stepId, 'l1c.changes');
    expect(plan[2].stepId, 'l1d.strum');
  });

  test('3 yıldız alınan adımın yerine sıradaki 3 yıldızsız adım gelir', () {
    final plan = GuitarRoutine.plan(const {
      'l1a.play': 3,
      'l1b.play': 3,
      'l1c.changes': 3,
      'l1d.strum': 3,
      'l1d.strum2': 1,
    });
    expect(plan[2].stepId, 'l1d.strum2');
  });

  test('önerilen tüm adım kimlikleri gerçekten var', () {
    final all = {
      'l1a.play': 1, 'l1b.play': 1, 'l2a.play': 1, 'l3a.play': 1, 'l3b.play': 1,
      'l4a.play': 1, 'l5a.play': 1, 'l5b.play': 1, 'l6a.e7': 1, 'l6a.a7': 1, 'l6a.d7': 1,
      'l7a.as': 1,
    };
    for (final b in GuitarRoutine.plan(all)) {
      if (b.stepId != null) expect(GuitarPath.stepById(b.stepId!), isNotNull, reason: b.stepId);
    }
  });
}

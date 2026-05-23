import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/staff/staff_slot_offset.dart';

void main() {
  test('alt ve üst ifadeleri', () {
    expect(
      StaffSlotOffset.describe(correctSlot: 4, userSlot: 6),
      '2 alt',
    );
    expect(
      StaffSlotOffset.describe(correctSlot: 4, userSlot: 2),
      '2 üst',
    );
    expect(
      StaffSlotOffset.describe(correctSlot: 4, userSlot: 4),
      'Doğru çizgi',
    );
  });
}

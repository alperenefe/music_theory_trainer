/// Porte slot farkını Türkçe metin (ör. «2 alt», «1 üst»).
abstract final class StaffSlotOffset {
  /// [userSlot] − [correctSlot]: pozitif = kullanıcı hedeften daha alçak (ekranda aşağı).
  static String describe({required int correctSlot, required int userSlot}) {
    final delta = userSlot - correctSlot;
    if (delta == 0) {
      return 'Doğru çizgi';
    }
    if (delta > 0) {
      return delta == 1 ? '1 alt' : '$delta alt';
    }
    final up = -delta;
    return up == 1 ? '1 üst' : '$up üst';
  }
}

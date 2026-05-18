final class AppSoundPolicy {
  AppSoundPolicy._();
  static final AppSoundPolicy instance = AppSoundPolicy._();

  bool _enabled = true;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }
}

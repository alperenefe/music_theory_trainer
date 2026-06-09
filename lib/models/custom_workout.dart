import '../theory/music_interval.dart';

/// Kayıtlı özel antrenman ayarı (Perfect Ear tarzı özelleştirme).
final class CustomWorkout {
  const CustomWorkout({
    required this.exerciseKind,
    required this.minMidi,
    required this.maxMidi,
    this.intervalKinds = const [],
  });

  final String exerciseKind;
  final int minMidi;
  final int maxMidi;

  /// Boşsa tüm `MusicInterval.practiceSet` kullanılır.
  final List<String> intervalKinds;

  List<IntervalKind> resolvedIntervalKinds() {
    if (intervalKinds.isEmpty) {
      return MusicInterval.practiceSet;
    }
    final out = <IntervalKind>[];
    for (final name in intervalKinds) {
      for (final k in IntervalKind.values) {
        if (k.name == name) {
          out.add(k);
          break;
        }
      }
    }
    return out.isEmpty ? MusicInterval.practiceSet : out;
  }

  CustomWorkout copyWith({
    String? exerciseKind,
    int? minMidi,
    int? maxMidi,
    List<String>? intervalKinds,
  }) {
    return CustomWorkout(
      exerciseKind: exerciseKind ?? this.exerciseKind,
      minMidi: minMidi ?? this.minMidi,
      maxMidi: maxMidi ?? this.maxMidi,
      intervalKinds: intervalKinds ?? this.intervalKinds,
    );
  }

  Map<String, Object?> toJson() => {
        'exerciseKind': exerciseKind,
        'minMidi': minMidi,
        'maxMidi': maxMidi,
        'intervalKinds': intervalKinds,
      };

  static CustomWorkout fromJson(Map<String, Object?> j) {
    int ni(Object? v, int d) {
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return d;
    }

    final kindsRaw = j['intervalKinds'];
    final kinds = <String>[];
    if (kindsRaw is List) {
      for (final e in kindsRaw) {
        kinds.add(e.toString());
      }
    }

    return CustomWorkout(
      exerciseKind: j['exerciseKind']?.toString() ?? '',
      minMidi: ni(j['minMidi'], PracticePrefsDefaults.poolMinMidi),
      maxMidi: ni(j['maxMidi'], PracticePrefsDefaults.poolMaxMidi),
      intervalKinds: kinds,
    );
  }

  static CustomWorkout defaultsForPrefs({
    required int poolMinMidi,
    required int poolMaxMidi,
    String exerciseKind = 'mcq',
  }) {
    return CustomWorkout(
      exerciseKind: exerciseKind,
      minMidi: poolMinMidi,
      maxMidi: poolMaxMidi,
      intervalKinds: MusicInterval.practiceSet.map((e) => e.name).toList(),
    );
  }
}

/// `practice_prefs` varsayılanlarına döngüsel bağımlılık yok.
abstract final class PracticePrefsDefaults {
  static const int poolMinMidi = 40;
  static const int poolMaxMidi = 71;
}

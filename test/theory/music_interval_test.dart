import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/theory/music_interval.dart';

void main() {
  test('semitones tüm practiceSet için tanımlı', () {
    for (final k in MusicInterval.practiceSet) {
      expect(MusicInterval.semitones[k], isNotNull);
      expect(MusicInterval.semitones[k], greaterThan(0));
      expect(MusicInterval.semitones[k], lessThan(12));
    }
  });

  test('yeni aralıklar Türkçe ad', () {
    expect(MusicInterval.turkishName(IntervalKind.tritone), 'tritonus');
    expect(MusicInterval.turkishName(IntervalKind.minorSixth), 'küçük 6lı');
    expect(MusicInterval.turkishName(IntervalKind.majorSeventh), 'büyük 7li');
  });

  test('apply tritonus yukarı', () {
    expect(
      MusicInterval.apply(60, IntervalKind.tritone, up: true),
      66,
    );
  });

  test('between tanır', () {
    expect(MusicInterval.between(60, 66), IntervalKind.tritone);
    expect(MusicInterval.between(60, 68), IntervalKind.minorSixth);
  });

  test('practiceSet oktav içermez', () {
    expect(MusicInterval.practiceSet, isNot(contains(IntervalKind.octave)));
    expect(MusicInterval.practiceSet.length, 11);
  });
}

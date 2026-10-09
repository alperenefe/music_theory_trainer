import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/chord_shape.dart';
import 'package:music_theory_trainer/models/guitar_path.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:music_theory_trainer/models/strum_pattern.dart';

void main() {
  group('akor şekilleri', () {
    test('her şeklin 6 teli, geçerli perde ve parmak sayısı var', () {
      for (final c in ChordLibrary.all) {
        expect(c.frets, hasLength(6), reason: c.symbol);
        expect(c.fingers, hasLength(6), reason: c.symbol);
        expect(c.frets.every((f) => f >= -1 && f <= 5), isTrue, reason: c.symbol);
        expect(c.playedStrings.length, greaterThanOrEqualTo(4), reason: c.symbol);
        for (var s = 0; s < 6; s++) {
          if (c.frets[s] > 0) {
            expect(c.fingers[s], inInclusiveRange(1, 4), reason: '${c.symbol} tel $s parmak');
          }
        }
      }
    });

    test('bilinen akorların notaları doğru (ders kitabı doğrulaması)', () {
      // Notaları pitch class olarak: C=0, D=2, E=4, F=5, G=7, A=9, B=11.
      Set<int> pcs(ChordShape c) => {for (final m in c.midis) m % 12};
      expect(pcs(ChordLibrary.em), {4, 7, 11});
      expect(pcs(ChordLibrary.am), {9, 0, 4});
      expect(pcs(ChordLibrary.e), {4, 8, 11});
      expect(pcs(ChordLibrary.a), {9, 1, 4});
      expect(pcs(ChordLibrary.d), {2, 6, 9});
      expect(pcs(ChordLibrary.dm), {2, 5, 9});
      expect(pcs(ChordLibrary.c), {0, 4, 7});
      expect(pcs(ChordLibrary.g), {7, 11, 2});
      expect(pcs(ChordLibrary.e7), {4, 8, 11, 2});
      expect(pcs(ChordLibrary.a7), {9, 1, 4, 7});
      expect(pcs(ChordLibrary.d7), {2, 6, 9, 0});
      expect(pcs(ChordLibrary.am7), {9, 0, 4, 7});
      expect(pcs(ChordLibrary.em7), {4, 7, 11, 2});
      expect(pcs(ChordLibrary.asus2), {9, 11, 4});
      expect(pcs(ChordLibrary.dsus2), {2, 4, 9});
    });

    test('kök notası akorun adıyla uyuşur (en pes çalınan tel)', () {
      const roots = {
        'D': 2, 'A': 9, 'E': 4, 'Em': 4, 'Am': 9, 'Dm': 2, 'C': 0, 'G': 7,
        'E7': 4, 'A7': 9, 'D7': 2, 'Am7': 9, 'Em7': 4, 'Asus2': 9, 'Dsus2': 2,
      };
      for (final c in ChordLibrary.all) {
        expect(c.midis.first % 12, roots[c.id], reason: c.symbol);
      }
    });
  });

  group('vuruş kalıpları', () {
    test('her kalıp 8 dilim; aşağı vuruşlar en az bir vuruş arayla', () {
      for (final p in StrumPatterns.all) {
        expect(p.slots, hasLength(8));
        final downs = p.downSlots;
        for (var i = 1; i < downs.length; i++) {
          expect(downs[i] - downs[i - 1], greaterThanOrEqualTo(2), reason: p.id);
        }
        expect(p.minBpm, lessThan(p.maxBpm));
      }
    });

    test('klasik kalıp JustinGuitar ile aynı: 1  2+  +  4', () {
      final p = StrumPatterns.classic;
      expect(p.downSlots, [0, 2, 6]);
      expect(p.upSlots, [3, 5]);
    });
  });

  group('gitar yolu', () {
    test('adım kimlikleri benzersiz', () {
      final ids = GuitarPath.allSteps.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('tüm adımların akorları ve kalıpları kütüphanede var', () {
      for (final s in GuitarPath.allSteps) {
        for (final id in s.chordIds) {
          expect(ChordLibrary.all.any((c) => c.id == id), isTrue, reason: '${s.id}: $id');
        }
        if (s.patternId != null) {
          expect(StrumPatterns.all.any((p) => p.id == s.patternId), isTrue, reason: s.id);
        }
      }
    });

    test('her adım türü gereken alanları taşıyor', () {
      for (final s in GuitarPath.allSteps) {
        switch (s.kind) {
          case GuitarStepKind.chordPlay:
            expect(s.chordIds, hasLength(1), reason: s.id);
          case GuitarStepKind.changes:
            expect(s.chordIds, hasLength(2), reason: s.id);
            expect(s.target, greaterThan(0), reason: s.id);
          case GuitarStepKind.strum:
            expect(s.chordIds, hasLength(1), reason: s.id);
            expect(s.patternId, isNotNull, reason: s.id);
            final p = StrumPatterns.byId(s.patternId!);
            expect(s.bpm, inInclusiveRange(p.minBpm, p.maxBpm), reason: '${s.id} tempo');
            expect(s.bars, greaterThan(0), reason: s.id);
          case GuitarStepKind.progression:
            expect(s.chordIds.length, greaterThanOrEqualTo(3), reason: s.id);
            expect(s.bars, s.chordIds.length >= 8 ? s.chordIds.length : isNotNull, reason: s.id);
          case GuitarStepKind.earPlay:
            expect(s.chordIds.length, greaterThanOrEqualTo(3), reason: s.id);
            expect(s.bpm, isNotNull, reason: s.id);
          case GuitarStepKind.info:
            expect(s.blocks, isNotEmpty, reason: s.id);
          case GuitarStepKind.tuner:
          case GuitarStepKind.openStrings:
            break;
        }
      }
    });

    test('bir akor, öğretildiği (chordPlay) yerden ÖNCE bir değişim/ritim adımında geçmez', () {
      final taught = <String>{};
      for (final s in GuitarPath.allSteps) {
        if (s.kind == GuitarStepKind.chordPlay) taught.addAll(s.chordIds);
        if (s.kind == GuitarStepKind.changes ||
            s.kind == GuitarStepKind.strum ||
            s.kind == GuitarStepKind.progression ||
            s.kind == GuitarStepKind.earPlay) {
          for (final id in s.chordIds) {
            expect(taught, contains(id), reason: '${s.id} henüz öğretilmemiş $id kullanıyor');
          }
        }
      }
    });

    test('aynı akor ikilisi ardışık değişimlerde ters sırayla tekrar edilmez', () {
      final pairs = <String>{};
      for (final s in GuitarPath.allSteps.where((s) => s.kind == GuitarStepKind.changes)) {
        final key = (s.chordIds.toList()..sort()).join('-');
        expect(pairs.add(key), isTrue, reason: 'tekrar: $key');
      }
    });

    test('yıldız hesabı: eksik adım varsa 0, tamamsa ortalama', () {
      final lesson = GuitarPath.levels[1].lessons.first; // D akoru: info + chordPlay
      expect(GuitarPath.lessonStars(lesson, {}), 0);
      expect(GuitarPath.lessonStars(lesson, {lesson.steps.first.id: 3}), 0);
      final all = {for (final s in lesson.steps) s.id: 3};
      expect(GuitarPath.lessonStars(lesson, all), 3);
      final mixed = {lesson.steps[0].id: 3, lesson.steps[1].id: 1};
      expect(GuitarPath.lessonStars(lesson, mixed), 1);
    });

    test('nextStep yolun başından başlar ve tamamlananları atlar', () {
      expect(GuitarPath.nextStep({})?.id, GuitarPath.allSteps.first.id);
      final first = GuitarPath.allSteps.first.id;
      expect(GuitarPath.nextStep({first: 1})?.id, GuitarPath.allSteps[1].id);
    });
  });

  group('gitar tercihleri', () {
    test('yıldız yalnızca artar, süre birikir, JSON turu korunur', () {
      var p = const PracticePrefs();
      p = p.withStepStars('x', 2).withStepStars('x', 1);
      expect(p.guitarStepStars['x'], 2);
      p = p.withStepStars('x', 3);
      expect(p.guitarStepStars['x'], 3);
      p = p.withPracticeMs('2026-10-01', 60000).withPracticeMs('2026-10-01', 30000);
      expect(p.practiceMsOn('2026-10-01'), 90000);
      p = p.withGuitarBest('changes:A-D', 22).withGuitarBest('changes:A-D', 18);
      expect(p.guitarBests['changes:A-D'], 22);
      final back = PracticePrefs.fromJson(p.toJson());
      expect(back.guitarStepStars['x'], 3);
      expect(back.practiceMsOn('2026-10-01'), 90000);
      expect(back.guitarBests['changes:A-D'], 22);
      expect(back.dailyGoalMinutes, 15);
    });

    test('bozuk gitar verisi atılır, günlük hedef sınırlanır', () {
      final p = PracticePrefs.fromJson({
        'dailyGoalMinutes': 9999,
        'guitarStepStars': {'a': 9, 'b': 'x', 'c': -3},
        'guitarPracticeMs': 'bozuk',
      });
      expect(p.dailyGoalMinutes, PracticePrefs.maxDailyGoalMinutes);
      expect(p.guitarStepStars['a'], 3);
      expect(p.guitarStepStars.containsKey('b'), isFalse);
      expect(p.guitarStepStars['c'], 0);
      expect(p.guitarPracticeMs, isEmpty);
    });

    test('120 günden eski gitar çalışma kayıtları budanır', () {
      var p = const PracticePrefs();
      for (var i = 0; i < 130; i++) {
        final d = DateTime(2026, 1, 1).add(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        p = p.withPracticeMs(key, 1000);
      }
      expect(p.guitarPracticeMs.length, PracticePrefs.maxPracticeDays);
      expect(p.guitarPracticeMs.containsKey('2026-01-01'), isFalse);
    });
  });
}

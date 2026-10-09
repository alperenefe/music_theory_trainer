import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/audio/ear_sound.dart';
import 'package:music_theory_trainer/dsp/guitar_synth.dart';
import 'package:music_theory_trainer/dsp/strum_session.dart';
import 'package:music_theory_trainer/models/chord_shape.dart';
import 'package:music_theory_trainer/models/guitar_path.dart';
import 'package:music_theory_trainer/models/strum_pattern.dart';
import 'package:music_theory_trainer/screens/guitar/guitar_path_screen.dart';
import 'package:music_theory_trainer/screens/guitar/guitar_step_screen.dart';
import 'package:music_theory_trainer/services/mic_audio_session.dart';
import 'package:music_theory_trainer/services/practice_prefs_repository.dart';
import 'package:music_theory_trainer/widgets/guitar/step_env.dart';
import 'package:music_theory_trainer/widgets/guitar/step_views/changes_view.dart';
import 'package:music_theory_trainer/widgets/guitar/step_views/ear_play_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sr = 44100;

/// Sahte mikrofon: testin verdiği ses parçalarını uygulamaya "mikrofondan" iletir.
final class FakeMic {
  final controller = StreamController<PitchFrame>.broadcast();
  var permission = true;

  MicAudioSession session() => MicAudioSession(
        frames: () => controller.stream,
        requestPermission: () async => permission,
      );

  void emit(Float64List chunk) =>
      controller.add(PitchFrame(hz: 0, rms: 0.1, pcm: chunk, sampleRate: _sr));
}

final class FakePlayer implements StepPlayer {
  final _pos = StreamController<Duration>.broadcast();
  var played = 0;

  @override
  Stream<Duration> get positions => _pos.stream;

  @override
  Future<void> playWav(Uint8List wav) async {
    played++;
    scheduleMicrotask(() => _pos.add(Duration.zero));
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

StepEnv _env(FakeMic mic, FakePlayer player) =>
    StepEnv(micFactory: mic.session, playerFactory: () => player);

/// Sesi 2048'lik parçalar hâlinde, uygulamanın ilerleyebilmesi için ara vererek yollar.
Future<void> _feed(WidgetTester tester, FakeMic mic, Float64List audio) async {
  await tester.runAsync(() async {
    for (var i = 0; i + 2048 <= audio.length; i += 2048) {
      mic.emit(Float64List.sublistView(audio, i, i + 2048));
      if ((i ~/ 2048) % 8 == 0) await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  await tester.pump();
}

/// Sahte-zamanlı bölgede başlayan SharedPreferences yazımlarının bitmesini bekler.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

Future<Map<String, int>> _stars() async =>
    (await PracticePrefsRepository().load()).guitarStepStars;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Gitar yolu açılır, sıradaki adım önerilir, bilgi adımı yıldız kaydeder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GuitarPathScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Gitar Yolu'), findsOneWidget);
    expect(find.text('Önerilen sıradaki adım'), findsOneWidget);

    await tester.tap(find.text('Önerilen sıradaki adım'));
    await tester.pumpAndSettle();
    expect(find.text('Okudum, devam'), findsOneWidget);

    await tester.tap(find.text('Okudum, devam'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    final stars = await tester.runAsync(_stars);
    expect(stars, {'l0a.hold': 1}, reason: 'yıldız okunan adıma yazılmalı, sıradakine değil');
  });

  testWidgets('akor adımı: doğru akor çalınınca yıldız verir ve kaydeder', (tester) async {
    final mic = FakeMic();
    await tester.pumpWidget(MaterialApp(
      home: GuitarStepScreen(stepId: 'l5b.play', env: _env(mic, FakePlayer())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinlemeyi başlat'));
    await tester.pumpAndSettle();

    final g = GuitarSynth.addNoise(
      GuitarSynth.chord(midis: ChordLibrary.g.midis, sampleRate: _sr, seconds: 1.6, strumMs: 18),
      30,
      seed: 4,
    );
    await _feed(tester, mic, g);
    expect(find.text('Devam'), findsOneWidget, reason: 'sonuç kartı gelmedi');
    final stars = await tester.runAsync(_stars);
    expect(stars!['l5b.play'], greaterThanOrEqualTo(1));
  });

  testWidgets('akor adımı: yanlış akor çalınırsa sonuç kartı gelmez, yıldız yazılmaz', (tester) async {
    final mic = FakeMic();
    await tester.pumpWidget(MaterialApp(
      home: GuitarStepScreen(stepId: 'l5b.play', env: _env(mic, FakePlayer())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinlemeyi başlat'));
    await tester.pumpAndSettle();
    final c = GuitarSynth.chord(
        midis: ChordLibrary.c.midis, sampleRate: _sr, seconds: 1.6, strumMs: 18);
    await _feed(tester, mic, c);
    expect(find.text('Devam'), findsNothing);
    final stars = await tester.runAsync(_stars);
    expect(stars!['l5b.play'], isNull);
  });

  testWidgets('mikrofon izni yoksa elle onay yalnızca 1 yıldız verir', (tester) async {
    final mic = FakeMic()..permission = false;
    await tester.pumpWidget(MaterialApp(
      home: GuitarStepScreen(stepId: 'l5b.play', env: _env(mic, FakePlayer())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinlemeyi başlat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mikrofon izni verilmedi'), findsOneWidget);
    final manual = find.widgetWithText(TextButton, 'Elle onayla (en fazla 1 yıldız)');
    await tester.scrollUntilVisible(manual, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(manual);
    await tester.pumpAndSettle();
    await _settleIo(tester);
    final stars = await tester.runAsync(_stars);
    expect(stars!['l5b.play'], 1);
  });

  testWidgets('vuruş adımı: metronomla çalınan kalıp puanlanır ve kaydedilir', (tester) async {
    final mic = FakeMic();
    final player = FakePlayer();
    await tester.pumpWidget(MaterialApp(
      home: GuitarStepScreen(stepId: 'l1d.strum', env: _env(mic, player)),
    ));
    await tester.pumpAndSettle();
    final step = GuitarPath.stepById('l1d.strum')!;
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(player.played, 1);

    final s = StrumSession(
      pattern: StrumPatterns.byId(step.patternId!),
      bpm: step.bpm!,
      bars: step.bars!,
    );
    final out = Float64List((_sr * (s.totalMs / 1000 + 1.5)).round());
    var k = 0;
    for (final t in s.expectedDownMs) {
      GuitarSynth.mixInto(
        out,
        GuitarSynth.chord(
            midis: ChordLibrary.d.midis, sampleRate: _sr, seconds: 0.9, strumMs: 14, seed: ++k),
        ((t + 90) * _sr / 1000).round(),
      );
    }
    await _feed(tester, mic, GuitarSynth.addNoise(out, 30, seed: 6));
    expect(find.text('Devam'), findsOneWidget, reason: 'sonuç kartı gelmedi');
    final stars = await tester.runAsync(_stars);
    expect(stars!['l1d.strum'], greaterThanOrEqualTo(2));
  });

  testWidgets('vuruş adımı: hiç çalmazsan 0 yıldız, kayıt 0', (tester) async {
    final mic = FakeMic();
    await tester.pumpWidget(MaterialApp(
      home: GuitarStepScreen(stepId: 'l1d.strum', env: _env(mic, FakePlayer())),
    ));
    await tester.pumpAndSettle();
    final step = GuitarPath.stepById('l1d.strum')!;
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    final s = StrumSession(
        pattern: StrumPatterns.byId(step.patternId!), bpm: step.bpm!, bars: step.bars!);
    final quiet = GuitarSynth.addNoise(
        Float64List((_sr * (s.totalMs / 1000 + 1.5)).round()), 30, seed: 3);
    await _feed(tester, mic, quiet);
    expect(find.text('Devam'), findsOneWidget);
    final stars = await tester.runAsync(_stars);
    expect(stars!['l1d.strum'], 0);
  });

  testWidgets('akor değişimi: mikrofon yoksa elle sayım en fazla 1 yıldız', (tester) async {
    final mic = FakeMic()..permission = false;
    final step = GuitarPath.stepById('l1c.changes')!;
    int? stars;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangesView(
          step: step,
          env: _env(mic, FakePlayer()),
          onFinished: (s) => stars = s,
          onNext: () {},
          onBest: (_, __) {},
          duration: const Duration(seconds: 3),
        ),
      ),
    ));
    await tester.tap(find.textContaining('Başla'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 4)); // geri sayım
    for (var i = 0; i < 20; i++) {
      await tester.tap(find.textContaining('+1 değişim'));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 4));
    expect(stars, 1);
    expect(find.textContaining('Elle sayıldığı'), findsOneWidget);
  });

  testWidgets('kulaktan bul: döngü dinlenir, akorlar çalınınca tamamlanır; ipucu yıldız düşürür', (tester) async {
    final mic = FakeMic();
    final step = GuitarPath.stepById('l8a.major')!;
    int? stars;
    var loops = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EarPlayView(
          step: step,
          env: _env(mic, FakePlayer()),
          onFinished: (s) => stars = s,
          onNext: () {},
          playLoop: (HarmonicRhythmSound _) async => loops++,
        ),
      ),
    ));
    await tester.tap(find.text('Döngüyü dinle'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(loops, 1);
    await tester.tap(find.textContaining('Çalmaya başla'));
    await tester.pumpAndSettle();

    for (final c in step.chords) {
      await _feed(
        tester,
        mic,
        GuitarSynth.addNoise(
          GuitarSynth.chord(midis: c.midis, sampleRate: _sr, seconds: 1.8, strumMs: 18),
          30,
          seed: 2,
        ),
      );
    }
    expect(stars, 3, reason: 'ipucusuz bulununca 3 yıldız');
  });
}

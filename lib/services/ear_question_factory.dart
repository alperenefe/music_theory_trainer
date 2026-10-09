import 'dart:math' as math;

import '../audio/ear_audio_types.dart';
import '../audio/ear_sound.dart';
import '../l10n/ear_strings.dart';
import '../models/ear_curriculum.dart';
import '../models/ear_exercise_kind.dart';
import '../models/ear_question.dart';

/// Bas avcısı hedefi: akor + gitardaki kök bas notası.
final class BassTarget {
  const BassTarget(this.chordName, this.quality, this.rootMidi, this.noteName);

  final String chordName;
  final EarChordQuality quality;
  final int rootMidi;
  final String noteName;
}

/// Tüm kulak eğitimi sorularını üretir (saf Dart, test edilebilir).
///
/// Aynı türde üst üste aynı hedefi sormaz; karışık seanslarda türleri
/// dengeli dağıtır (interleaving).
final class EarQuestionFactory {
  EarQuestionFactory({math.Random? random}) : _rng = random ?? math.Random();

  final math.Random _rng;
  final Map<EarExerciseKind, String> _lastSubtype = {};

  static const bassSubtypeKey = 'downbeat_bass';

  /// Bas avcısında gösterilen perdeler (inlay'li perdeler dahil).
  static const bassFrets = [0, 1, 2, 3, 5, 7, 8, 10, 12];

  /// Açık tel MIDI değerleri: 6. tel E2, 5. tel A2.
  static const openStringMidi = {6: 40, 5: 45};

  static const bassTargets = [
    BassTarget('Sol Majör (G)', EarChordQuality.major, 43, 'Sol (G)'),
    BassTarget('La Minör (Am)', EarChordQuality.minor, 45, 'La (A)'),
    BassTarget('Fa Majör (F)', EarChordQuality.major, 41, 'Fa (F)'),
    BassTarget('Mi Minör (Em)', EarChordQuality.minor, 40, 'Mi (E)'),
    BassTarget('Si Minör (Bm)', EarChordQuality.minor, 47, 'Si (B)'),
    BassTarget('Do Majör (C)', EarChordQuality.major, 48, 'Do (C)'),
    BassTarget('Re Minör (Dm)', EarChordQuality.minor, 50, 'Re (D)'),
    BassTarget('Mi Majör (E)', EarChordQuality.major, 52, 'Mi (E)'),
  ];

  /// 1. hafta: akorların temeli (3'lüler, 5'li, oktav). 3. hafta: + tam 4'lü.
  /// 4. hafta: + 2'liler (melodilerin adımları; sus2 ile birlikte gelir).
  static List<EarIntervalType> intervalPool(int weekNumber) => weekNumber >= 4
      ? const [
          EarIntervalType.minor2,
          EarIntervalType.major2,
          EarIntervalType.minor3,
          EarIntervalType.major3,
          EarIntervalType.perfect4,
          EarIntervalType.perfect5,
          EarIntervalType.octave,
        ]
      : weekNumber >= 3
      ? const [
          EarIntervalType.minor3,
          EarIntervalType.major3,
          EarIntervalType.perfect4,
          EarIntervalType.perfect5,
          EarIntervalType.octave,
        ]
      : const [
          EarIntervalType.minor3,
          EarIntervalType.major3,
          EarIntervalType.perfect5,
          EarIntervalType.octave,
        ];

  static List<EarChordQuality> chordPool(int weekNumber) => weekNumber >= 11
      ? const [
          EarChordQuality.major,
          EarChordQuality.minor,
          EarChordQuality.sus2,
          EarChordQuality.dominant7,
          EarChordQuality.minor7,
        ]
      : const [
          EarChordQuality.major,
          EarChordQuality.minor,
          EarChordQuality.sus2,
          EarChordQuality.power,
        ];

  // --- Seans ---------------------------------------------------------------

  /// [kinds] birden fazlaysa sorular türler arasında dengeli ve karışık dağılır.
  /// [subtypes] verilirse (aralıklı tekrar) sorular bu hedeflere odaklanır.
  List<EarQuestion> session({
    required List<EarExerciseKind> kinds,
    required int count,
    required int weekNumber,
    List<String> subtypes = const [],
  }) {
    final n = math.max(1, count);
    final known = [
      for (final s in subtypes)
        if (isKnownSubtype(s)) s,
    ];
    if (known.isNotEmpty) {
      final order = [for (var i = 0; i < n; i++) known[i % known.length]]..shuffle(_rng);
      return [for (final key in order) forSubtype(key, weekNumber: weekNumber)!];
    }

    final concrete = [
      for (final k in kinds)
        if (k != EarExerciseKind.interleaved) k,
    ];
    final pool = concrete.isEmpty ? earKindsIntroducedBy(weekNumber) : concrete;
    final order = [for (var i = 0; i < n; i++) pool[i % pool.length]]..shuffle(_rng);
    return [for (final k in order) build(k, weekNumber: weekNumber)];
  }

  EarQuestion build(EarExerciseKind kind, {required int weekNumber}) {
    return switch (kind) {
      EarExerciseKind.intervalBlind => interval(weekNumber: weekNumber),
      EarExerciseKind.harmonicRhythm => harmonicRhythm(),
      EarExerciseKind.chordQuality => chordQuality(weekNumber: weekNumber),
      EarExerciseKind.bassHunter => bassHunter(),
      EarExerciseKind.inversionDetect => inversionDetect(),
      EarExerciseKind.cadenceRecognition => cadence(),
      EarExerciseKind.scaleDegree => scaleDegree(weekNumber: weekNumber),
      EarExerciseKind.interleaved => build(
          _pickFrom(earKindsIntroducedBy(weekNumber)),
          weekNumber: weekNumber,
        ),
    };
  }

  static bool isKnownSubtype(String key) =>
      key == bassSubtypeKey ||
      _rhythmBeatsFromKey(key) != null ||
      inversionKeys.contains(key) ||
      degreeFromKey(key) != null ||
      EarIntervalType.fromSrsKey(key) != null ||
      EarChordQuality.fromSrsKey(key) != null ||
      EarCadenceType.fromSrsKey(key) != null;

  /// Belirli bir zayıf noktayı hedefleyen soru (aralıklı tekrar için).
  EarQuestion? forSubtype(String key, {required int weekNumber}) {
    final interval = EarIntervalType.fromSrsKey(key);
    if (interval != null) return this.interval(weekNumber: weekNumber, target: interval);
    final chord = EarChordQuality.fromSrsKey(key);
    if (chord != null) return chordQuality(weekNumber: weekNumber, target: chord);
    final cad = EarCadenceType.fromSrsKey(key);
    if (cad != null) return cadence(target: cad);
    if (key == bassSubtypeKey) return bassHunter();
    final beats = _rhythmBeatsFromKey(key);
    if (beats != null) return harmonicRhythm(targetBeats: beats);
    final inv = inversionKeys.indexOf(key);
    if (inv >= 0) return inversionDetect(targetInversion: inv);
    final degree = degreeFromKey(key);
    if (degree != null) return scaleDegree(weekNumber: weekNumber, target: degree);
    return null;
  }

  static int? _rhythmBeatsFromKey(String key) {
    for (final b in rhythmBeatsPool) {
      if (key == 'rhythm_${b}_beats') return b;
    }
    return null;
  }

  // --- Soru türleri ----------------------------------------------------------

  /// 1. hafta yalnızca yükselen aralıklarla başlar; yükselen hâl oturunca
  /// alçalan hâl de sorulur (alçalan aralıklar ayrı bir beceridir).
  static const descendingFromWeek = 2;
  static const descendingRatio = 0.35;

  EarQuestion interval({
    required int weekNumber,
    EarIntervalType? target,
    bool? descending,
  }) {
    final pool = [...intervalPool(weekNumber)];
    if (target != null && !pool.contains(target)) pool.add(target);
    pool.sort((a, b) => a.semitones.compareTo(b.semitones));
    final t = target ?? _pick<EarIntervalType>(pool, (e) => e.srsKey, EarExerciseKind.intervalBlind);
    final root = 40 + _rng.nextInt(12); // E2 – D#3: gitarın bas bölgesi
    final down = descending ??
        (weekNumber >= descendingFromWeek && _rng.nextDouble() < descendingRatio);
    final sound = IntervalSound(rootMidi: root, interval: t, descending: down);

    return EarQuestion(
      kind: EarExerciseKind.intervalBlind,
      subtypeKey: t.srsKey,
      prompt: down ? EarStrings.intervalPromptDescending : EarStrings.intervalPrompt,
      hint: down ? EarStrings.intervalHintDescending : EarStrings.intervalHint,
      sound: sound,
      altSound: sound.withHarmonic(true),
      altSoundLabel: EarStrings.playTogether,
      options: [
        for (final i in pool)
          EarAnswerOption(
            id: i.srsKey,
            title: i.label,
            subtitle: i.subtitle,
            sound: IntervalSound(rootMidi: root, interval: i, descending: down),
          ),
      ],
      correctIds: {t.srsKey},
      correctLabel: t.label,
      explanation: EarStrings.intervalReference(t, descending: down),
    );
  }

  EarQuestion chordQuality({required int weekNumber, EarChordQuality? target}) {
    final pool = [...chordPool(weekNumber)];
    if (target != null && !pool.contains(target)) pool.add(target);
    final t = target ?? _pick<EarChordQuality>(pool, (e) => e.srsKey, EarExerciseKind.chordQuality);
    final root = 40 + _rng.nextInt(12);
    final sound = ChordSound(rootMidi: root, quality: t);

    return EarQuestion(
      kind: EarExerciseKind.chordQuality,
      subtypeKey: t.srsKey,
      prompt: EarStrings.chordPrompt,
      hint: EarStrings.chordHint,
      sound: sound,
      altSound: sound.withArpeggio(true),
      altSoundLabel: EarStrings.playArpeggio,
      options: [
        for (final q in pool)
          EarAnswerOption(
            id: q.srsKey,
            title: q.label,
            subtitle: q.subtitle,
            sound: ChordSound(rootMidi: root, quality: q),
          ),
      ],
      correctIds: {t.srsKey},
      correctLabel: t.label,
      explanation: EarStrings.chordExplanation(t),
    );
  }

  EarQuestion cadence({EarCadenceType? target}) {
    const pool = EarCadenceType.values;
    final t = target ?? _pick<EarCadenceType>(pool, (e) => e.srsKey, EarExerciseKind.cadenceRecognition);
    final root = 40 + _rng.nextInt(8);

    return EarQuestion(
      kind: EarExerciseKind.cadenceRecognition,
      subtypeKey: t.srsKey,
      prompt: EarStrings.cadencePrompt,
      hint: EarStrings.cadenceHint,
      sound: CadenceSound(rootMidi: root, cadence: t),
      options: [
        for (final c in pool)
          EarAnswerOption(
            id: c.srsKey,
            title: c.label,
            subtitle: c.subtitle,
            sound: CadenceSound(rootMidi: root, cadence: c),
          ),
      ],
      correctIds: {t.srsKey},
      correctLabel: t.label,
      explanation: EarStrings.cadenceExplanation(t),
    );
  }

  EarQuestion bassHunter({BassTarget? target}) {
    final t = target ?? _pick<BassTarget>(bassTargets, (e) => e.noteName + e.chordName, EarExerciseKind.bassHunter);
    final options = <EarAnswerOption>[
      for (final string in const [6, 5])
        for (final fret in bassFrets)
          EarAnswerOption(
            id: 's${string}f$fret',
            title: fret == 0 ? EarStrings.openString : '$fret',
            sound: NoteSound(openStringMidi[string]! + fret),
            stringNumber: string,
            fret: fret,
          ),
    ];
    final correct = {
      for (final o in options)
        if (openStringMidi[o.stringNumber]! + o.fret! == t.rootMidi) o.id,
    };
    final positions = [
      for (final o in options)
        if (correct.contains(o.id)) EarStrings.fretPosition(o.stringNumber!, o.fret!),
    ];

    return EarQuestion(
      kind: EarExerciseKind.bassHunter,
      subtypeKey: bassSubtypeKey,
      prompt: EarStrings.bassPrompt,
      hint: EarStrings.bassHint,
      sound: ChordSound(rootMidi: t.rootMidi, quality: t.quality),
      altSound: NoteSound(t.rootMidi),
      altSoundLabel: EarStrings.playBassOnly,
      layout: EarAnswerLayout.fretboard,
      options: options,
      correctIds: correct,
      correctLabel: '${t.noteName} · ${t.chordName}',
      explanation: EarStrings.bassExplanation(positions),
    );
  }

  static const rhythmBeatsPool = [2, 4, 8];

  /// Aynı akor ailesinden farklı döngüler (kökten yarım ses, kök pozisyon).
  static const _rhythmProgressions = [
    [
      [0, 4, 7, 12], // I
      [7, 11, 14, 19], // V
      [9, 12, 16, 21], // vi
      [5, 9, 12, 17], // IV
    ],
    [
      [9, 12, 16, 21], // vi
      [5, 9, 12, 17], // IV
      [0, 4, 7, 12], // I
      [7, 11, 14, 19], // V
    ],
    [
      [0, 4, 7, 12], // I
      [9, 12, 16, 21], // vi
      [5, 9, 12, 17], // IV
      [7, 11, 14, 19], // V
    ],
    [
      [0, 4, 7, 12], // I
      [5, 9, 12, 17], // IV
      [7, 11, 14, 19], // V
      [5, 9, 12, 17], // IV
    ],
  ];

  /// Her seçenekte toplam süre 16 vuruştur; böylece cevap sesin uzunluğundan
  /// değil, akorların ne sıklıkla değiştiğinden bulunur. Ton, tempo ve dizi
  /// her soruda değişir.
  EarQuestion harmonicRhythm({int? targetBeats}) {
    final t = targetBeats ??
        _pick<int>(rhythmBeatsPool, (e) => 'rhythm_${e}_beats', EarExerciseKind.harmonicRhythm);
    final subtypeKey = 'rhythm_${t}_beats';
    final root = 43 + _rng.nextInt(7); // G2 – C#3
    final bpm = 84 + _rng.nextInt(25); // 84 – 108
    final base = _pickFrom(_rhythmProgressions);

    List<List<int>> chordsFor(int beats) {
      final cycle = [
        for (final c in base) [for (final s in c) root + s],
      ];
      return switch (beats) {
        2 => [...cycle, ...cycle],
        8 => cycle.take(2).toList(),
        _ => cycle,
      };
    }

    final options = [
      for (final b in rhythmBeatsPool)
        EarAnswerOption(
          id: 'rhythm_${b}_beats',
          title: EarStrings.rhythmOptionTitle(b),
          subtitle: EarStrings.rhythmOptionSubtitle(b),
          sound: HarmonicRhythmSound(chords: chordsFor(b), beatsPerChord: b, bpm: bpm),
        ),
    ];

    return EarQuestion(
      kind: EarExerciseKind.harmonicRhythm,
      subtypeKey: subtypeKey,
      prompt: EarStrings.rhythmPrompt,
      hint: EarStrings.rhythmHint,
      sound: HarmonicRhythmSound(chords: chordsFor(t), beatsPerChord: t, bpm: bpm),
      options: options,
      correctIds: {subtypeKey},
      correctLabel: EarStrings.rhythmOptionTitle(t),
      explanation: EarStrings.rhythmExplanation(t),
    );
  }

  /// 0 = kök pozisyon, 1 = 1. inversiyon (bas 3'lü), 2 = 2. inversiyon (bas 5'li).
  static const inversionKeys = ['inversion_root', 'inversion_slash', 'inversion_second'];

  static const _inversionChords = [
    (name: 'Do Majör (C)', root: 36, minor: false, notes: ['Do', 'Mi', 'Sol']),
    (name: 'Re Majör (D)', root: 38, minor: false, notes: ['Re', 'Fa♯', 'La']),
    (name: 'Mi Minör (Em)', root: 40, minor: true, notes: ['Mi', 'Sol', 'Si']),
    (name: 'Fa Majör (F)', root: 41, minor: false, notes: ['Fa', 'La', 'Do']),
    (name: 'Sol Majör (G)', root: 43, minor: false, notes: ['Sol', 'Si', 'Re']),
    (name: 'La Minör (Am)', root: 45, minor: true, notes: ['La', 'Do', 'Mi']),
  ];

  /// Üç seçenekte de üstteki akor birebir aynıdır; yalnızca bas değişir.
  /// Böylece cevap tınıdan değil, gerçekten en pes notadan bulunur.
  EarQuestion inversionDetect({int? targetInversion}) {
    final inv = targetInversion ??
        _pick<int>(const [0, 1, 2], (e) => inversionKeys[e], EarExerciseKind.inversionDetect);
    final ch = _pickFrom(_inversionChords);
    final third = ch.minor ? 3 : 4;
    final upper = [ch.root + 12, ch.root + 12 + third, ch.root + 19];
    final bassOf = [ch.root, ch.root + third, ch.root + 7];

    SlashChordSound soundFor(int i) => SlashChordSound(bassMidi: bassOf[i], upperMidis: upper);

    return EarQuestion(
      kind: EarExerciseKind.inversionDetect,
      subtypeKey: inversionKeys[inv],
      prompt: EarStrings.inversionPrompt,
      hint: EarStrings.inversionHint,
      sound: soundFor(inv),
      altSound: NoteSound(bassOf[inv]),
      altSoundLabel: EarStrings.playBassOnly,
      options: [
        for (var i = 0; i < 3; i++)
          EarAnswerOption(
            id: inversionKeys[i],
            title: EarStrings.inversionOptionTitle(i),
            subtitle: EarStrings.inversionOptionSubtitle(i, ch.name, ch.notes[i]),
            sound: soundFor(i),
          ),
      ],
      correctIds: {inversionKeys[inv]},
      correctLabel: EarStrings.inversionOptionTitle(inv),
      explanation: EarStrings.inversionExplanation(
        inversion: inv,
        chordName: ch.name,
        bassName: ch.notes[inv],
      ),
    );
  }

  // --- Derece tanıma (fonksiyonel dinleme) -----------------------------------

  static const _majorOffsets = [0, 2, 4, 5, 7, 9, 11];
  static const degreeNames = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'];

  /// 3. hafta derste anlatılan dereceler (ev, 3, 4, 5, 7); 6. haftadan itibaren hepsi.
  static List<int> degreePool(int weekNumber) =>
      weekNumber >= 6 ? const [1, 2, 3, 4, 5, 6, 7] : const [1, 3, 4, 5, 7];

  static String degreeKey(int degree) => 'degree_$degree';

  static int? degreeFromKey(String key) {
    if (!key.startsWith('degree_')) return null;
    final d = int.tryParse(key.substring(7));
    return d != null && d >= 1 && d <= 7 ? d : null;
  }

  /// Notadan en yakın eve adım adım çözülüş (Benbassat yöntemi).
  static List<int> resolutionOffsets(int degree) => switch (degree) {
        2 => const [2, 0],
        3 => const [4, 2, 0],
        4 => const [5, 4, 2, 0],
        5 => const [7, 9, 11, 12],
        6 => const [9, 11, 12],
        7 => const [11, 12],
        _ => const [0],
      };

  /// Önce tonik akorunun notalarıyla ev kurulur, ardından hedef nota çalar.
  EarQuestion scaleDegree({required int weekNumber, int? target}) {
    final pool = [...degreePool(weekNumber)];
    if (target != null && !pool.contains(target)) {
      pool
        ..add(target)
        ..sort();
    }
    final d = target ?? _pick<int>(pool, degreeKey, EarExerciseKind.scaleDegree);
    final tonic = 48 + _rng.nextInt(8); // C3 – G3
    final context = [tonic, tonic + 4, tonic + 7, tonic + 12, tonic + 7, tonic + 4, tonic];

    ScaleSound noteSound(int degree) =>
        ScaleSound(notes: [...context, tonic + _majorOffsets[degree - 1]], stepDurationMs: 330);

    return EarQuestion(
      kind: EarExerciseKind.scaleDegree,
      subtypeKey: degreeKey(d),
      prompt: EarStrings.degreePrompt,
      hint: EarStrings.degreeHint,
      sound: noteSound(d),
      altSound: ScaleSound(
        notes: [
          ...context,
          for (final o in resolutionOffsets(d)) tonic + o,
        ],
        stepDurationMs: 330,
      ),
      altSoundLabel: EarStrings.degreeResolve,
      altSoundAfterAnswer: true,
      options: [
        for (final i in pool)
          EarAnswerOption(
            id: degreeKey(i),
            title: EarStrings.degreeTitle(i),
            subtitle: EarStrings.degreeSubtitle(i),
            sound: noteSound(i),
          ),
      ],
      correctIds: {degreeKey(d)},
      correctLabel: EarStrings.degreeTitle(d),
      explanation: EarStrings.degreeExplanation(d),
    );
  }

  // --- Yardımcılar ---------------------------------------------------------

  T _pickFrom<T>(List<T> pool) => pool[_rng.nextInt(pool.length)];

  /// Aynı türde bir önceki hedefi (havuzda başka seçenek varsa) tekrar seçmez.
  T _pick<T>(List<T> pool, String Function(T) keyOf, EarExerciseKind kind) {
    final last = _lastSubtype[kind];
    final candidates = last == null
        ? pool
        : [
            for (final e in pool)
              if (keyOf(e) != last) e,
          ];
    final choice = _pickFrom(candidates.isEmpty ? pool : candidates);
    _lastSubtype[kind] = keyOf(choice);
    return choice;
  }
}

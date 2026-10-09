enum EarExerciseKind {
  intervalBlind, // Küçük 3'lü vs Büyük 3'lü vs Tam 5'li vs Oktav kör test
  harmonicRhythm, // Akorlar ne zaman el değiştiriyor? 2, 4 ya da 8 vuruş?
  chordQuality, // Majör / Minör / Sus2 / Power Chord ayırımı
  bassHunter, // Gitarda Downbeat bası yakalama
  inversionDetect, // Kök pozisyon mu, 1. inversiyon mu (C/E), 2. inversiyon mu (C/G)?
  cadenceRecognition, // i-iv-V7, I-V-vi-IV döngü tanıma
  scaleDegree, // Ton kurulduktan sonra çalan notanın derecesi (fonksiyonel dinleme)
  interleaved, // Tüm önceki türler karışık (konsolidasyon haftaları)
}

extension EarExerciseKindLabel on EarExerciseKind {
  String get label => switch (this) {
        EarExerciseKind.intervalBlind => 'Aralık Testi',
        EarExerciseKind.harmonicRhythm => 'Harmonik Ritim',
        EarExerciseKind.chordQuality => 'Akor Kalitesi',
        EarExerciseKind.bassHunter => 'Bas Avcısı',
        EarExerciseKind.inversionDetect => 'İnversiyon Dedektörü',
        EarExerciseKind.cadenceRecognition => 'Kadans Tanıma',
        EarExerciseKind.scaleDegree => 'Derece Tanıma',
        EarExerciseKind.interleaved => 'Karışık Pratik',
      };

  String get emoji => switch (this) {
        EarExerciseKind.intervalBlind => '🎯',
        EarExerciseKind.harmonicRhythm => '⏱️',
        EarExerciseKind.chordQuality => '🎸',
        EarExerciseKind.bassHunter => '🐟',
        EarExerciseKind.inversionDetect => '🔀',
        EarExerciseKind.cadenceRecognition => '🔄',
        EarExerciseKind.scaleDegree => '🏠',
        EarExerciseKind.interleaved => '🎲',
      };

  /// Egzersiz kartındaki kısa açıklama.
  String get description => switch (this) {
        EarExerciseKind.intervalBlind => 'İki notanın arasındaki mesafeyi duy',
        EarExerciseKind.harmonicRhythm => 'Akorun kaç vuruşta bir değiştiğini say',
        EarExerciseKind.chordQuality => 'Akorun rengini ayırt et',
        EarExerciseKind.bassHunter => 'Bas notayı gitar klavyesinde bul',
        EarExerciseKind.inversionDetect => 'Basta kök mü, 3\'lü mü, 5\'li mi?',
        EarExerciseKind.cadenceRecognition => 'Akor döngüsünü tanı',
        EarExerciseKind.scaleDegree => 'Ev kurulduktan sonra çalan notanın derecesini bul',
        EarExerciseKind.interleaved => 'Önceki konular karışık sırayla',
      };
}

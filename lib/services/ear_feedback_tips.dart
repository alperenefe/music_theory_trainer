import '../audio/ear_audio_types.dart';
import '../models/ear_exercise_kind.dart';
import '../models/ear_question.dart';
import 'ear_question_factory.dart';

/// Yanlış cevaptan sonra "seçtiğin ile doğrusu arasındaki fark nasıl duyulur"
/// açıklaması. Genel teori notunun ([EarQuestion.explanation]) aksine bu metin
/// kullanıcının yaptığı belirli karışıklığa özeldir.
abstract final class EarFeedbackTips {
  static String? contrast(EarQuestion q, String pickedId) {
    if (q.isCorrect(pickedId)) return null;
    return switch (q.kind) {
      EarExerciseKind.intervalBlind => _interval(q.subtypeKey, pickedId),
      EarExerciseKind.chordQuality => _chord(q.subtypeKey, pickedId),
      EarExerciseKind.cadenceRecognition => _cadence(q.subtypeKey, pickedId),
      EarExerciseKind.harmonicRhythm => _rhythm(q.subtypeKey),
      EarExerciseKind.inversionDetect => _inversion(q.subtypeKey, pickedId),
      EarExerciseKind.bassHunter => _bass(q, pickedId),
      EarExerciseKind.scaleDegree => _degree(q.subtypeKey, pickedId),
      EarExerciseKind.interleaved => null,
    };
  }

  // --- Aralıklar -----------------------------------------------------------

  static String? _interval(String correctKey, String pickedKey) {
    final c = EarIntervalType.fromSrsKey(correctKey);
    final p = EarIntervalType.fromSrsKey(pickedKey);
    if (c == null || p == null) return null;
    final diff = (c.semitones - p.semitones).abs();
    final wider = c.semitones > p.semitones;
    final base = 'Seçtiğin ${p.label} ${p.semitones} yarım ses (aynı telde ${p.semitones} '
        'perde), doğrusu ${c.label} ${c.semitones} yarım ses. Doğru cevap $diff yarım ses '
        '${wider ? 'daha geniş' : 'daha dar'}.';
    final tip = _intervalPairTip(c, p);
    return tip == null ? base : '$base\n$tip';
  }

  static String? _intervalPairTip(EarIntervalType a, EarIntervalType b) {
    bool pair(EarIntervalType x, EarIntervalType y) =>
        (a == x && b == y) || (a == y && b == x);

    if (pair(EarIntervalType.minor2, EarIntervalType.major2)) {
      return 'Nasıl ayırırsın: Küçük 2\'li çok dar ve gergindir, iki nota birbirine sürtünür '
          '("Jaws" teması, "Für Elise" açılışı). Büyük 2\'li gamda sıradan, rahat bir adımdır '
          '("İyi ki Doğdun": "İ-yi – ki"). "Birlikte çal"a bas: küçük 2\'li belirgin bir '
          'cızırtı yapar, büyük 2\'li daha yumuşaktır.';
    }
    if (pair(EarIntervalType.major2, EarIntervalType.minor3)) {
      return 'Nasıl ayırırsın: Büyük 2\'li bir adımdır (Do → Re, gamda yan yana iki nota). '
          'Küçük 3\'lü ise bir notayı atlayan küçük bir sıçramadır (Do → Mi♭) ve hüzünlü bir '
          'renk taşır. Notalar yan yana mı, arada boşluk var mı?';
    }
    if (a == EarIntervalType.minor2 ||
        a == EarIntervalType.major2 ||
        b == EarIntervalType.minor2 ||
        b == EarIntervalType.major2) {
      return 'İpucu: 2\'liler adımdır, yani gamda yan yana iki nota; 3\'lü ve daha geniş '
          'aralıklar ise sıçramadır. Duyduğun hareket bir "adım" mı, bir "atlama" mı?';
    }
    if (pair(EarIntervalType.minor3, EarIntervalType.major3)) {
      return 'Nasıl ayırırsın: Büyük 3\'lü gülümser ("Arı Vız Vız" açılışı: "A – rı"), '
          'küçük 3\'lü kaşlarını çatar ("Hatırla Sevgili": "Ha – tır"; aşağı inerken "Küçük '
          'Kurbağa": "Kü – çük"). Kendine tek soru sor: aydınlık mı, gölgeli mi?';
    }
    if (pair(EarIntervalType.perfect4, EarIntervalType.perfect5)) {
      return 'Nasıl ayırırsın: Kafanda İstiklal Marşı\'nın açılışını ("Kork – ma", 4\'lü) ve '
          '"Yaşasın Okulumuz"un açılışını ("Ya-şa – sın", 5\'li) söyle. 4\'lü dar ve soru gibi, '
          '5\'li geniş ve oturmuş durur.';
    }
    if (pair(EarIntervalType.perfect5, EarIntervalType.octave)) {
      return 'Nasıl ayırırsın: Oktavda ikinci nota aynı notanın tizidir, "aynı isim" gibi '
          'gelir ("İyi ki Doğdun"daki büyük sıçrama: "İ-yi ki – DOĞ-dun"). 5\'li ise başka bir '
          'nota ("Yaşasın Okulumuz"). "Birlikte çal"a bas: oktav tek kalın ses gibi kaynaşır, '
          '5\'li iki ayrı ses kalır.';
    }
    if (pair(EarIntervalType.major3, EarIntervalType.perfect4)) {
      return 'Nasıl ayırırsın: Büyük 3\'lü net bir mutlu renk taşır ("Arı Vız Vız"); 4\'lü '
          'renksiz ve törensi durur, bir marşın başlangıcı gibi (İstiklal Marşı: "Kork – ma").';
    }
    if (pair(EarIntervalType.minor3, EarIntervalType.perfect4)) {
      return 'Nasıl ayırırsın: Küçük 3\'lü hüzünlü bir renk taşır; 4\'lü ne hüzünlü ne '
          'mutlu, açık ve asılıdır.';
    }
    if (pair(EarIntervalType.major3, EarIntervalType.perfect5) ||
        pair(EarIntervalType.minor3, EarIntervalType.perfect5)) {
      return 'Nasıl ayırırsın: 3\'lüler duygulu (mutlu ya da hüzünlü), 5\'li duygusuz ve '
          'güçlüdür. Duyduğun aralık sana bir duygu verdiyse büyük ihtimalle 3\'lüdür.';
    }
    if (b == EarIntervalType.octave || a == EarIntervalType.octave) {
      return 'İpucu: Oktavın iki notası "aynı nota" gibi duyulur; diğer aralıklarda iki '
          'farklı nota hissedersin.';
    }
    return null;
  }

  // --- Akor kaliteleri -----------------------------------------------------

  static String? _chord(String correctKey, String pickedKey) {
    final c = EarChordQuality.fromSrsKey(correctKey);
    final p = EarChordQuality.fromSrsKey(pickedKey);
    if (c == null || p == null) return null;
    bool pair(EarChordQuality x, EarChordQuality y) =>
        (c == x && p == y) || (c == y && p == x);

    final head = 'Seçtiğin ${p.label} (${_formula(p)}), doğrusu ${c.label} (${_formula(c)}).';
    String? tip;
    if (pair(EarChordQuality.major, EarChordQuality.minor)) {
      tip = 'Tek fark 3\'lü: majörde 4 yarım ses yukarıda, minörde 3. "Arpej çal"a bas ve '
          'ortadaki notayı mırıldan — aydınlıksa majör, gölgeliyse minör.';
    } else if (pair(EarChordQuality.sus2, EarChordQuality.power)) {
      tip = 'Power chord çıplaktır: sadece kök ve 5\'li, boş ve güçlü. Sus2\'de araya 2\'li '
          'girer — çan gibi parlak, hafif bir sürtünme duyarsın.';
    } else if (c == EarChordQuality.sus2 || p == EarChordQuality.sus2) {
      tip = 'Sus2\'de 3\'lü yok: akor ne gülümser ne üzülür, bir karara varmamış gibi asılı '
          'kalır.';
    } else if (c == EarChordQuality.power || p == EarChordQuality.power) {
      tip = 'Power chord\'da 3\'lü yok: renk yok, sadece güç. Majör/minör ise net bir duygu '
          'taşır.';
    } else if (pair(EarChordQuality.dominant7, EarChordQuality.major)) {
      tip = 'Dominant 7, majörün üstüne ♭7 ekler: aynı parlaklık ama huzursuz, "bir yere '
          'gitmek istiyor". Majör ise yerinde rahat durur.';
    } else if (pair(EarChordQuality.minor7, EarChordQuality.minor)) {
      tip = 'Minör 7, minörün sertliğini yumuşatır: daha kadife, daha caz. Sade minör daha '
          'çıplak ve keskindir.';
    } else if (pair(EarChordQuality.dominant7, EarChordQuality.minor7)) {
      tip = 'İkisinde de ♭7 var; farkı alttaki üçlü yapar: dominant 7 parlak ve gergin '
          '(majör taban), minör 7 gölgeli ve rahat (minör taban).';
    } else if (pair(EarChordQuality.dominant7, EarChordQuality.minor)) {
      tip = 'Dominant 7 parlak ama gergin, minör gölgeli ama durgun.';
    } else if (pair(EarChordQuality.minor7, EarChordQuality.major)) {
      tip = 'Minör 7 gölgeli ve yumuşak, majör aydınlık ve sade.';
    }
    return tip == null ? head : '$head\n$tip';
  }

  static String _formula(EarChordQuality q) => switch (q) {
        EarChordQuality.major => '1-3-5',
        EarChordQuality.minor => '1-♭3-5',
        EarChordQuality.sus2 => '1-2-5',
        EarChordQuality.power => '1-5',
        EarChordQuality.dominant7 => '1-3-5-♭7',
        EarChordQuality.minor7 => '1-♭3-5-♭7',
      };

  // --- Kadanslar -----------------------------------------------------------

  static String? _cadence(String correctKey, String pickedKey) {
    final c = EarCadenceType.fromSrsKey(correctKey);
    final p = EarCadenceType.fromSrsKey(pickedKey);
    if (c == null || p == null) return null;
    final head = 'Seçtiğin: ${p.label}. Doğrusu: ${c.label}.';
    return '$head\n${_cadenceEnding(c)}';
  }

  static String _cadenceEnding(EarCadenceType c) => switch (c) {
        EarCadenceType.I_IV =>
          'Son akora odaklan: evden uzaklaşıp açılıyor, ama gerilim yok — "nefes alma" hissi.',
        EarCadenceType.I_V =>
          'Son akora odaklan: cümle bitmedi, havada kaldı — "peki sonra?" diye soruyor (virgül).',
        EarCadenceType.i_VI =>
          'Başlangıç hüzünlü (minör), sonra yumuşak ve sıcak bir majöre iniyor — "çöküş" hissi.',
        EarCadenceType.V7_i =>
          'Gergin, parlak bir akordan hüzünlü bir eve sert ve kesin iniş — minörde "nokta".',
        EarCadenceType.I_V_vi_IV =>
          'Dört akor var, ikiye değil — uzun bir döngü: ev → gerilim → hüzün → açılış.',
        EarCadenceType.V_vi =>
          'Eve varacak sanırken beklenmedik, hüzünlü bir akora düşüyor — "şaşırtma" hissi.',
        EarCadenceType.IV_I =>
          'Yumuşak, gerilimsiz bir eve dönüş — "a-min" gibi sakin bir kapanış.',
      };

  // --- Harmonik ritim ------------------------------------------------------

  static String? _rhythm(String correctKey) {
    final what = switch (correctKey) {
      'rhythm_2_beats' => 'Hem "1"de hem "3"te değişim oldu: iki kat hızlı.',
      'rhythm_8_beats' => 'Bir "1"de değişti, sonraki "1"de değişmedi: her akor iki ölçü sürdü.',
      _ => 'Her "1"de bir değişim oldu: geniş ritim.',
    };
    return 'İçinden "1-2-3-4" say ve her akor değişiminde elini vur. $what Tempo her soruda '
        'farklı; süreye değil, değişimlere odaklan.';
  }

  // --- İnversiyon ----------------------------------------------------------

  static String? _inversion(String correctKey, String pickedKey) {
    final c = EarQuestionFactory.inversionKeys.indexOf(correctKey);
    final p = EarQuestionFactory.inversionKeys.indexOf(pickedKey);
    if (c < 0 || p < 0) return null;
    const was = ['akorun kökü', 'akorun 3\'lüsü', 'akorun 5\'lisi'];
    const chosen = ['kökü', '3\'lüyü', '5\'liyi'];
    final head = 'Basta ${was[c]} vardı, sen ${chosen[p]} seçtin. Üstteki akor üç seçenekte de '
        'aynıydı; fark sadece en pes notada.';
    final tip = switch (c) {
      0 => 'Kök pozisyonda bas, akorun adıyla aynı notadır: bası mırıldan, sonra akoru söyle — aynı "ev" hissi.',
      1 => '1. inversiyonda bas, akorun 3\'lüsüdür: kararlı ama kök pozisyon kadar "yere basmaz".',
      _ => '2. inversiyonda bas, akorun 5\'lisidir: basla üstü arasında 4\'lü oluşur, akor asılı ve çözülmemiş duyulur.',
    };
    return '$head\n$tip';
  }

  // --- Derece --------------------------------------------------------------

  static String? _degree(String correctKey, String pickedKey) {
    final c = EarQuestionFactory.degreeFromKey(correctKey);
    final p = EarQuestionFactory.degreeFromKey(pickedKey);
    if (c == null || p == null) return null;
    final names = EarQuestionFactory.degreeNames;
    final up = c > p;
    return 'Seçtiğin $p. derece (${names[p - 1]}), doğrusu $c. derece (${names[c - 1]}) — '
        'doğru nota ${up ? 'daha yukarıda' : 'daha aşağıda'}.\n'
        '${_degreeTendency(c)} "Eve çözülüşünü dinle"ye bas ve notanın eve nasıl yürüdüğünü duy.';
  }

  static String _degreeTendency(int d) => switch (d) {
        1 => 'Do evin kendisidir: hiçbir yere gitmek istemez.',
        2 => 'Re evin bir adım üstündedir: hafif askıda, aşağı Do\'ya iner.',
        3 => 'Mi sakin ve parlaktır: evin majör rengini taşır.',
        4 => 'Fa, Mi\'ye inmek ister: kulağında "aşağı" bir çekim hissedersin.',
        5 => 'Sol sağlam ama evden uzaktır: açık ve geniş durur.',
        6 => 'La hafif hüzünlüdür: Sol\'e ya da yukarı Do\'ya gitmek ister.',
        _ => 'Si eve yarım ses uzaktadır: güçlü bir "yukarı, eve" çekimi hissettirir.',
      };

  // --- Bas avcısı ----------------------------------------------------------

  static String? _bass(EarQuestion q, String pickedId) {
    final picked = q.optionById(pickedId);
    EarAnswerOption? correct;
    for (final id in q.correctIds) {
      correct = q.optionById(id);
      if (correct != null) break;
    }
    final pm = _midiOf(picked);
    final cm = _midiOf(correct);
    if (pm == null || cm == null) return null;
    final d = cm - pm;
    final dir = d > 0 ? 'daha tiz (yukarıda)' : 'daha pes (aşağıda)';
    final n = d.abs();
    if (n % 12 == 0) {
      return 'Nota ismi doğru ama ${n ~/ 12} oktav ${d > 0 ? 'aşağıda' : 'yukarıda'} seçtin. '
          'Bas avcılığında aynı notanın doğru oktavını bulmak gerekiyor: doğru ses $dir.';
    }
    return 'Seçtiğin perde doğru sesten $n yarım ses uzakta; doğru ses $dir. '
        'Aynı telde $n perde ${d > 0 ? 'yukarı' : 'aşağı'} kaydırmayı dene ve iki sesi '
        'karşılaştır.';
  }

  static int? _midiOf(EarAnswerOption? o) {
    if (o == null || o.stringNumber == null || o.fret == null) return null;
    final open = EarQuestionFactory.openStringMidi[o.stringNumber!];
    return open == null ? null : open + o.fret!;
  }
}

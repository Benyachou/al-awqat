// =============================================================================
// Textes des dou'as et adhkar liés aux 5 prières.
//
// Chaque entrée contient :
//   - titleFr / titleAr : libellé (souvent l'incipit en arabe).
//   - arabic           : texte arabe vocalisé.
//   - transliteration  : translittération phonétique en alphabet latin.
//   - translation      : traduction française.
//
// Les sources sont les recueils classiques d'adhkar (Hisn al-Muslim, etc.).
// Les longueurs varient volontairement — l'UI fait défiler chaque slide
// en proportion du nombre de mots du texte français.
// =============================================================================

class Dua {
  final String titleFr;
  final String titleAr;
  final String arabic;
  final String transliteration;
  final String translation;

  const Dua({
    required this.titleFr,
    required this.titleAr,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  /// Compte le nombre de mots du texte français (séparateur = espace).
  /// Utilisé pour calibrer le temps d'affichage d'une slide.
  int get wordCount =>
      translation.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

class Duas {
  // ===========================================================================
  // Invocation à réciter juste après que le mu'adhin a fini l'adhan.
  // ===========================================================================
  static const Dua afterAdhan = Dua(
    titleFr: 'Invocation après l\'adhan',
    titleAr: 'دعاء ما بعد الأذان',
    arabic:
        'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ وَالصَّلاَةِ الْقَائِمَةِ، '
        'آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، '
        'وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ',
    transliteration:
        'Allâhumma rabba hâdhihi-d-da\'wati-t-tâmmati was-salâti-l-qâ\'imati, '
        'âti Muhammadan-il-wasîlata wal-fadîlata, '
        'wab\'ath-hu maqâman mahmûdan-il-ladhî wa\'ad-tah',
    translation:
        'Ô Allah, Maître de cet appel parfait et de la prière qui va être '
        'accomplie, donne à Mohammed le pouvoir d\'intercéder (le Jour du '
        'Jugement) et la place d\'honneur [au Paradis], et ressuscite-le dans '
        'la position louable que Tu lui as promise.',
  );

  // ===========================================================================
  // Adhkar récités après la prière obligatoire. Tirés des recueils
  // classiques (sahih Muslim, Bukhari, Hisn al-Muslim).
  //
  // L'ordre suit la sunna :
  //   1. Astaghfir × 3
  //   2. Allâhumma anta-s-salâm
  //   3. Allâhumma a'innî 'alâ dhikrik
  //   4. Sub-hânallah × 33
  //   5. Al-hamdu li-llâh × 33
  //   6. Allâhu akbar × 33
  //   7. La ilaha illa-llâh wahdah... (la 100ème, complète à 100)
  //   8. Âyat al-Kursî
  //   9. Sourate Al-Ikhlâs (× 3)
  //   10. Sourate Al-Falaq
  //   11. Sourate An-Nâs
  //
  // L'UI défile à travers ces 11 slides puis recommence ; le widget répète
  // 3 cycles complets avant de figer la dernière slide.
  // ===========================================================================
  static const List<Dua> afterPrayer = [
    Dua(
      titleFr: 'Demande de pardon (× 3)',
      titleAr: 'الاستغفار × 3',
      arabic: 'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Astaghfiru-llâh, astaghfiru-llâh, astaghfiru-llâh',
      translation: 'Je demande pardon à Allah (à dire trois fois).',
    ),
    Dua(
      titleFr: 'Invocation de paix',
      titleAr: 'اللَّهُمَّ أَنْتَ السَّلاَمُ',
      arabic:
          'اللَّهُمَّ أَنْتَ السَّلاَمُ وَمِنْكَ السَّلاَمُ، '
          'تَبَارَكْتَ يَا ذَا الْجَلاَلِ وَالْإِكْرَامِ',
      transliteration:
          'Allâhumma anta-s-salâmu wa minka-s-salâm, '
          'tabârakta yâ dhâ-l-jalâli wal-ikrâm',
      translation:
          'Ô Allah, Tu es La Paix et de Toi vient la paix, béni sois-Tu, '
          'ô Détenteur de la Majesté et de la Munificence.',
    ),
    Dua(
      titleFr: 'Aide pour Te rappeler',
      titleAr: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ',
      arabic:
          'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      transliteration:
          'Allâhumma a\'innî \'alâ dhikrika wa shukrika wa husni \'ibâdatik',
      translation:
          'Ô Allah, aide-moi à T\'évoquer, à Te remercier et à T\'adorer '
          'de la meilleure façon.',
    ),
    Dua(
      titleFr: 'Tasbih (× 33)',
      titleAr: 'سُبْحَانَ اللَّهِ × 33',
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: 'Sub-hâna-llâh (× 33)',
      translation:
          'Gloire à Allah, à répéter trente-trois fois après chaque prière '
          'obligatoire.',
    ),
    Dua(
      titleFr: 'Tahmid (× 33)',
      titleAr: 'الْحَمْدُ لِلَّهِ × 33',
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Al-hamdu li-llâh (× 33)',
      translation:
          'Louange à Allah, à répéter trente-trois fois après chaque prière '
          'obligatoire.',
    ),
    Dua(
      titleFr: 'Takbir (× 33)',
      titleAr: 'اللَّهُ أَكْبَرُ × 33',
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allâhu akbar (× 33)',
      translation:
          'Allah est le plus Grand, à répéter trente-trois fois après chaque '
          'prière obligatoire.',
    ),
    Dua(
      titleFr: 'Chahada — 100ème dhikr',
      titleAr: 'لاَ إِلَهَ إِلاَّ اللَّهُ — تَمَامُ المِائَةِ',
      arabic:
          'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، '
          'لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration:
          'Lâ ilâha illâ-llâhu wahdahu lâ sharîka lah, '
          'lahu-l-mulku wa lahu-l-hamd, wa huwa \'alâ kulli shay\'in qadîr',
      translation:
          'Il n\'y a de divinité qu\'Allah, Unique, sans associé. À Lui la '
          'royauté et la louange, et Il est puissant sur toute chose. '
          'Récitée une fois pour compléter le total à cent dhikr.',
    ),
    Dua(
      titleFr: 'Âyat al-Kursî',
      titleAr: 'آية الكرسي',
      arabic:
          'اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ، '
          'لاَ تَأْخُذُهُ سِنَةٌ وَلاَ نَوْمٌ، '
          'لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الأَرْضِ، '
          'مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بِإِذْنِهِ، '
          'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، '
          'وَلاَ يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلاَّ بِمَا شَاءَ، '
          'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالأَرْضَ، '
          'وَلاَ يَؤُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      transliteration:
          'Allâhu lâ ilâha illâ huwa-l-hayyu-l-qayyûm, lâ ta\'khudhuhu sinatun '
          'wa lâ nawm, lahu mâ fî-s-samâwâti wa mâ fî-l-ard, man dhâ-lladhî '
          'yashfa\'u \'indahu illâ bi-idhnih...',
      translation:
          'Allah, point de divinité à part Lui, le Vivant, Celui qui '
          'subsiste par lui-même. Ni somnolence ni sommeil ne Le saisissent. '
          'À Lui appartient tout ce qui est dans les cieux et sur la terre. '
          'Qui peut intercéder auprès de Lui sans Sa permission ? '
          '(Coran 2:255 — verset du Trône).',
    ),
    Dua(
      titleFr: 'Sourate Al-Ikhlâs (× 3)',
      titleAr: 'سورة الإخلاص × 3',
      arabic:
          'قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، '
          'لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ',
      transliteration:
          'Qul huwa-llâhu ahad, Allâhu-s-samad, lam yalid wa lam yûlad, '
          'wa lam yakun lahu kufuwan ahad',
      translation:
          'Dis : « Il est Allah, Unique. Allah, le Soutien Absolu. Il n\'a '
          'jamais engendré, n\'a pas été engendré non plus, et nul n\'est '
          'égal à Lui. » (Coran 112 — à réciter trois fois).',
    ),
    Dua(
      titleFr: 'Sourate Al-Falaq',
      titleAr: 'سورة الفلق',
      arabic:
          'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِنْ شَرِّ مَا خَلَقَ، '
          'وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ، '
          'وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، '
          'وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ',
      transliteration:
          'Qul a\'ûdhu bi-rabbi-l-falaq, min sharri mâ khalaq, wa min sharri '
          'ghâsiqin idhâ waqab, wa min sharri-n-naffâthâti fî-l-\'uqad, '
          'wa min sharri hâsidin idhâ hasad',
      translation:
          'Dis : « Je cherche refuge auprès du Seigneur de l\'aube naissante '
          'contre le mal des êtres qu\'Il a créés, contre le mal de '
          'l\'obscurité quand elle s\'approfondit, contre le mal de celles '
          'qui soufflent sur les nœuds, et contre le mal de l\'envieux '
          'quand il envie. » (Coran 113).',
    ),
    Dua(
      titleFr: 'Sourate An-Nâs',
      titleAr: 'سورة الناس',
      arabic:
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَهِ النَّاسِ، '
          'مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، '
          'الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ',
      transliteration:
          'Qul a\'ûdhu bi-rabbi-n-nâs, maliki-n-nâs, ilâhi-n-nâs, min sharri-l-'
          'waswâsi-l-khannâs, alladhî yuwaswisu fî sudûri-n-nâs, mina-l-jinnati '
          'wa-n-nâs',
      translation:
          'Dis : « Je cherche refuge auprès du Seigneur des hommes, du Roi '
          'des hommes, du Dieu des hommes, contre le mal du mauvais '
          'conseiller furtif, qui souffle le mal dans les poitrines des '
          'hommes, qu\'il soit djinn ou homme. » (Coran 114).',
    ),
  ];
}

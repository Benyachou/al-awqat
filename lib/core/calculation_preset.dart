import 'package:adhan/adhan.dart';

class CalculationPreset {
  final String key;
  final String label;
  final CalculationParameters Function() build;

  const CalculationPreset({
    required this.key,
    required this.label,
    required this.build,
  });

  static final mosqueeParis = CalculationPreset(
    key: 'mosquee_paris',
    label: 'Mosquée de Paris (France)',
    build: () => CalculationParameters(fajrAngle: 12.0, ishaAngle: 12.0),
  );

  static final uoifFrance = CalculationPreset(
    key: 'uoif_france',
    label: 'UOIF / France 15°',
    build: () => CalculationParameters(fajrAngle: 15.0, ishaAngle: 15.0),
  );

  static CalculationPreset _builtin(
    String key,
    String label,
    CalculationMethod method,
  ) {
    return CalculationPreset(
      key: key,
      label: label,
      build: () => method.getParameters(),
    );
  }

  static final muslimWorldLeague = _builtin(
    'mwl',
    'Muslim World League (international)',
    CalculationMethod.muslim_world_league,
  );

  static final ummAlQura = _builtin(
    'umm_al_qura',
    'Umm al-Qura (Arabie Saoudite)',
    CalculationMethod.umm_al_qura,
  );

  static final isna = _builtin(
    'isna',
    'ISNA (Amérique du Nord)',
    CalculationMethod.north_america,
  );

  static final egyptian = _builtin(
    'egyptian',
    'Égyptienne',
    CalculationMethod.egyptian,
  );

  static final karachi = _builtin(
    'karachi',
    'Karachi (Pakistan)',
    CalculationMethod.karachi,
  );

  static final dubai = _builtin('dubai', 'Dubaï', CalculationMethod.dubai);
  static final qatar = _builtin('qatar', 'Qatar', CalculationMethod.qatar);
  static final kuwait = _builtin('kuwait', 'Koweït', CalculationMethod.kuwait);
  static final turkey = _builtin('turkey', 'Turquie', CalculationMethod.turkey);
  static final tehran = _builtin('tehran', 'Téhéran', CalculationMethod.tehran);
  static final singapore =
      _builtin('singapore', 'Singapour', CalculationMethod.singapore);
  static final moonsighting = _builtin(
    'moonsighting',
    'Moonsighting Committee',
    CalculationMethod.moon_sighting_committee,
  );

  static final List<CalculationPreset> all = [
    mosqueeParis,
    uoifFrance,
    muslimWorldLeague,
    ummAlQura,
    isna,
    egyptian,
    karachi,
    dubai,
    qatar,
    kuwait,
    turkey,
    tehran,
    singapore,
    moonsighting,
  ];

  static CalculationPreset byKey(String key) {
    return all.firstWhere(
      (p) => p.key == key,
      orElse: () => mosqueeParis,
    );
  }
}

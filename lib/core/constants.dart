class PrayerNames {
  static const Map<String, String> arabic = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  static const Map<String, String> french = {
    'fajr': 'Fajr',
    'sunrise': 'Lever',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };
}

class PresetCities {
  static const Map<String, (double, double)> coordinates = {
    'Ganges, France (34190)': (43.9333, 3.7167),
    'Montpellier, France': (43.6109, 3.8772),
    'Nîmes, France': (43.8367, 4.3601),
    'Paris, France': (48.8566, 2.3522),
    'Lyon, France': (45.7640, 4.8357),
    'Marseille, France': (43.2965, 5.3698),
    'Bruxelles, Belgique': (50.8503, 4.3517),
    'Casablanca, Maroc': (33.5731, -7.5898),
    'Alger, Algérie': (36.7538, 3.0588),
    'Tunis, Tunisie': (36.8065, 10.1815),
    'La Mecque': (21.4225, 39.8262),
    'Médine': (24.5247, 39.5692),
    'Istanbul, Turquie': (41.0082, 28.9784),
  };
}

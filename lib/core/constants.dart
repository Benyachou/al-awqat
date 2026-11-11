// =============================================================================
// Constantes textuelles et géographiques de l'app.
//
// On garde ici les données figées qu'on ne veut pas dupliquer dans plusieurs
// widgets. Tous les widgets qui affichent un nom de prière en arabe ou en
// français passent par PrayerNames pour rester cohérents.
// =============================================================================

/// Vrai quand l'app tourne en fond d'écran sur PC (lancée avec --fond).
/// La barre des tâches Windows cache le bas de l'écran : le bandeau des
/// horaires passe alors en haut.
bool fondEcran = false;

/// Vrai quand l'app tourne en écran de veille sur PC (lancée par Windows
/// avec /s). Elle reste muette : c'est le fond d'écran qui joue l'adhan,
/// sinon on l'entendrait deux fois.
bool ecranVeille = false;

/// Noms des 5 prières + lever du soleil, en arabe vocalisé et en
/// translittération latine. Les clés sont les `name` de l'enum PrayerSlot
/// (`fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`) — comme ça on peut
/// faire `PrayerNames.french[slot.name]!` partout sans switch.
class PrayerNames {
  /// Noms en arabe avec voyelles (s'affichent en RTL via Directionality).
  static const Map<String, String> arabic = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  /// Translittération latine. On garde "Shurûq" (avec û) pour le lever du
  /// soleil — c'est le terme arabe direct, plus reconnaissable pour les
  /// musulmans francophones que "Lever".
  static const Map<String, String> french = {
    'fajr': 'Fajr',
    'sunrise': 'Shurûq',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };
}

/// Liste figée de villes pré-réglées disponibles dans le dropdown des
/// paramètres. Chaque entrée mappe un libellé affiché à un couple
/// `(latitude, longitude)` en degrés décimaux.
///
/// Si tu ajoutes une ville, copie-colle simplement une ligne — pas besoin
/// de toucher au reste du code. Le dropdown se peuple automatiquement à
/// partir des clés de cette Map.
///
/// Pour les villes hors de cette liste, l'utilisateur peut utiliser la
/// recherche Nominatim (en ligne) ou saisir lat/long manuellement.
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

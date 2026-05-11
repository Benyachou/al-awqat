# Al-awqat

Application Flutter d'horaires de prières pensée pour tourner en plein écran sur une box Android (TV, mini-PC, écran de salon ou de mosquée). Fonctionne **entièrement hors-ligne** une fois installée — aucun appel réseau requis pour l'affichage des horaires.

## Fonctionnalités

### Horaires
- Calcul local via le package [`adhan`](https://pub.dev/packages/adhan) — aucun appel API.
- 14 méthodes de calcul (Mosquée de Paris, UOIF, MWL, Umm al-Qura, ISNA, Égyptienne, Karachi, Dubaï, Qatar, Koweït, Turquie, Téhéran, Singapour, Moonsighting Committee).
- Madhab Shafi / Hanafi (impacte le calcul de l'Asr).
- Ajustements fins par prière (±15 min) pour s'aligner sur la mosquée locale.
- Remplacement automatique de Dhuhr par **Jumu'ah** le vendredi à l'heure choisie.
- Décalage Hijri ±2 jours pour s'aligner sur l'observation lunaire locale.
- Heure d'été / d'hiver gérée automatiquement par le système.

### Affichage
- Cadran 24h avec dégradé jour/nuit, marqueurs des prières et aiguille temps réel.
- Anneau coloré des **périodes spirituelles** : Karaha (interdites), Doha, lecture du Coran, Tahajjud (dernier tiers de la nuit).
- Compte à rebours iqama après chaque adhan.
- Compte à rebours vers la prochaine prière.
- Date hijrie (`hijri` package).
- Liste des horaires (français + arabe).

### Outils
- **Qibla** : boussole magnétique avec calcul d'azimut grand-cercle vers la Kaaba (`flutter_compass`).
- **Calendrier mensuel** : navigation mois précédent/suivant avec horaires complets.
- **Recherche de ville** via OpenStreetMap Nominatim, ou saisie manuelle lat/long.
- **Adhan** : lecture audio, contrôle de volume, bouton stop, anti-rejeu après reboot (timestamp persisté).
- **Mises à jour** : vérification automatique 1×/jour de la dernière release GitHub, badge dans l'UI, ouverture du lien APK.

## Lancement

```bash
flutter pub get
flutter run -d <device-id>
```

L'app force l'orientation paysage et le mode immersif, et garde l'écran allumé via `wakelock_plus`.

## Personnalisation

### Adhan audio
Place un fichier `adhan.mp3` dans `assets/audio/`. S'il est absent, l'option « Jouer l'adhan » reste sans effet (échec silencieux).

### Auto-update GitHub
Renseigne `owner/repo` dans **Paramètres → Mises à jour**. L'app interrogera `api.github.com/repos/<repo>/releases/latest` au lancement (max 1×/24h) et affichera un badge orange si une nouvelle version est disponible. Si la release contient un asset `.apk`, le bouton « Télécharger APK » ouvre directement le lien.

## Structure

```
lib/
├── core/              ← engine de calcul, périodes, presets, thème
├── models/            ← AppSettings
├── providers/         ← PrayerProvider (ChangeNotifier, ticker 1s)
├── services/          ← audio, settings, geocoding, qibla, update
├── screens/           ← home, settings, qibla, monthly
├── widgets/           ← dial 24h, prayer rows, countdowns, hijri, period
└── main.dart / app.dart
```

## Tests

```bash
flutter test
```

Tests unitaires sur le moteur de prière, le calculateur de périodes, le service Qibla et le parsing des versions.

## Stack

Flutter 3.11+ · Dart 3.11 · `adhan` · `provider` · `shared_preferences` · `audioplayers` · `wakelock_plus` · `hijri` · `flutter_compass` · `geolocator` · `url_launcher` · `intl` · `package_info_plus`.

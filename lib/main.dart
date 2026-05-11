// =============================================================================
// Point d'entrée de l'application Al-awqat.
//
// Cette fonction `main` est exécutée UNE SEULE FOIS au démarrage. Elle :
//   1. Initialise le binding Flutter (obligatoire avant tout appel système).
//   2. Charge les données de localisation française (pour DateFormat 'EEEE...').
//   3. Force l'orientation paysage (l'app est conçue pour une box/TV horizontale).
//   4. Active le mode plein écran immersif (cache la barre de navigation Android).
//   5. Active le wakelock (l'écran ne s'éteint jamais — c'est un panneau permanent).
//   6. Charge les préférences sauvegardées (SharedPreferences).
//   7. Lance l'app dans un Provider qui partage le PrayerProvider à tout l'arbre.
//
// Note : si tu changes l'ordre, fais attention — initializeDateFormatting doit
// précéder tout DateFormat avec un locale.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'providers/prayer_provider.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  // Bridge Flutter ↔ moteur Skia : indispensable avant tout appel async/plugin.
  WidgetsFlutterBinding.ensureInitialized();

  // Charge les locales pour le package `intl` (noms de mois, jours en français).
  // Sans ça, DateFormat('EEEE d MMMM', 'fr_FR') lance une exception.
  await initializeDateFormatting('fr_FR', null);

  // Verrouille l'orientation : l'app est faite pour un écran horizontal
  // (box Android branchée sur une TV de mosquée, par exemple).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // immersiveSticky = cache les barres système ; elles réapparaissent
  // brièvement au swipe puis se cachent à nouveau. Idéal pour un affichage
  // permanent où on veut voir uniquement l'horloge et les prières.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Empêche l'écran de s'éteindre tant que l'app tourne au premier plan.
  // Critique pour un panneau d'affichage de mosquée qui doit tourner 24h/24.
  WakelockPlus.enable();

  // SettingsService lit toutes les préférences (coords, méthode de calcul,
  // tailles UI, etc.) depuis SharedPreferences AVANT d'instancier le provider,
  // sinon le premier rendu utiliserait les valeurs par défaut puis "saute".
  final settingsService = SettingsService();
  await settingsService.load();

  // PrayerProvider est le ChangeNotifier central : il tick chaque seconde,
  // recalcule les horaires, expose l'état d'affichage (adhan, iqama, etc.),
  // et notifie tous les widgets qui le consomment via Consumer/context.watch.
  runApp(
    ChangeNotifierProvider(
      create: (_) => PrayerProvider(settingsService),
      child: const AlAwqatApp(),
    ),
  );
}

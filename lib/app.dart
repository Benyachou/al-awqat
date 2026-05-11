// =============================================================================
// AlAwqatApp = racine de l'arbre Widget.
//
// Configure MaterialApp avec :
//   - le thème sombre maison (AppTheme.dark)
//   - le français comme locale par défaut (les textes UI sont en français)
//   - l'anglais en fallback (utile sur certaines TV non-FR)
//   - les delegates Material/Widgets/Cupertino pour la localisation native
//     (formats de date, AlertDialog, etc.)
//   - HomeScreen comme première page
//
// Le `debugShowCheckedModeBanner: false` retire la bannière rouge "DEBUG"
// en haut à droite en mode développement — sinon ça pollue l'affichage de
// la mosquée pendant les tests.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'screens/home_screen.dart';

class AlAwqatApp extends StatelessWidget {
  const AlAwqatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-awqat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Locale forcé à fr_FR : tous les textes de l'app sont en français,
      // et on veut "vendredi 10 mai 2026" pas "Friday May 10, 2026".
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}

// =============================================================================
// Palette et thème centralisés de l'application.
//
// Toutes les couleurs et ombres réutilisables sont définies ici comme
// constantes statiques. Si tu veux changer la teinte générale (par ex passer
// d'un bleu nuit à un vert mosquée), c'est le seul fichier à toucher.
//
// Convention : les widgets n'utilisent JAMAIS de Color(0xFF...) en dur, ils
// passent toujours par AppTheme.xxx — comme ça la cohérence visuelle est
// garantie sur tout l'écran.
// =============================================================================

import 'package:flutter/material.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // Couleurs principales
  // ---------------------------------------------------------------------------

  /// Fond très sombre bleu nuit. Utilisé si l'image d'arrière-plan ne charge pas.
  static const Color background = Color(0xFF0A1929);

  /// Fond des cartes/pilules dans les paramètres (un cran plus clair).
  static const Color surface = Color(0xFF132F4C);

  /// Bleu accent — utilisé pour les éléments "next" (prochaine prière),
  /// les bordures des chips info, et les boutons de Settings.
  static const Color accent = Color(0xFF66B2FF);

  /// Orange chaud — réservé aux éléments "current" (prière en cours) et aux
  /// alertes/highlights (jauge de vie, badge update, halo focus TV).
  static const Color highlight = Color(0xFFFFB74D);

  /// Blanc pur pour le texte principal — lisible sur fond sombre/photo.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Gris bleuté pour les libellés secondaires (sous-titres, dates discrètes).
  static const Color textSecondary = Color(0xFFB0BEC5);

  /// Bleu intermédiaire pour les séparateurs (Divider dans Settings).
  static const Color divider = Color(0xFF1E4976);

  // ---------------------------------------------------------------------------
  // Ombres réutilisables pour le texte
  //
  // Pourquoi deux niveaux d'ombre ? L'app affiche du texte par-dessus une
  // photo de mosquée. Sans ombre, un mot blanc sur un nuage clair devient
  // illisible. L'ombre noire derrière chaque lettre garantit le contraste
  // quel que soit le fond.
  // ---------------------------------------------------------------------------

  /// Ombre douce, deux passes (8 px + 16 px) pour les textes courants.
  /// Le `0xCC` = 80 % d'opacité, `0x99` = 60 %.
  static const List<Shadow> textShadow = [
    Shadow(color: Color(0xCC000000), blurRadius: 8, offset: Offset(0, 2)),
    Shadow(color: Color(0x99000000), blurRadius: 16, offset: Offset(0, 1)),
  ];

  /// Ombre renforcée pour la grande horloge XL (qui mesure 78+ px).
  /// Sans cette version, l'ombre douce devient ridicule à cette taille.
  static const List<Shadow> textShadowStrong = [
    Shadow(color: Color(0xE6000000), blurRadius: 16, offset: Offset(0, 3)),
    Shadow(color: Color(0xB3000000), blurRadius: 30, offset: Offset(0, 2)),
  ];

  // ---------------------------------------------------------------------------
  // ThemeData Material global
  //
  // Appliqué à toute l'app via MaterialApp(theme: AppTheme.dark).
  // Affecte automatiquement AppBar, Switch, Slider, Dialog, etc.
  // ---------------------------------------------------------------------------

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: highlight,
          surface: surface,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(color: textPrimary),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
        ),
      );
}

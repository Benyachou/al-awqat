// =============================================================================
// SideInfo : pilule latérale affichant un libellé + une heure.
//
// Deux instances de ce widget encadrent la grande horloge centrale :
//   - à gauche : Shurûq (lever du soleil) avec l'heure du jour
//   - à droite : Jumu'ah (vendredi) avec l'heure de la khutba
//
// C'est un widget purement présentatif — il ne lit aucun setting et
// n'a aucune logique métier. Tout vient en paramètres.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';

class SideInfo extends StatelessWidget {
  const SideInfo({
    super.key,
    required this.label,
    required this.arabicLabel,
    required this.time,
    this.scale = 1.0,
    this.isActive = false,
  });

  /// Libellé en français ("Shurûq", "Jumu'ah").
  final String label;

  /// Libellé en arabe vocalisé ("الشروق", "الجمعة"). Affiché en gros au-dessus.
  final String arabicLabel;

  /// Heure à afficher en HH:MM. Si null, affiche "--:--" (cas Jumu'ah désactivé).
  final DateTime? time;

  /// Facteur multiplicatif (sideScale × fontScale depuis les Settings).
  final double scale;

  /// Si true, met la pilule en surbrillance dorée (Jumu'ah actif).
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final timeStr = time != null ? DateFormat('HH:mm').format(time!) : '--:--';
    final s = scale;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6 * s),
      padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 18 * s),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.highlight.withValues(alpha: 0.18)
            : Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(
          color: isActive
              ? AppTheme.highlight.withValues(alpha: 0.90)
              : Colors.white.withValues(alpha: 0.18),
          width: isActive ? 2.0 : 1.4,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.highlight.withValues(alpha: 0.30),
                  blurRadius: 18,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabicLabel,
            style: TextStyle(
              fontSize: 28 * s,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              shadows: AppTheme.textShadow,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16 * s,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              shadows: AppTheme.textShadow,
            ),
          ),
          SizedBox(height: 8 * s),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 44 * s,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.highlight : AppTheme.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1,
              shadows: AppTheme.textShadowStrong,
            ),
          ),
        ],
      ),
    );
  }
}

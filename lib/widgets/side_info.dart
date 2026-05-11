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
  });

  /// Libellé en français ("Shurûq", "Jumu'ah").
  final String label;

  /// Libellé en arabe vocalisé ("الشروق", "الجمعة"). Affiché en gros au-dessus.
  final String arabicLabel;

  /// Heure à afficher en HH:MM. Si null, affiche "--:--" (cas Jumu'ah désactivé).
  final DateTime? time;

  /// Facteur multiplicatif (sideScale × fontScale depuis les Settings).
  final double scale;

  @override
  Widget build(BuildContext context) {
    final timeStr = time != null ? DateFormat('HH:mm').format(time!) : '--:--';
    final s = scale;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6 * s),
      padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 18 * s),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.4,
        ),
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
              color: AppTheme.textPrimary,
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

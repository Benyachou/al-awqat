// =============================================================================
// PrayerCard : une carte affichant une prière (nom arabe + français + heure).
//
// Six de ces cartes sont alignées en bas du HomeScreen (Fajr, Shurûq, Dhuhr,
// Asr, Maghrib, Isha). L'apparence change selon l'état (`PrayerCardState`) :
//
//   - upcoming : prière à venir aujourd'hui — fond sombre, bordure grise.
//   - next     : prochaine prière — bordure bleue + jauge bleue qui SE REMPLIT
//                à mesure qu'on s'en approche.
//   - current  : prière en cours (entre son heure et la suivante) — bordure
//                orange + jauge orange qui SE VIDE comme une barre de vie.
//   - passed   : prière déjà passée aujourd'hui — grisée.
//
// La jauge `fillProgress` est calculée dans home_screen.dart (_fillFor) et
// passée en prop. C'est le widget HomeScreen qui décide quand l'afficher,
// pas la carte elle-même — elle ne fait que dessiner ce qu'on lui dit.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';

/// État visuel d'une carte. Détermine couleurs/bordure/jauge.
enum PrayerCardState { upcoming, current, next, passed }

class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.slot,
    required this.time,
    required this.iqamaMinutes,
    required this.state,
    this.isJumuah = false,
    this.showIqama = true,
    this.fillProgress,
    this.jumuahLabel,
    this.scale = 1.0,
    this.now,
  });

  /// Identifiant de la prière (fajr, dhuhr, ...). Dérive son label.
  final PrayerSlot slot;

  /// Heure réelle de la prière pour aujourd'hui.
  final DateTime time;

  /// Délai en minutes après l'adhan avant l'iqama, affiché en badge "+10'".
  final int iqamaMinutes;

  /// État visuel — pilote couleur/bordure (voir _colorsFor).
  final PrayerCardState state;

  /// Vrai si on est vendredi et que jumuahEnabled = true. Si oui, ET si
  /// `slot == dhuhr`, on affiche "Jumu'ah" / الجمعة à la place de Dhuhr.
  final bool isJumuah;

  /// Cache le badge iqama. Utile pour la carte Shurûq (lever de soleil)
  /// qui n'a pas d'iqama.
  final bool showIqama;

  /// Si non null, dessine la jauge de fond animée :
  ///   - sur current : fillProgress va de 1.0 (plein) à 0.0 (vide), comme
  ///     une barre de vie qui descend.
  ///   - sur next : fillProgress va de 0.0 à 1.0, comme un chargement.
  /// Voir home_screen.dart _fillFor pour le calcul.
  final double? fillProgress;

  /// Étiquette additionnelle (legacy). N'est plus passé par défaut.
  final String? jumuahLabel;

  /// Facteur multiplicatif pour toutes les tailles internes (fontSize,
  /// paddings, SizedBox). Vient de settings.cardScale × settings.fontScale.
  final double scale;

  /// Heure courante. Optionnel — si fourni ET que la carte est en état
  /// `current`, le badge iqama devient un compte à rebours dynamique
  /// (`Iqama 03:42`) au lieu du badge statique `+10'`.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final isJumuahSlot = isJumuah && slot == PrayerSlot.dhuhr;
    final french = isJumuahSlot ? 'Jumu\'ah' : PrayerNames.french[slot.name]!;
    final arabic =
        isJumuahSlot ? 'الجمعة' : PrayerNames.arabic[slot.name]!;
    final timeStr = DateFormat('HH:mm').format(time);
    final colors = _colorsFor(state);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 1.2),
        boxShadow: state == PrayerCardState.current
            ? [
                BoxShadow(
                  color: colors.border.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (fillProgress != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  heightFactor: fillProgress!.clamp(0.0, 1.0),
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      // Bordure lumineuse en haut de la jauge = niveau actuel.
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.highlight,
                          width: 3,
                        ),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colors.fillTop, colors.fillBottom],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.highlight.withValues(alpha: 0.6),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 6 * scale, vertical: 10 * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      arabic,
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w600,
                        color: colors.fg,
                        height: 1,
                        shadows: AppTheme.textShadow,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      french,
                      style: TextStyle(
                        fontSize: 14 * scale,
                        color: colors.fg.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                        shadows: AppTheme.textShadow,
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 40 * scale,
                        fontWeight: FontWeight.bold,
                        color: colors.fg,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        height: 1,
                        shadows: AppTheme.textShadow,
                      ),
                    ),
                    if (showIqama) ...[
                      SizedBox(height: 6 * scale),
                      _IqamaBadge(
                        text: _iqamaBadgeText(),
                        highlighted: _isCurrentBeforeIqama(),
                        fg: colors.fg,
                        scale: scale,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vrai si on est sur la carte de la prière COURANTE et qu'on n'a pas
  /// encore atteint l'heure de l'iqama. C'est dans cette fenêtre qu'on
  /// montre un VRAI compte à rebours (MM:SS qui décroît).
  bool _isCurrentBeforeIqama() {
    if (state != PrayerCardState.current || now == null) return false;
    final iqamaAt = time.add(Duration(minutes: iqamaMinutes));
    return now!.isBefore(iqamaAt);
  }

  /// Texte du badge iqama :
  ///   - prière courante avant iqama : « Iqama  03:42 » (countdown live)
  ///   - prière courante après iqama : « En prière » (badge calme)
  ///   - autres cas : « +10' » (offset statique de la mosquée)
  String _iqamaBadgeText() {
    if (state == PrayerCardState.current && now != null) {
      final iqamaAt = time.add(Duration(minutes: iqamaMinutes));
      final remaining = iqamaAt.difference(now!);
      if (remaining.isNegative || remaining == Duration.zero) {
        return 'En prière';
      }
      final m = remaining.inMinutes;
      final s = remaining.inSeconds % 60;
      return 'Iqama  ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '+$iqamaMinutes\'';
  }

  _CardColors _colorsFor(PrayerCardState state) {
    switch (state) {
      case PrayerCardState.current:
        return _CardColors(
          bg: const Color(0xFF1A2D4A).withValues(alpha: 0.55),
          fg: AppTheme.textPrimary,
          border: AppTheme.highlight.withValues(alpha: 0.95),
          fillTop: AppTheme.highlight.withValues(alpha: 0.80),
          fillBottom: AppTheme.highlight.withValues(alpha: 0.30),
        );
      case PrayerCardState.next:
        return _CardColors(
          bg: const Color(0xFF0F1F38).withValues(alpha: 0.55),
          fg: AppTheme.textPrimary,
          border: AppTheme.accent.withValues(alpha: 0.85),
          fillTop: AppTheme.accent.withValues(alpha: 0.20),
          fillBottom: AppTheme.accent.withValues(alpha: 0.05),
        );
      case PrayerCardState.passed:
        return _CardColors(
          bg: Colors.black.withValues(alpha: 0.35),
          fg: AppTheme.textSecondary.withValues(alpha: 0.65),
          border: Colors.white.withValues(alpha: 0.10),
          fillTop: Colors.transparent,
          fillBottom: Colors.transparent,
        );
      case PrayerCardState.upcoming:
        return _CardColors(
          bg: const Color(0xFF0A1929).withValues(alpha: 0.55),
          fg: AppTheme.textPrimary,
          border: Colors.white.withValues(alpha: 0.18),
          fillTop: Colors.transparent,
          fillBottom: Colors.transparent,
        );
    }
  }
}

/// Badge sous l'heure de la prière. En statique : pilule discrète avec le
/// délai mosquée (« +10' »). En mode countdown (prière courante avant
/// iqama) : pilule plus marquée avec halo doré, chiffres tabulaires et
/// icône de timer pour signaler que ça tourne en direct.
class _IqamaBadge extends StatelessWidget {
  const _IqamaBadge({
    required this.text,
    required this.highlighted,
    required this.fg,
    required this.scale,
  });
  final String text;
  final bool highlighted;
  final Color fg;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final fontSize = (highlighted ? 14.0 : 13.0) * scale;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (highlighted ? 10 : 8) * scale,
        vertical: (highlighted ? 4 : 2) * scale,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.highlight.withValues(alpha: 0.22)
            : fg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: highlighted
            ? Border.all(
                color: AppTheme.highlight.withValues(alpha: 0.7),
                width: 1.2,
              )
            : null,
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppTheme.highlight.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlighted) ...[
            Icon(
              Icons.timer_outlined,
              size: fontSize + 2,
              color: AppTheme.highlight,
            ),
            SizedBox(width: 4 * scale),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: highlighted ? AppTheme.highlight : fg,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardColors {
  final Color bg;
  final Color fg;
  final Color border;
  final Color fillTop;
  final Color fillBottom;
  _CardColors({
    required this.bg,
    required this.fg,
    required this.border,
    required this.fillTop,
    required this.fillBottom,
  });
}

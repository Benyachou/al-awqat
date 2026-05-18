// =============================================================================
// MawaqitClock : le bloc central du HomeScreen.
//
// Composé de 3 éléments empilés verticalement :
//   1. La grosse horloge HH:MM + :SS (mêmes tailles, alignées au centre).
//   2. Un chip "<NextPrayer> dans 1 h 20 min" en bleu accent.
//   3. Une pilule verte islamique avec la date hijrie en gros — c'est
//      l'info la plus importante de l'écran, mise en avant volontairement.
//
// Le tout est centré et utilise `MainAxisSize.min` pour ne prendre que
// la place nécessaire (le wrapper dans HomeScreen ajoute le cadre sombre).
//
// Le facteur `scale` multiplie toutes les fontSize et paddings — vient de
// settings.clockScale × settings.fontScale.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/hijri_helper.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';

class MawaqitClock extends StatelessWidget {
  const MawaqitClock({
    super.key,
    required this.now,
    required this.nextSlot,
    required this.untilNext,
    required this.hijriOffset,
    this.scale = 1.0,
    this.nextSlotLabel,
  });

  final DateTime now;
  final PrayerSlot? nextSlot;
  final Duration untilNext;
  final int hijriOffset;
  final double scale;

  /// Si renseigné, remplace le label calculé depuis [nextSlot].
  /// Utilisé le vendredi pour afficher "Jumu'ah" à la place de "Dhuhr"/"Asr".
  final String? nextSlotLabel;

  /// Convertit un PrayerSlot en libellé français court pour le chip
  /// "Asr dans 1 h 20 min". Sépraré de PrayerNames.french pour permettre
  /// la traduction "sunrise" → "Shurûq" sans toucher au reste.
  String _slotLabel(PrayerSlot slot) {
    switch (slot) {
      case PrayerSlot.fajr:
        return 'Fajr';
      case PrayerSlot.sunrise:
        return 'Shurûq';
      case PrayerSlot.dhuhr:
        return 'Dhuhr';
      case PrayerSlot.asr:
        return 'Asr';
      case PrayerSlot.maghrib:
        return 'Maghrib';
      case PrayerSlot.isha:
        return 'Isha';
    }
  }

  /// Met en forme une durée en langage naturel français.
  /// Exemples :
  ///   - 7245 s  → "2 h 00 min"
  ///   - 1234 s  → "20 min 34 s"
  ///   - 42 s    → "42 secondes"
  ///   - 0 s     → "maintenant"
  ///
  /// Plus parlant que "02:00" ou "20:34" pour quelqu'un qui regarde
  /// l'écran de loin dans une mosquée.
  String _formatRemaining(Duration d) {
    if (d.isNegative || d.inSeconds == 0) return 'maintenant';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours >= 1) {
      if (minutes == 0) return '$hours h';
      return '$hours h ${minutes.toString().padLeft(2, '0')} min';
    }
    if (minutes >= 1) {
      if (minutes == 1 && seconds == 0) return '1 minute';
      return '$minutes min ${seconds.toString().padLeft(2, '0')} s';
    }
    return '$seconds secondes';
  }

  @override
  Widget build(BuildContext context) {
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final hijri = HijriCalendar.fromDate(now.add(Duration(days: hijriOffset)));
    final hijriStr =
        '${hijri.hDay} ${HijriHelper.monthNames[hijri.hMonth - 1]} ${hijri.hYear}';

    final s = scale;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$hh:$mm',
              style: TextStyle(
                fontSize: 110 * s,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1,
                letterSpacing: -2,
                shadows: AppTheme.textShadowStrong,
              ),
            ),
            SizedBox(width: 8 * s),
            Text(
              ':$ss',
              style: TextStyle(
                fontSize: 110 * s,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary.withValues(alpha: 0.85),
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1,
                letterSpacing: -2,
                shadows: AppTheme.textShadowStrong,
              ),
            ),
          ],
        ),
        if (nextSlot != null) ...[
          SizedBox(height: 12 * s),
          // Bloc "Prochaine prière" sur deux lignes : libellé discret en
          // haut, slot + countdown gros en dessous. Plus parlant que la
          // simple chip précédente.
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 18 * s, vertical: 7 * s),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PROCHAINE PRIÈRE',
                  style: TextStyle(
                    fontSize: 10 * s,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 2,
                    shadows: AppTheme.textShadow,
                  ),
                ),
                SizedBox(height: 2 * s),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.nightlight_round,
                        color: AppTheme.accent, size: 16 * s),
                    SizedBox(width: 8 * s),
                    Text(
                      nextSlotLabel ?? _slotLabel(nextSlot!),
                      style: TextStyle(
                        fontSize: 18 * s,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1,
                        shadows: AppTheme.textShadow,
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Container(
                      width: 1.5,
                      height: 18 * s,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: 10 * s),
                    Text(
                      'dans ${_formatRemaining(untilNext)}',
                      style: TextStyle(
                        fontSize: 16 * s,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.highlight,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        height: 1,
                        shadows: AppTheme.textShadow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 10 * s),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: 16 * s, vertical: 7 * s),
          decoration: BoxDecoration(
            color: const Color(0xFF1F5C3D).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(22 * s),
            border: Border.all(
              color: const Color(0xFF66BB6A).withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.brightness_3,
                  color: const Color(0xFF8FE0A0), size: 18 * s),
              SizedBox(width: 8 * s),
              Text(
                hijriStr,
                style: TextStyle(
                  fontSize: 22 * s,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                  shadows: AppTheme.textShadow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// IslamicEventBanner : pilule islamique affichée sur le HomeScreen.
//
// Apparaît automatiquement quand un événement du calendrier lunaire est actif
// ce jour-là (Ramadan, Eid, Arafa, jeûne sunnah, etc.). Taille compacte
// pour ne pas voler la vedette aux horaires de prière.
// =============================================================================

import 'package:flutter/material.dart';

import '../core/islamic_events.dart';
import '../core/theme.dart';

class IslamicEventBanner extends StatelessWidget {
  const IslamicEventBanner({
    super.key,
    required this.event,
    this.scale = 1.0,
  });

  final IslamicEvent event;
  final double scale;

  static Color _bgColor(IslamicEventType t) => switch (t) {
        IslamicEventType.eid => const Color(0xFFD4A017),
        IslamicEventType.arafat => const Color(0xFFC8860A),
        IslamicEventType.laylatulQadr => const Color(0xFF6A0D91),
        IslamicEventType.ramadan => const Color(0xFF1B6B3A),
        IslamicEventType.ashura ||
        IslamicEventType.tasuaa =>
          const Color(0xFF1A3A6B),
        IslamicEventType.dhulHijja => const Color(0xFF2D6B5A),
        IslamicEventType.ayyamBeedh => const Color(0xFF1F4A7A),
        IslamicEventType.mondayFast ||
        IslamicEventType.thursdayFast =>
          const Color(0xFF2A2A3A),
      };

  static Color _borderColor(IslamicEventType t) => switch (t) {
        IslamicEventType.eid ||
        IslamicEventType.arafat =>
          const Color(0xFFFFD700),
        IslamicEventType.laylatulQadr => const Color(0xFFB066D4),
        IslamicEventType.ramadan ||
        IslamicEventType.dhulHijja =>
          const Color(0xFF4CAF50),
        IslamicEventType.ashura ||
        IslamicEventType.tasuaa =>
          const Color(0xFF64B5F6),
        IslamicEventType.ayyamBeedh => const Color(0xFF90CAF9),
        IslamicEventType.mondayFast ||
        IslamicEventType.thursdayFast =>
          const Color(0xFF888899),
      };

  static IconData _icon(IslamicEventType t) => switch (t) {
        IslamicEventType.eid => Icons.celebration,
        IslamicEventType.arafat => Icons.landscape,
        IslamicEventType.laylatulQadr => Icons.nights_stay,
        IslamicEventType.ramadan => Icons.brightness_3,
        IslamicEventType.ashura ||
        IslamicEventType.tasuaa =>
          Icons.water_drop,
        IslamicEventType.dhulHijja => Icons.mosque,
        IslamicEventType.ayyamBeedh => Icons.wb_sunny,
        IslamicEventType.mondayFast ||
        IslamicEventType.thursdayFast =>
          Icons.no_food,
      };

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor(event.type);
    final border = _borderColor(event.type);
    final icon = _icon(event.type);
    final s = scale;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: border.withValues(alpha: 0.75), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: border, size: 16 * s),
          SizedBox(width: 7 * s),
          Text(
            event.nameAr,
            style: TextStyle(
              fontSize: 15 * s,
              fontWeight: FontWeight.bold,
              color: border,
              height: 1,
            ),
          ),
          SizedBox(width: 8 * s),
          Container(
            width: 1,
            height: 14 * s,
            color: border.withValues(alpha: 0.45),
          ),
          SizedBox(width: 8 * s),
          Text(
            event.nameFr,
            style: TextStyle(
              fontSize: 12 * s,
              color: AppTheme.textPrimary.withValues(alpha: 0.88),
              height: 1,
            ),
          ),
          if (event.isFasting) ...[
            SizedBox(width: 8 * s),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 6 * s, vertical: 2 * s),
              decoration: BoxDecoration(
                color: border.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8 * s),
              ),
              child: Text(
                'Jeûne',
                style: TextStyle(
                  fontSize: 9 * s,
                  color: border,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          if (event.isHoliday) ...[
            SizedBox(width: 8 * s),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 6 * s, vertical: 2 * s),
              decoration: BoxDecoration(
                color: border.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8 * s),
              ),
              child: Text(
                'Fête',
                style: TextStyle(
                  fontSize: 9 * s,
                  color: border,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

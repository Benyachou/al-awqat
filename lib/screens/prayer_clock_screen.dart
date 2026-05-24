// =============================================================================
// PrayerClockScreen : cadran circulaire 24 h (00h en haut → sens horaire).
//
// Affiche, sur une seule horloge :
//   - les 6 horaires du jour (Fajr, Shurûq, Dhuhr, Asr, Maghrib, Isha) comme
//     points sur le cercle ;
//   - les ARCS ROUGES = temps où la prière est interdite (lever, zénith,
//     coucher du soleil) ;
//   - les ARCS ORANGE = temps déconseillés (après le Fajr, après l'Asr) ;
//   - une AIGUILLE blanche = l'heure courante (avance chaque seconde) ;
//   - au centre, un badge « Prière permise / Déconseillé / Temps interdit ».
//
// Les arcs sont calculés sur les horaires ASTRONOMIQUES bruts (sans la
// substitution Jumu'ah) pour que le zénith reste calé sur le vrai midi
// solaire, tandis que les POINTS de prière reprennent les horaires affichés
// par l'app (Mawaqit / mosquée / Jumu'ah) — cf. PrayerProvider.today.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/forbidden_times.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';
import '../providers/prayer_provider.dart';

/// Rouge des interdictions strictes.
const _kForbidden = Color(0xFFE53935);

/// Orange des temps déconseillés (proche de AppTheme.highlight).
const _kDiscouraged = Color(0xFFFFA726);

/// Vert « tout va bien » (même teinte que la pilule hijrie).
const _kAllowed = Color(0xFF66BB6A);

class PrayerClockScreen extends StatelessWidget {
  const PrayerClockScreen({super.key});

  /// Libellé court pour les points du cadran.
  static String _shortLabel(PrayerSlot slot, bool isJumuah) {
    switch (slot) {
      case PrayerSlot.fajr:
        return 'Fajr';
      case PrayerSlot.sunrise:
        return 'Shurûq';
      case PrayerSlot.dhuhr:
        return isJumuah ? 'Jumu\'ah' : 'Dhuhr';
      case PrayerSlot.asr:
        return 'Asr';
      case PrayerSlot.maghrib:
        return 'Maghrib';
      case PrayerSlot.isha:
        return 'Isha';
    }
  }

  static String _formatRemaining(Duration d) {
    if (d.isNegative || d.inSeconds == 0) return 'maintenant';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h >= 1) return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
    if (m >= 1) return '$m min';
    return '${d.inSeconds} s';
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final today = prayer.today;

    if (today == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = prayer.now;
    final settings = prayer.settings;

    // Arcs interdits/déconseillés : sur les horaires ASTRONOMIQUES bruts.
    final astro = PrayerEngine().scheduleFor(
      settings,
      DateTime(now.year, now.month, now.day),
      applyJumuah: false,
    );
    final windows = ForbiddenTimes.forSchedule(astro);
    final ban = ForbiddenTimes.banAt(windows, now);
    final next = prayer.nextPrayer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horloge 24 h — temps de prière'),
        backgroundColor: AppTheme.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.infinite,
                          painter: _ClockDialPainter(
                            schedule: today,
                            windows: windows,
                            now: now,
                          ),
                        ),
                        _CenterBadge(ban: ban),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Compteur « prochaine prière »
            if (next != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_shortLabel(next.slot, today.isJumuah)} dans '
                  '${_formatRemaining(next.time.difference(now))}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const _Legend(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Badge central : état actuel (permise / déconseillée / interdite).
class _CenterBadge extends StatelessWidget {
  const _CenterBadge({required this.ban});
  final PrayerBan? ban;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = switch (ban) {
      PrayerBan.forbidden => (_kForbidden, Icons.block, 'Temps interdit'),
      PrayerBan.discouraged => (
          _kDiscouraged,
          Icons.warning_amber_rounded,
          'Déconseillé'
        ),
      null => (_kAllowed, Icons.check_circle, 'Prière permise'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Légende sous le cadran.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: const [
        _LegendItem(color: _kForbidden, label: 'Interdit'),
        _LegendItem(color: _kDiscouraged, label: 'Déconseillé'),
        _LegendItem(color: Colors.white, label: 'Maintenant', isLine: true),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.isLine = false,
  });
  final Color color;
  final String label;
  final bool isLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLine ? 18 : 14,
          height: isLine ? 3 : 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isLine ? 2 : 7),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Le peintre du cadran
// =============================================================================

class _ClockDialPainter extends CustomPainter {
  _ClockDialPainter({
    required this.schedule,
    required this.windows,
    required this.now,
  });

  /// Horaires affichés (points de prière) — peut inclure Jumu'ah.
  final PrayerSchedule schedule;

  /// Créneaux interdits/déconseillés (arcs).
  final List<ForbiddenWindow> windows;

  final DateTime now;

  /// Convertit une heure du jour en angle (00h en haut, sens horaire).
  double _angle(DateTime t) {
    final h = t.hour + t.minute / 60.0 + t.second / 3600.0;
    return -math.pi / 2 + (h / 24.0) * 2 * math.pi;
  }

  Offset _polar(Offset center, double r, double angle) =>
      center + Offset(math.cos(angle) * r, math.sin(angle) * r);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Rayons des différents anneaux (de l'extérieur vers l'intérieur).
    final rOuter = r - 2;
    final rLabel = r - 22; // chiffres des heures
    final rBand = r - 48; // anneau coloré (interdits/déconseillés)
    final bandWidth = 16.0;
    final rDot = rBand; // points de prière, posés sur l'anneau
    final rDotLabel = r - 78; // libellés des prières (vers l'intérieur)
    final rHandEnd = rBand - bandWidth / 2 - 6;
    final rHandStart = 46.0; // l'aiguille démarre hors du badge central

    // --- Disque de fond ---
    canvas.drawCircle(
      center,
      rOuter,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // --- Secteur « jour » (lever → coucher) en teinte chaude discrète ---
    final dayStart = _angle(schedule.sunrise);
    final daySweep = _angle(schedule.maghrib) - dayStart;
    final dayPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: rOuter),
        dayStart,
        daySweep,
        false,
      )
      ..close();
    canvas.drawPath(
      dayPath,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.07),
    );

    // --- Cercle extérieur ---
    canvas.drawCircle(
      center,
      rOuter,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.30),
    );

    // --- Piste de l'anneau (track gris, visible où il n'y a pas de ban) ---
    canvas.drawCircle(
      center,
      rBand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bandWidth
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    // --- Graduations horaires (24 traits, libellés tous les 3 h) ---
    for (var h = 0; h < 24; h++) {
      final a = -math.pi / 2 + (h / 24.0) * 2 * math.pi;
      final major = h % 3 == 0;
      final p1 = _polar(center, rOuter - 3, a);
      final p2 = _polar(center, rOuter - (major ? 16 : 8), a);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = major ? 2 : 1
          ..color = Colors.white.withValues(alpha: major ? 0.55 : 0.28),
      );
      if (major) {
        _text(
          canvas,
          '${h}h',
          _polar(center, rLabel, a),
          color: AppTheme.textSecondary,
          fontSize: 12,
          weight: FontWeight.w600,
        );
      }
    }

    // --- Arcs interdits / déconseillés ---
    // (la liste a les "discouraged" avant les "forbidden" → le rouge se pose
    //  au-dessus de l'orange là où ils se chevauchent.)
    for (final w in windows) {
      final start = _angle(w.start);
      final sweep = _angle(w.end) - start;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: rBand),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bandWidth
          ..strokeCap = StrokeCap.butt
          ..color = (w.ban == PrayerBan.forbidden ? _kForbidden : _kDiscouraged)
              .withValues(alpha: 0.85),
      );
    }

    // --- Points de prière + libellés ---
    for (final entry in schedule.all.entries) {
      final a = _angle(entry.value);
      final dotPos = _polar(center, rDot, a);
      // Point blanc cerclé de noir pour rester lisible sur les arcs colorés.
      canvas.drawCircle(dotPos, 6, Paint()..color = Colors.black);
      canvas.drawCircle(dotPos, 4.5, Paint()..color = Colors.white);

      final label = PrayerClockScreen._shortLabel(entry.key, schedule.isJumuah);
      final hhmm =
          '${entry.value.hour.toString().padLeft(2, '0')}:${entry.value.minute.toString().padLeft(2, '0')}';
      _text(
        canvas,
        '$label\n$hhmm',
        _polar(center, rDotLabel, a),
        color: AppTheme.textPrimary,
        fontSize: 11,
        weight: FontWeight.w600,
        align: TextAlign.center,
      );
    }

    // --- Aiguille « maintenant » ---
    final aNow = _angle(now);
    final handStart = _polar(center, rHandStart, aNow);
    final handEnd = _polar(center, rHandEnd, aNow);
    // Halo
    canvas.drawLine(
      handStart,
      handEnd,
      Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    canvas.drawLine(
      handStart,
      handEnd,
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );
    canvas.drawCircle(handEnd, 5, Paint()..color = Colors.white);
  }

  /// Dessine un texte (éventuellement multi-lignes) centré sur [pos].
  void _text(
    Canvas canvas,
    String text,
    Offset pos, {
    required Color color,
    required double fontSize,
    FontWeight weight = FontWeight.normal,
    TextAlign align = TextAlign.center,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1.15,
          shadows: AppTheme.textShadow,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ClockDialPainter old) =>
      old.now != now ||
      old.schedule != schedule ||
      old.windows.length != windows.length;
}

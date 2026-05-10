import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/prayer_engine.dart';
import '../core/prayer_period.dart';
import '../core/theme.dart';

class PrayerDial extends StatelessWidget {
  const PrayerDial({
    super.key,
    required this.today,
    required this.tomorrow,
    required this.now,
    required this.periods,
  });

  final PrayerSchedule today;
  final PrayerSchedule tomorrow;
  final DateTime now;
  final List<PrayerPeriod> periods;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _DialPainter(
                today: today,
                tomorrow: tomorrow,
                now: now,
                periods: periods,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _DialLegend(),
        ],
      ),
    );
  }
}

class _DialLegend extends StatelessWidget {
  const _DialLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 4,
      children: const [
        _LegendDot(color: Color(0xFF66BB6A), label: 'Surérogatoire'),
        _LegendDot(color: Color(0xFFEF5350), label: 'Interdit'),
        _LegendDot(color: Color(0xFF66B2FF), label: 'Obligatoire'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.today,
    required this.tomorrow,
    required this.now,
    required this.periods,
  });

  final PrayerSchedule today;
  final PrayerSchedule tomorrow;
  final DateTime now;
  final List<PrayerPeriod> periods;

  /// 24-hour dial laid out clockwise: 00h at the bottom, 06h on the left,
  /// 12h at the top, 18h on the right.
  double _timeToAngle(DateTime time) {
    final dayStart = DateTime(time.year, time.month, time.day);
    final hours = time.difference(dayStart).inSeconds / 3600.0;
    return (hours - 18) * math.pi / 12;
  }

  Offset _pointOnCircle(Offset center, double radius, double angle) {
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  double _hoursOf(DateTime t) {
    final dayStart = DateTime(t.year, t.month, t.day);
    return t.difference(dayStart).inSeconds / 3600.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide / 2 - 4;
    final dialR = outerR - 8;
    final tickR = dialR - 8;
    final markerR = tickR - 28;
    final periodRingOuter = markerR - 14;
    final periodRingInner = periodRingOuter - 14;

    _paintDayNightBackground(canvas, center, dialR);
    _paintPeriodRing(canvas, center, periodRingOuter, periodRingInner);
    _paintDialRing(canvas, center, dialR);
    _paintHourTicks(canvas, center, tickR);
    _paintPrayerMarkers(canvas, center, markerR);
    _paintCurrentTimeHand(canvas, center, markerR);
    _paintCenterClock(canvas, center, periodRingInner * 0.78);
  }

  Color? _periodColor(PeriodStatus s) {
    switch (s) {
      case PeriodStatus.allowed:
        return null;
      case PeriodStatus.recommended:
        return const Color(0xFF66BB6A);
      case PeriodStatus.prohibited:
        return const Color(0xFFEF5350);
    }
  }

  void _paintPeriodRing(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
  ) {
    final rect = Rect.fromCircle(
      center: center,
      radius: (outerR + innerR) / 2,
    );
    final strokeW = outerR - innerR;

    canvas.drawCircle(
      center,
      (outerR + innerR) / 2,
      Paint()
        ..color = AppTheme.background.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    for (final p in periods) {
      final color = _periodColor(p.status);
      if (color == null) continue;
      final start = _timeToAngle(p.start);
      final end = _timeToAngle(p.end);
      var sweep = end - start;
      if (sweep < 0) sweep += 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  void _paintDayNightBackground(Canvas canvas, Offset center, double r) {
    final sunriseH = _hoursOf(today.sunrise);
    final sunsetH = _hoursOf(today.maghrib);

    final stops = <double>[];
    final colors = <Color>[];

    for (var i = 0; i <= 96; i++) {
      final h = i / 96 * 24;
      stops.add(i / 96);
      colors.add(_skyColorAt(h, sunriseH, sunsetH));
    }

    final shader = SweepGradient(
      startAngle: -math.pi / 2 - math.pi / 12 * 12,
      endAngle: -math.pi / 2 + math.pi / 12 * 12,
      transform: const GradientRotation(math.pi / 2),
      stops: stops,
      colors: colors,
    ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, Paint()..shader = shader);
  }

  Color _skyColorAt(double hour, double sunriseH, double sunsetH) {
    const night = Color(0xFF071324);
    const dawn = Color(0xFF2A3F66);
    const day = Color(0xFF1B4F8A);
    const sunset = Color(0xFF7A3B2E);

    if (hour < sunriseH - 1) return night;
    if (hour < sunriseH + 0.5) {
      final t = (hour - (sunriseH - 1)) / 1.5;
      return Color.lerp(night, dawn, t)!;
    }
    if (hour < sunriseH + 2) {
      final t = (hour - sunriseH - 0.5) / 1.5;
      return Color.lerp(dawn, day, t)!;
    }
    if (hour < sunsetH - 1) return day;
    if (hour < sunsetH) {
      final t = (hour - (sunsetH - 1));
      return Color.lerp(day, sunset, t)!;
    }
    if (hour < sunsetH + 1) {
      final t = (hour - sunsetH);
      return Color.lerp(sunset, night, t)!;
    }
    return night;
  }

  void _paintDialRing(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = AppTheme.textSecondary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintHourTicks(Canvas canvas, Offset center, double r) {
    final tickPaint = Paint()..color = AppTheme.textSecondary;
    for (var h = 0; h < 24; h++) {
      final isMajor = h % 3 == 0;
      final tickLen = isMajor ? 10.0 : 4.0;
      final angle = (h - 18) * math.pi / 12;
      final outer = _pointOnCircle(center, r, angle);
      final inner = _pointOnCircle(center, r - tickLen, angle);
      tickPaint.strokeWidth = isMajor ? 2.0 : 1.0;
      canvas.drawLine(inner, outer, tickPaint);

      if (isMajor) {
        final labelPos = _pointOnCircle(center, r - tickLen - 16, angle);
        final tp = TextPainter(
          text: TextSpan(
            text: h.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
        );
      }
    }
  }

  void _paintPrayerMarkers(Canvas canvas, Offset center, double r) {
    final markers = <(String, DateTime, Color)>[
      ('Fajr', today.fajr, const Color(0xFF7E9CD3)),
      ('Chorouk', today.sunrise, const Color(0xFFFFD54F)),
      ('Dhuhr', today.dhuhr, const Color(0xFFFFA726)),
      ('Asr', today.asr, const Color(0xFFFF7043)),
      ('Maghrib', today.maghrib, const Color(0xFFEF5350)),
      ('Isha', today.isha, const Color(0xFF7E57C2)),
    ];

    for (final (label, time, color) in markers) {
      final angle = _timeToAngle(time);
      final dotPos = _pointOnCircle(center, r, angle);
      final labelPos = _pointOnCircle(center, r - 28, angle);

      // Outer ring stroke for readability against background.
      canvas.drawCircle(
        dotPos,
        10,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawCircle(dotPos, 9, Paint()..color = color);
      canvas.drawCircle(
        dotPos,
        9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label\n',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
            TextSpan(
              text: timeStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );
    }
  }

  void _paintCurrentTimeHand(Canvas canvas, Offset center, double r) {
    final angle = _timeToAngle(now);
    final tip = _pointOnCircle(center, r - 10, angle);
    final indicator = _pointOnCircle(center, r - 12, angle);

    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppTheme.highlight
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      indicator,
      14,
      Paint()
        ..color = AppTheme.highlight.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(indicator, 8, Paint()..color = AppTheme.highlight);
    canvas.drawCircle(
      indicator,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintCenterClock(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center,
      r,
      Paint()..color = AppTheme.background.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = AppTheme.textSecondary.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final tp = TextPainter(
      text: TextSpan(
        text: timeStr,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: r * 0.55,
          fontWeight: FontWeight.w300,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.now != now || old.today.fajr != today.fajr;
}

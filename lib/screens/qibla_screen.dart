import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/prayer_provider.dart';
import '../services/qibla_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<CompassEvent>? _sub;
  double? _heading;
  bool _compassUnavailable = false;

  @override
  void initState() {
    super.initState();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _compassUnavailable = true;
      return;
    }
    _sub = stream.listen(
      (event) {
        if (!mounted) return;
        setState(() => _heading = event.heading);
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _compassUnavailable = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final settings = prayer.settings;
    final qiblaBearing =
        QiblaService.bearingFrom(settings.latitude, settings.longitude);
    final distanceKm =
        QiblaService.distanceKmFrom(settings.latitude, settings.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla'),
        backgroundColor: AppTheme.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _QiblaCompass(
                      qiblaBearing: qiblaBearing,
                      heading: _heading,
                      compassUnavailable: _compassUnavailable,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Direction de la Qibla',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Info(
                      label: 'Azimut depuis le Nord',
                      value: '${qiblaBearing.toStringAsFixed(1)}°',
                    ),
                    _Info(
                      label: 'Distance vers la Kaaba',
                      value: '${distanceKm.toStringAsFixed(0)} km',
                    ),
                    _Info(label: 'Lieu', value: settings.cityName),
                    const SizedBox(height: 16),
                    if (_compassUnavailable)
                      const Text(
                        'Boussole indisponible sur cet appareil. '
                        'Utilise l\'azimut indiqué ci-dessus avec une boussole physique.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      )
                    else if (_heading == null)
                      const Text(
                        'En attente du capteur magnétique...',
                        style: TextStyle(color: AppTheme.textSecondary),
                      )
                    else
                      const Text(
                        'Aligne le triangle vert avec le marqueur de la Qibla.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaCompass extends StatelessWidget {
  const _QiblaCompass({
    required this.qiblaBearing,
    required this.heading,
    required this.compassUnavailable,
  });

  final double qiblaBearing;
  final double? heading;
  final bool compassUnavailable;

  @override
  Widget build(BuildContext context) {
    final h = heading ?? 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -h * math.pi / 180,
          child: CustomPaint(
            painter: _CompassPainter(qiblaBearing: qiblaBearing),
            child: const SizedBox.expand(),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.qiblaBearing});
  final double qiblaBearing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 4;

    canvas.drawCircle(
      center,
      r,
      Paint()..color = AppTheme.surface,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = AppTheme.textSecondary.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Cardinal points.
    const cardinals = ['N', 'E', 'S', 'O'];
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final pos = Offset(
        center.dx + (r - 22) * math.cos(angle),
        center.dy + (r - 22) * math.sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: cardinals[i],
          style: TextStyle(
            color: i == 0 ? AppTheme.highlight : AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
      );
    }

    // Tick marks every 30 degrees.
    final tickPaint = Paint()..color = AppTheme.textSecondary;
    for (var d = 0; d < 360; d += 10) {
      final isMajor = d % 30 == 0;
      final angle = (d - 90) * math.pi / 180;
      final outer = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      final tickLen = isMajor ? 12.0 : 6.0;
      final inner = Offset(
        center.dx + (r - tickLen) * math.cos(angle),
        center.dy + (r - tickLen) * math.sin(angle),
      );
      tickPaint.strokeWidth = isMajor ? 2.0 : 1.0;
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Qibla marker (green triangle pointing inward).
    final qAngle = (qiblaBearing - 90) * math.pi / 180;
    final qOuter = Offset(
      center.dx + (r - 4) * math.cos(qAngle),
      center.dy + (r - 4) * math.sin(qAngle),
    );
    final qLeft = Offset(
      center.dx + (r - 30) * math.cos(qAngle - 0.12),
      center.dy + (r - 30) * math.sin(qAngle - 0.12),
    );
    final qRight = Offset(
      center.dx + (r - 30) * math.cos(qAngle + 0.12),
      center.dy + (r - 30) * math.sin(qAngle + 0.12),
    );
    final path = Path()
      ..moveTo(qOuter.dx, qOuter.dy)
      ..lineTo(qLeft.dx, qLeft.dy)
      ..lineTo(qRight.dx, qRight.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF66BB6A));

    // Kaaba glyph at center of qibla direction.
    final glyphPos = Offset(
      center.dx + (r * 0.55) * math.cos(qAngle),
      center.dy + (r * 0.55) * math.sin(qAngle),
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: '🕋',
        style: TextStyle(fontSize: 28),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(glyphPos.dx - tp.width / 2, glyphPos.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.qiblaBearing != qiblaBearing;
}

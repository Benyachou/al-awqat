import 'package:flutter/material.dart';

import '../core/prayer_period.dart';
import '../core/theme.dart';

class PeriodIndicator extends StatelessWidget {
  const PeriodIndicator({
    super.key,
    required this.period,
    required this.now,
  });

  final PrayerPeriod period;
  final DateTime now;

  Color _statusColor() {
    switch (period.status) {
      case PeriodStatus.allowed:
        return AppTheme.accent;
      case PeriodStatus.recommended:
        return const Color(0xFF66BB6A);
      case PeriodStatus.prohibited:
        return const Color(0xFFEF5350);
    }
  }

  IconData _statusIcon() {
    switch (period.status) {
      case PeriodStatus.allowed:
        return Icons.check_circle_outline;
      case PeriodStatus.recommended:
        return Icons.star_outline;
      case PeriodStatus.prohibited:
        return Icons.block;
    }
  }

  String _statusLabel() {
    switch (period.status) {
      case PeriodStatus.allowed:
        return 'Prière permise';
      case PeriodStatus.recommended:
        return 'Prière recommandée';
      case PeriodStatus.prohibited:
        return 'Prière interdite';
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = period.remainingFrom(now);
    final h = remaining.inHours;
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final timeLeft = h > 0 ? '${h}h $m\'$s"' : '$m:$s';
    final color = _statusColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(), color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _statusLabel(),
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            period.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Reste : $timeLeft',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

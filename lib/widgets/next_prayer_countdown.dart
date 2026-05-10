import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';

class NextPrayerCountdown extends StatelessWidget {
  const NextPrayerCountdown({
    super.key,
    required this.slot,
    required this.untilNext,
  });

  final PrayerSlot slot;
  final Duration untilNext;

  @override
  Widget build(BuildContext context) {
    final hours = untilNext.inHours.toString().padLeft(2, '0');
    final minutes = (untilNext.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (untilNext.inSeconds % 60).toString().padLeft(2, '0');
    final french = PrayerNames.french[slot.name]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.25),
            AppTheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent, width: 2),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prochaine prière',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                french,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$hours:$minutes:$seconds',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: AppTheme.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

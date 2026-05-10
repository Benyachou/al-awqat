import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';

class IqamaCountdown extends StatelessWidget {
  const IqamaCountdown({
    super.key,
    required this.slot,
    required this.remaining,
  });

  final PrayerSlot slot;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final french = PrayerNames.french[slot.name]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.highlight,
            AppTheme.highlight.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.highlight.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mosque, size: 36, color: Colors.black87),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Iqama $french',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'dans $minutes:$seconds',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFeatures: [FontFeature.tabularFigures()],
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';

class CurrentClock extends StatelessWidget {
  const CurrentClock({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(now);
    final date = DateFormat('EEEE d MMMM y', 'fr_FR').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w300,
            color: AppTheme.textPrimary,
            height: 1,
            letterSpacing: 1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/theme.dart';

class HijriDateWidget extends StatelessWidget {
  const HijriDateWidget({super.key, required this.now, this.offsetDays = 0});

  final DateTime now;
  final int offsetDays;

  @override
  Widget build(BuildContext context) {
    final adjusted = now.add(Duration(days: offsetDays));
    final hijri = HijriCalendar.fromDate(adjusted);
    final formatted = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formatted,
        style: const TextStyle(
          fontSize: 18,
          color: AppTheme.accent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

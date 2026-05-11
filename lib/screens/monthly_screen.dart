import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/prayer_engine.dart';
import '../core/theme.dart';
import '../providers/prayer_provider.dart';

class MonthlyScreen extends StatefulWidget {
  const MonthlyScreen({super.key});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> {
  late DateTime _monthStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthStart = DateTime(now.year, now.month, 1);
  }

  void _shift(int months) {
    setState(() {
      _monthStart = DateTime(_monthStart.year, _monthStart.month + months, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final daysInMonth =
        DateTime(_monthStart.year, _monthStart.month + 1, 0).day;
    final today = DateTime.now();
    final monthFmt = DateFormat('MMMM y', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier mensuel'),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shift(-1),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                monthFmt.format(_monthStart),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shift(1),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            const Divider(height: 1, color: AppTheme.divider),
            Expanded(
              child: ListView.builder(
                itemCount: daysInMonth,
                itemBuilder: (context, i) {
                  final day = DateTime(_monthStart.year, _monthStart.month, i + 1);
                  final schedule = prayer.scheduleForDay(day);
                  final isToday = _isSameDay(day, today);
                  final isFriday = day.weekday == DateTime.friday;
                  return _Row(
                    day: day,
                    schedule: schedule,
                    isToday: isToday,
                    isFriday: isFriday,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      color: AppTheme.accent,
      fontSize: 13,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        children: const [
          SizedBox(width: 90, child: Text('Date', style: style)),
          Expanded(child: Center(child: Text('Fajr', style: style))),
          Expanded(child: Center(child: Text('Lever', style: style))),
          Expanded(child: Center(child: Text('Dhuhr', style: style))),
          Expanded(child: Center(child: Text('Asr', style: style))),
          Expanded(child: Center(child: Text('Maghrib', style: style))),
          Expanded(child: Center(child: Text('Isha', style: style))),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.day,
    required this.schedule,
    required this.isToday,
    required this.isFriday,
  });

  final DateTime day;
  final PrayerSchedule schedule;
  final bool isToday;
  final bool isFriday;

  @override
  Widget build(BuildContext context) {
    final dayFmt = DateFormat('EEE d', 'fr_FR');
    final hijri = HijriCalendar.fromDate(day);
    final bg = isToday
        ? AppTheme.highlight.withValues(alpha: 0.15)
        : isFriday
            ? AppTheme.accent.withValues(alpha: 0.08)
            : null;
    final color = isToday ? AppTheme.highlight : AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayFmt.format(day),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                Text(
                  '${hijri.hDay}/${hijri.hMonth}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _Cell(time: schedule.fajr, color: color),
          _Cell(time: schedule.sunrise, color: color),
          _Cell(time: schedule.dhuhr, color: color, jumuah: schedule.isJumuah),
          _Cell(time: schedule.asr, color: color),
          _Cell(time: schedule.maghrib, color: color),
          _Cell(time: schedule.isha, color: color),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.time, required this.color, this.jumuah = false});

  final DateTime time;
  final Color color;
  final bool jumuah;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fmt.format(time),
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (jumuah)
              const Text(
                'Jumu\'ah',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

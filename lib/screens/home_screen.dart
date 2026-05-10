import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/prayer_provider.dart';
import '../widgets/current_clock.dart';
import '../widgets/hijri_date_widget.dart';
import '../widgets/iqama_countdown.dart';
import '../widgets/next_prayer_countdown.dart';
import '../widgets/period_indicator.dart';
import '../widgets/prayer_dial.dart';
import '../widgets/prayer_row.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, prayer, _) {
        final today = prayer.today;
        final tomorrow = prayer.tomorrow;
        if (today == null || tomorrow == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final next = prayer.nextPrayer;
        final current = prayer.currentPrayer;
        final fresh = prayer.freshlyStartedSlot;
        final iqama = prayer.iqamaCountdown;
        final period = prayer.currentPeriod;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prayer.settings.cityName,
                          style: const TextStyle(
                            fontSize: 22,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      HijriDateWidget(
                        now: prayer.now,
                        offsetDays: prayer.settings.hijriOffset,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: AppTheme.textSecondary,
                          size: 32,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: PrayerDial(
                              today: today,
                              tomorrow: tomorrow,
                              now: prayer.now,
                              periods: prayer.dayPeriods,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CurrentClock(now: prayer.now),
                              const SizedBox(height: 12),
                              if (iqama != null) ...[
                                IqamaCountdown(
                                  slot: iqama.slot,
                                  remaining: iqama.remaining,
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (period != null)
                                PeriodIndicator(
                                  period: period,
                                  now: prayer.now,
                                ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: today.all.entries
                                        .map(
                                          (e) => PrayerRow(
                                            key: ValueKey(e.key),
                                            slot: e.key,
                                            time: e.value,
                                            isCurrent: current == e.key,
                                            isNext: next?.slot == e.key,
                                            isFresh: fresh == e.key,
                                            isJumuah: today.isJumuah,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                              if (next != null) ...[
                                const SizedBox(height: 8),
                                NextPrayerCountdown(
                                  slot: next.slot,
                                  untilNext: prayer.untilNext,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

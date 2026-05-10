import 'package:adhan/adhan.dart';

import '../models/app_settings.dart';

enum PrayerSlot { fajr, sunrise, dhuhr, asr, maghrib, isha }

class PrayerSchedule {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// True when the dhuhr slot is replaced by Jumu'ah (Friday only,
  /// when enabled in settings). Used by widgets to relabel "Dhuhr" → "Jumu'ah".
  final bool isJumuah;

  const PrayerSchedule({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.isJumuah = false,
  });

  Map<PrayerSlot, DateTime> get all => {
        PrayerSlot.fajr: fajr,
        PrayerSlot.sunrise: sunrise,
        PrayerSlot.dhuhr: dhuhr,
        PrayerSlot.asr: asr,
        PrayerSlot.maghrib: maghrib,
        PrayerSlot.isha: isha,
      };
}

class PrayerEngine {
  PrayerSchedule scheduleFor(AppSettings settings, DateTime day) {
    final coords = Coordinates(settings.latitude, settings.longitude);
    final params = settings.preset.build()..madhab = settings.madhab;
    final dateComponents = DateComponents(day.year, day.month, day.day);
    final times = PrayerTimes(coords, dateComponents, params);

    var dhuhr = times.dhuhr;
    var isJumuah = false;
    if (settings.jumuahEnabled && day.weekday == DateTime.friday) {
      dhuhr = DateTime(
        day.year,
        day.month,
        day.day,
        settings.jumuahHour,
        settings.jumuahMinute,
      );
      isJumuah = true;
    }

    return PrayerSchedule(
      fajr: times.fajr,
      sunrise: times.sunrise,
      dhuhr: dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
      isJumuah: isJumuah,
    );
  }

  ({PrayerSlot slot, DateTime time})? nextPrayer(
    PrayerSchedule today,
    PrayerSchedule tomorrow,
    DateTime now,
  ) {
    for (final entry in today.all.entries) {
      if (entry.key == PrayerSlot.sunrise) continue;
      if (entry.value.isAfter(now)) {
        return (slot: entry.key, time: entry.value);
      }
    }
    return (slot: PrayerSlot.fajr, time: tomorrow.fajr);
  }

  PrayerSlot? currentPrayer(PrayerSchedule today, DateTime now) {
    PrayerSlot? current;
    for (final entry in today.all.entries) {
      if (entry.key == PrayerSlot.sunrise) continue;
      if (!entry.value.isAfter(now)) {
        current = entry.key;
      } else {
        break;
      }
    }
    return current;
  }
}

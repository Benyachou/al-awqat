import 'prayer_engine.dart';

enum PeriodStatus { allowed, recommended, prohibited }

class PrayerPeriod {
  final String label;
  final String description;
  final DateTime start;
  final DateTime end;
  final PeriodStatus status;

  const PrayerPeriod({
    required this.label,
    required this.description,
    required this.start,
    required this.end,
    required this.status,
  });

  Duration remainingFrom(DateTime now) => end.difference(now);
}

class PrayerPeriodCalculator {
  static const Duration _karahaSunrise = Duration(minutes: 15);
  static const Duration _karahaZenith = Duration(minutes: 10);
  static const Duration _karahaSunset = Duration(minutes: 15);

  /// Build the list of periods for a given day, in order from Fajr
  /// to next-day Fajr.
  List<PrayerPeriod> buildDay(PrayerSchedule today, PrayerSchedule tomorrow) {
    final fajr = today.fajr;
    final sunrise = today.sunrise;
    final dhuhr = today.dhuhr;
    final asr = today.asr;
    final maghrib = today.maghrib;
    final isha = today.isha;
    final nextFajr = tomorrow.fajr;

    final afterSunriseKaraha = sunrise.add(_karahaSunrise);
    final beforeZenithKaraha = dhuhr.subtract(_karahaZenith);
    final beforeSunsetKaraha = maghrib.subtract(_karahaSunset);

    return [
      PrayerPeriod(
        label: 'Fajr',
        description: 'Prière du Fajr',
        start: fajr,
        end: sunrise,
        status: PeriodStatus.allowed,
      ),
      PrayerPeriod(
        label: 'Karaha (lever du soleil)',
        description: 'Prière interdite pendant le lever du soleil',
        start: sunrise,
        end: afterSunriseKaraha,
        status: PeriodStatus.prohibited,
      ),
      PrayerPeriod(
        label: 'Doha (Duha)',
        description: 'Période recommandée pour la prière surérogatoire',
        start: afterSunriseKaraha,
        end: beforeZenithKaraha,
        status: PeriodStatus.recommended,
      ),
      PrayerPeriod(
        label: 'Karaha (zénith)',
        description: 'Prière interdite quand le soleil est au zénith',
        start: beforeZenithKaraha,
        end: dhuhr,
        status: PeriodStatus.prohibited,
      ),
      PrayerPeriod(
        label: 'Dhuhr',
        description: 'Prière du Dhuhr + nafl autorisées',
        start: dhuhr,
        end: asr,
        status: PeriodStatus.allowed,
      ),
      PrayerPeriod(
        label: 'Asr',
        description: 'Asr seulement, prières surérogatoires interdites',
        start: asr,
        end: beforeSunsetKaraha,
        status: PeriodStatus.allowed,
      ),
      PrayerPeriod(
        label: 'Karaha (coucher du soleil)',
        description: 'Prière interdite pendant le coucher du soleil',
        start: beforeSunsetKaraha,
        end: maghrib,
        status: PeriodStatus.prohibited,
      ),
      PrayerPeriod(
        label: 'Maghrib',
        description: 'Prière du Maghrib + nafl autorisées',
        start: maghrib,
        end: isha,
        status: PeriodStatus.allowed,
      ),
      PrayerPeriod(
        label: 'Isha + Shaf\' / Witr',
        description: 'Isha, Shaf\', Witr et Tahajjud',
        start: isha,
        end: nextFajr,
        status: PeriodStatus.allowed,
      ),
    ];
  }

  PrayerPeriod? currentPeriod(
    PrayerSchedule today,
    PrayerSchedule tomorrow,
    DateTime now,
  ) {
    final periods = buildDay(today, tomorrow);
    for (final p in periods) {
      if (!now.isBefore(p.start) && now.isBefore(p.end)) {
        return p;
      }
    }
    if (!now.isBefore(periods.last.start)) return periods.last;
    return periods.first;
  }
}

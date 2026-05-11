import 'package:adhan/adhan.dart';
import 'package:al_awqat/core/prayer_engine.dart';
import 'package:al_awqat/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrayerEngine.scheduleFor', () {
    final engine = PrayerEngine();

    test('produit 6 horaires ordonnés dans la journée', () {
      final schedule =
          engine.scheduleFor(AppSettings.defaults, DateTime(2026, 6, 15));
      final times = schedule.all.values.toList();
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue,
            reason: 'horaire $i doit être après horaire ${i - 1}');
      }
    });

    test('applique les offsets par prière', () {
      final settings = AppSettings.defaults.copyWith(
        prayerOffsets: {
          PrayerSlot.fajr: -3,
          PrayerSlot.isha: 7,
        },
      );
      final base =
          engine.scheduleFor(AppSettings.defaults, DateTime(2026, 6, 15));
      final adjusted = engine.scheduleFor(settings, DateTime(2026, 6, 15));
      expect(adjusted.fajr.difference(base.fajr).inMinutes, -3);
      expect(adjusted.isha.difference(base.isha).inMinutes, 7);
      expect(adjusted.dhuhr, base.dhuhr); // pas d'offset
    });

    test('remplace Dhuhr par Jumu\'ah le vendredi', () {
      // 2026-01-02 = vendredi
      final schedule = engine.scheduleFor(
        AppSettings.defaults.copyWith(jumuahHour: 13, jumuahMinute: 30),
        DateTime(2026, 1, 2),
      );
      expect(schedule.isJumuah, isTrue);
      expect(schedule.dhuhr.hour, 13);
      expect(schedule.dhuhr.minute, 30);
    });
  });

  group('PrayerEngine.nextPrayer / currentPrayer', () {
    final engine = PrayerEngine();
    final today = PrayerSchedule(
      fajr: DateTime(2026, 5, 10, 4, 30),
      sunrise: DateTime(2026, 5, 10, 6, 15),
      dhuhr: DateTime(2026, 5, 10, 13, 0),
      asr: DateTime(2026, 5, 10, 16, 45),
      maghrib: DateTime(2026, 5, 10, 20, 15),
      isha: DateTime(2026, 5, 10, 21, 45),
    );
    final tomorrow = PrayerSchedule(
      fajr: DateTime(2026, 5, 11, 4, 28),
      sunrise: DateTime(2026, 5, 11, 6, 14),
      dhuhr: DateTime(2026, 5, 11, 13, 0),
      asr: DateTime(2026, 5, 11, 16, 45),
      maghrib: DateTime(2026, 5, 11, 20, 16),
      isha: DateTime(2026, 5, 11, 21, 46),
    );

    test('avant Fajr → next = Fajr', () {
      final next = engine.nextPrayer(today, tomorrow, DateTime(2026, 5, 10, 3, 0));
      expect(next?.slot, PrayerSlot.fajr);
    });

    test('entre Dhuhr et Asr → next = Asr, current = Dhuhr', () {
      final t = DateTime(2026, 5, 10, 14, 0);
      expect(engine.nextPrayer(today, tomorrow, t)?.slot, PrayerSlot.asr);
      expect(engine.currentPrayer(today, t), PrayerSlot.dhuhr);
    });

    test('après Isha → next = Fajr du lendemain', () {
      final t = DateTime(2026, 5, 10, 23, 0);
      final next = engine.nextPrayer(today, tomorrow, t);
      expect(next?.slot, PrayerSlot.fajr);
      expect(next?.time, tomorrow.fajr);
    });

    test('sunrise est ignoré (pas une prière obligatoire)', () {
      // Entre sunrise et dhuhr : current doit rester Fajr.
      final t = DateTime(2026, 5, 10, 9, 0);
      expect(engine.currentPrayer(today, t), PrayerSlot.fajr);
      expect(engine.nextPrayer(today, tomorrow, t)?.slot, PrayerSlot.dhuhr);
    });
  });

  test('AppSettings.copyWith permet de vider updateRepoUrl', () {
    final s = AppSettings.defaults.copyWith(updateRepoUrl: 'foo/bar');
    expect(s.updateRepoUrl, 'foo/bar');
    final cleared = s.copyWith(clearUpdateRepoUrl: true);
    expect(cleared.updateRepoUrl, isNull);
  });

  test('Madhab Hanafi décale Asr', () {
    final engine = PrayerEngine();
    final shafi = engine.scheduleFor(
        AppSettings.defaults.copyWith(madhab: Madhab.shafi),
        DateTime(2026, 6, 15));
    final hanafi = engine.scheduleFor(
        AppSettings.defaults.copyWith(madhab: Madhab.hanafi),
        DateTime(2026, 6, 15));
    expect(hanafi.asr.isAfter(shafi.asr), isTrue);
  });
}

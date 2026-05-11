// =============================================================================
// Moteur de calcul des horaires de prière.
//
// Tout repose sur le package `adhan` (Batoul Apps), une implémentation
// éprouvée de Suehail Shergill basée sur les algorithmes astronomiques
// classiques (Muslim World League, Umm al-Qura, ISNA, etc.).
//
// On ne fait jamais de calcul nous-mêmes : on configure les coordonnées,
// la méthode, le madhab, puis on lit les heures renvoyées par PrayerTimes.
// Notre seule logique custom :
//   - applyOffset : décale chaque prière de N minutes (réglage mosquée locale)
//   - Jumu'ah le vendredi : remplace l'heure calculée du Dhuhr par une heure
//     fixe choisie par l'utilisateur (les mosquées font ça pour l'organisation).
// =============================================================================

import 'package:adhan/adhan.dart';

import '../models/app_settings.dart';

/// Identifiant typé des 6 moments de la journée. `sunrise` n'est pas une
/// prière obligatoire mais on l'expose quand même pour l'afficher dans le
/// dial et marquer la fin du créneau Fajr.
enum PrayerSlot { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Snapshot immuable des 6 horaires d'une journée donnée.
///
/// On en garde deux en mémoire dans le provider : `today` et `tomorrow`,
/// pour pouvoir afficher "Fajr de demain" quand on dépasse l'Isha sans
/// recalculer pendant la nuit.
class PrayerSchedule {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// Vrai quand le créneau Dhuhr a été remplacé par Jumu'ah (vendredi
  /// uniquement, si l'option est activée). Les widgets s'en servent pour
  /// relabeler "Dhuhr" → "Jumu'ah" / الجمعة.
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

  /// Vue Map indexée par PrayerSlot, pratique pour itérer dans l'ordre
  /// fajr → isha. L'ordre d'insertion d'une Map littérale Dart est
  /// préservé, donc on peut compter dessus.
  Map<PrayerSlot, DateTime> get all => {
        PrayerSlot.fajr: fajr,
        PrayerSlot.sunrise: sunrise,
        PrayerSlot.dhuhr: dhuhr,
        PrayerSlot.asr: asr,
        PrayerSlot.maghrib: maghrib,
        PrayerSlot.isha: isha,
      };
}

/// Façade autour du package `adhan` : tu lui passes des AppSettings et un
/// jour, il te renvoie un PrayerSchedule prêt à l'affichage.
class PrayerEngine {
  /// Calcule les 6 horaires pour [day] selon les paramètres de l'utilisateur.
  ///
  /// Étapes :
  ///   1. Coordonnées et paramètres adhan (fajrAngle, ishaAngle, madhab).
  ///   2. Lecture de PrayerTimes pour ce jour.
  ///   3. Application des offsets par prière (+/- N min, voir AppSettings).
  ///   4. Substitution Jumu'ah si on est vendredi et que l'option est ON.
  PrayerSchedule scheduleFor(AppSettings settings, DateTime day) {
    final coords = Coordinates(settings.latitude, settings.longitude);
    final params = settings.preset.build()..madhab = settings.madhab;
    final dateComponents = DateComponents(day.year, day.month, day.day);
    final times = PrayerTimes(coords, dateComponents, params);

    // Helper local : applique l'ajustement minute par minute défini dans
    // les paramètres pour ce slot précis (0 = pas d'ajustement).
    DateTime applyOffset(PrayerSlot slot, DateTime base) {
      final off = settings.offsetFor(slot);
      return off == 0 ? base : base.add(Duration(minutes: off));
    }

    var dhuhr = applyOffset(PrayerSlot.dhuhr, times.dhuhr);
    var isJumuah = false;

    // Vendredi + jumuahEnabled → on écrase l'heure calculée du Dhuhr par
    // l'heure manuelle choisie (souvent 13:00 ou 14:00 selon la mosquée).
    // C'est le comportement Mawaqit standard.
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
      fajr: applyOffset(PrayerSlot.fajr, times.fajr),
      sunrise: applyOffset(PrayerSlot.sunrise, times.sunrise),
      dhuhr: dhuhr,
      asr: applyOffset(PrayerSlot.asr, times.asr),
      maghrib: applyOffset(PrayerSlot.maghrib, times.maghrib),
      isha: applyOffset(PrayerSlot.isha, times.isha),
      isJumuah: isJumuah,
    );
  }

  /// Renvoie la prochaine prière obligatoire après [now].
  ///
  /// On saute sunrise (ce n'est pas une prière). Si toutes les prières
  /// d'aujourd'hui sont déjà passées (typiquement après l'Isha), on renvoie
  /// le Fajr de demain pour que l'UI affiche un countdown qui passe minuit
  /// proprement.
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

  /// Renvoie la prière "en cours" (la plus récente dont l'heure est déjà
  /// passée). C'est ce slot qui est mis en valeur (orange) dans la rangée
  /// de cartes du HomeScreen.
  ///
  /// sunrise est ignoré : entre Fajr et Dhuhr, current reste = Fajr, même
  /// après le lever du soleil. C'est volontaire : tant qu'on n'a pas prié
  /// Dhuhr, on est encore dans le "créneau Fajr".
  ///
  /// Retourne null seulement si toutes les prières d'aujourd'hui sont dans
  /// le futur (entre minuit et Fajr, cas limite).
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

import 'package:hijri/hijri_calendar.dart';

class HijriHelper {
  static const List<String> monthNames = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qa'dah",
    'Dhu al-Hijjah',
  ];

  /// Renvoie l'offset en jours grégoriens à appliquer pour que la date hijrie
  /// affichée pour [todayGregorian] corresponde à [observedDay]/[observedMonth]/[observedYear].
  ///
  /// Recherche brute force dans une fenêtre de ±15 jours autour de zéro :
  /// suffisant pour les écarts entre tables astronomiques et observation lunaire.
  /// Renvoie `null` si aucun offset ne matche dans la fenêtre.
  static int? offsetForObservedDate({
    required DateTime todayGregorian,
    required int observedYear,
    required int observedMonth,
    required int observedDay,
  }) {
    for (var off = -15; off <= 15; off++) {
      final candidate = todayGregorian.add(Duration(days: off));
      final h = HijriCalendar.fromDate(candidate);
      if (h.hYear == observedYear &&
          h.hMonth == observedMonth &&
          h.hDay == observedDay) {
        return off;
      }
    }
    return null;
  }

  /// Date hijrie courante (sans offset).
  static HijriCalendar currentHijri([DateTime? now]) {
    return HijriCalendar.fromDate(now ?? DateTime.now());
  }
}

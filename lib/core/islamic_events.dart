// =============================================================================
// Moteur du calendrier islamique.
//
// Retourne les événements actifs pour une date grégorienne donnée :
// Eid, Ramadan, Arafa, Dhul Hijja, Achoura, Ayyam al-Beedh, jeûnes sunnah
// du lundi/jeudi, Mawlid, Isra Miraj, Sha'ban 15, Laylat ul-Qadr, etc.
//
// Usage :
//   final events = IslamicCalendar.eventsFor(DateTime.now(), hijriOffset: 0);
// =============================================================================

import 'package:hijri/hijri_calendar.dart';

enum IslamicEventType {
  eid,
  arafat,
  dhulHijja,
  ramadan,
  laylatulQadr,
  ayyamBeedh,
  mondayFast,
  thursdayFast,
  ashura,
  tasuaa,
}

class IslamicEvent {
  final IslamicEventType type;
  final String nameAr;
  final String nameFr;
  final String descFr;
  final bool isFasting;
  final bool isHoliday;

  const IslamicEvent({
    required this.type,
    required this.nameAr,
    required this.nameFr,
    required this.descFr,
    this.isFasting = false,
    this.isHoliday = false,
  });
}

class IslamicCalendar {
  /// Retourne tous les événements islamiques actifs pour [date].
  /// [hijriOffset] décale la date hijrie pour l'observation lunaire locale.
  static List<IslamicEvent> eventsFor(DateTime date, {int hijriOffset = 0}) {
    final hd = HijriCalendar.fromDate(date.add(Duration(days: hijriOffset)));
    final m = hd.hMonth;
    final d = hd.hDay;
    final weekday = date.weekday;
    final events = <IslamicEvent>[];

    // Ramadan (mois 9) + Laylat ul-Qadr (nuits impaires des 10 derniers jours)
    if (m == 9) {
      if (d >= 21 && d.isOdd) {
        events.add(const IslamicEvent(
          type: IslamicEventType.laylatulQadr,
          nameAr: 'ليلة القدر',
          nameFr: 'Laylat ul-Qadr',
          descFr: 'Nuit du Destin — meilleure que mille mois',
        ));
      }
      events.add(IslamicEvent(
        type: IslamicEventType.ramadan,
        nameAr: 'رمضان',
        nameFr: 'Ramadan — $d Ramadan',
        descFr: 'Mois sacré — jeûne obligatoire (Fajr → Maghrib)',
        isFasting: true,
      ));
    }

    // Eid al-Fitr (1 Shawwal, mois 10)
    if (m == 10 && d == 1) {
      events.add(const IslamicEvent(
        type: IslamicEventType.eid,
        nameAr: 'عيد الفطر',
        nameFr: 'Eid al-Fitr',
        descFr: 'Fête de la rupture du jeûne — تقبل الله منا ومنكم',
        isHoliday: true,
      ));
    }

    // Dhul Hijja (mois 12)
    if (m == 12) {
      if (d >= 1 && d <= 8) {
        events.add(IslamicEvent(
          type: IslamicEventType.dhulHijja,
          nameAr: 'أيام ذي الحجة',
          nameFr: '$d Dhul Hijja',
          descFr: 'Parmi les 10 jours les plus bénis — actes multipliés',
          isFasting: true,
        ));
      }
      if (d == 9) {
        events.add(const IslamicEvent(
          type: IslamicEventType.arafat,
          nameAr: 'يوم عرفة',
          nameFr: 'Jour d\'Arafa',
          descFr: 'Jeûne = expiation de deux années de péchés',
          isFasting: true,
        ));
      }
      if (d == 10) {
        events.add(const IslamicEvent(
          type: IslamicEventType.eid,
          nameAr: 'عيد الأضحى',
          nameFr: 'Eid al-Adha',
          descFr: 'Fête du Sacrifice — تقبل الله منا ومنكم',
          isHoliday: true,
        ));
      }
      if (d == 11 || d == 12 || d == 13) {
        events.add(IslamicEvent(
          type: IslamicEventType.dhulHijja,
          nameAr: 'أيام التشريق',
          nameFr: 'Tashreeq — $d Dhul Hijja',
          descFr: 'Jours de Dhikr et de célébration après l\'Eid al-Adha',
          isHoliday: true,
        ));
      }
    }

    // Muharram (mois 1)
    if (m == 1) {
      if (d == 9) {
        events.add(const IslamicEvent(
          type: IslamicEventType.tasuaa,
          nameAr: 'تاسوعاء',
          nameFr: 'Tasu\'a — 9 Muharram',
          descFr: 'Jeûne recommandé — veille d\'Achoura',
          isFasting: true,
        ));
      }
      if (d == 10) {
        events.add(const IslamicEvent(
          type: IslamicEventType.ashura,
          nameAr: 'عاشوراء',
          nameFr: 'Achoura — 10 Muharram',
          descFr: 'Jeûne = expiation d\'une année de péchés',
          isFasting: true,
        ));
      }
    }

    // Ayyam al-Beedh (13, 14, 15 de chaque mois)
    if (d == 13 || d == 14 || d == 15) {
      final noHigher = !events.any((e) =>
          e.type == IslamicEventType.ramadan ||
          e.type == IslamicEventType.eid ||
          e.type == IslamicEventType.arafat ||
          e.type == IslamicEventType.ashura ||
          e.type == IslamicEventType.dhulHijja);
      if (noHigher) {
        events.add(const IslamicEvent(
          type: IslamicEventType.ayyamBeedh,
          nameAr: 'الأيام البيض',
          nameFr: 'Jours Blancs',
          descFr: 'Jeûne recommandé — 13ᵉ, 14ᵉ et 15ᵉ du mois lunaire',
          isFasting: true,
        ));
      }
    }

    // Lundi et Jeudi (jeûne sunnah, uniquement si rien de plus important)
    final hasImportant = events.any((e) =>
        e.type == IslamicEventType.ramadan ||
        e.type == IslamicEventType.eid ||
        e.type == IslamicEventType.arafat ||
        e.type == IslamicEventType.ashura);
    if (!hasImportant) {
      if (weekday == DateTime.monday) {
        events.add(const IslamicEvent(
          type: IslamicEventType.mondayFast,
          nameAr: 'صوم الإثنين',
          nameFr: 'Lundi — Jeûne sunnah',
          descFr: 'Le Prophète ﷺ jeûnait chaque lundi',
          isFasting: true,
        ));
      }
      if (weekday == DateTime.thursday) {
        events.add(const IslamicEvent(
          type: IslamicEventType.thursdayFast,
          nameAr: 'صوم الخميس',
          nameFr: 'Jeudi — Jeûne sunnah',
          descFr: 'Le Prophète ﷺ jeûnait chaque jeudi',
          isFasting: true,
        ));
      }
    }

    // Tri par priorité (plus petit = plus important)
    events.sort((a, b) => _priority(a.type).compareTo(_priority(b.type)));
    return events;
  }

  /// Retourne l'événement le plus prioritaire pour une date.
  static IslamicEvent? topEventFor(DateTime date, {int hijriOffset = 0}) {
    final list = eventsFor(date, hijriOffset: hijriOffset);
    return list.isEmpty ? null : list.first;
  }

  static int _priority(IslamicEventType type) => switch (type) {
        IslamicEventType.eid => 0,
        IslamicEventType.arafat => 1,
        IslamicEventType.laylatulQadr => 2,
        IslamicEventType.ramadan => 3,
        IslamicEventType.ashura => 4,
        IslamicEventType.tasuaa => 5,
        IslamicEventType.dhulHijja => 6,
        IslamicEventType.ayyamBeedh => 7,
        IslamicEventType.mondayFast => 8,
        IslamicEventType.thursdayFast => 9,
      };
}

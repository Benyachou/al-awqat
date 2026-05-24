// =============================================================================
// Calcul des temps où la prière est interdite ou déconseillée
// (الأوقات المنهي عن الصلاة فيها).
//
// Trois moments d'INTERDICTION stricte (تحريم), liés à la position du soleil :
//   1. Le LEVER du soleil, jusqu'à ce qu'il se soit élevé « de la hauteur
//      d'une lance » (~15 min après le shurûq).
//   2. Le ZÉNITH / istiwâ' : quand le soleil est au plus haut, juste avant
//      qu'il décline — les ~6 min précédant le zawâl (adhan du Dhuhr).
//   3. Le COUCHER du soleil : quand le disque jaunit et descend, jusqu'à
//      disparition complète (~15 min avant le Maghrib).
//
// Deux moments DÉCONSEILLÉS (كراهة) — pas de prière surérogatoire sans cause :
//   4. Après la prière du Subh (Fajr) jusqu'au lever du soleil.
//   5. Après la prière de l'Asr jusqu'au coucher du soleil.
//
// On part toujours des horaires ASTRONOMIQUES bruts (lever, midi solaire,
// coucher) — pas de l'heure de Jumu'ah ni des horaires affichés par la
// mosquée — car ces interdictions sont liées à la position réelle du soleil.
//
// Les durées (15 / 6 / 15 min) sont des approximations communes ; elles sont
// regroupées en constantes pour être ajustées facilement.
// =============================================================================

import 'prayer_engine.dart';

/// Niveau de restriction sur la prière à un instant donné.
enum PrayerBan {
  /// Interdiction stricte (تحريم) : lever, zénith, coucher du soleil.
  forbidden,

  /// Déconseillé (كراهة) : après le Fajr jusqu'au lever, après l'Asr jusqu'au
  /// coucher. La prière surérogatoire « sans cause » y est blâmable.
  discouraged,
}

/// Un créneau `[start, end[` pendant lequel la prière est interdite ou
/// déconseillée, accompagné d'un libellé court et d'une explication.
class ForbiddenWindow {
  final DateTime start;
  final DateTime end;
  final PrayerBan ban;

  /// Libellé court affiché sur le cadran / la légende (ex : « Lever du soleil »).
  final String label;

  /// Phrase d'explication plus longue (tooltip / panneau de détail).
  final String description;

  const ForbiddenWindow({
    required this.start,
    required this.end,
    required this.ban,
    required this.label,
    required this.description,
  });

  /// Vrai si [t] tombe dans le créneau (borne de fin exclue).
  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  Duration get duration => end.difference(start);
}

/// Durées (approximatives) des trois fenêtres d'interdiction stricte.
class ForbiddenTimes {
  ForbiddenTimes._();

  /// Après le lever : tant que le soleil ne s'est pas élevé.
  static const sunriseBan = Duration(minutes: 15);

  /// Avant le zawâl : le soleil au méridien, immobile avant de décliner.
  static const zenithBan = Duration(minutes: 6);

  /// Avant le Maghrib : le soleil jaunit et descend jusqu'à disparaître.
  static const sunsetBan = Duration(minutes: 15);

  /// Construit la liste ordonnée des créneaux à partir d'un horaire
  /// ASTRONOMIQUE [s] (idéalement obtenu avec `applyJumuah: false`, pour que
  /// le zénith reste calé sur le vrai midi solaire même le vendredi).
  ///
  /// Ordre de la liste : déconseillés d'abord, interdits ensuite — pratique
  /// pour le dessin (les arcs rouges se superposent aux arcs orange).
  static List<ForbiddenWindow> forSchedule(PrayerSchedule s) {
    return [
      // --- Déconseillés (كراهة) ---
      ForbiddenWindow(
        start: s.fajr,
        end: s.sunrise,
        ban: PrayerBan.discouraged,
        label: 'Après le Fajr',
        description:
            'Du Subh jusqu\'au lever du soleil : pas de prière surérogatoire sans cause.',
      ),
      ForbiddenWindow(
        start: s.asr,
        end: s.maghrib,
        ban: PrayerBan.discouraged,
        label: 'Après l\'Asr',
        description:
            'De l\'Asr jusqu\'au coucher du soleil : pas de prière surérogatoire sans cause.',
      ),
      // --- Interdits stricts (تحريم) ---
      ForbiddenWindow(
        start: s.sunrise,
        end: s.sunrise.add(sunriseBan),
        ban: PrayerBan.forbidden,
        label: 'Lever du soleil',
        description:
            'Pendant que le soleil se lève, jusqu\'à ce qu\'il soit haut.',
      ),
      ForbiddenWindow(
        start: s.dhuhr.subtract(zenithBan),
        end: s.dhuhr,
        ban: PrayerBan.forbidden,
        label: 'Zénith (istiwâ\')',
        description:
            'Le soleil au plus haut, juste avant qu\'il décline (zawâl).',
      ),
      ForbiddenWindow(
        start: s.maghrib.subtract(sunsetBan),
        end: s.maghrib,
        ban: PrayerBan.forbidden,
        label: 'Coucher du soleil',
        description: 'Pendant que le soleil se couche, jusqu\'à sa disparition.',
      ),
    ];
  }

  /// Restriction en vigueur à l'instant [now] (l'interdiction stricte prime
  /// sur le simple « déconseillé »). Retourne null si la prière est permise.
  static PrayerBan? banAt(List<ForbiddenWindow> windows, DateTime now) {
    PrayerBan? result;
    for (final w in windows) {
      if (!w.contains(now)) continue;
      if (w.ban == PrayerBan.forbidden) return PrayerBan.forbidden;
      result = PrayerBan.discouraged;
    }
    return result;
  }

  /// Prochain créneau d'interdiction/déconseil à venir après [now] (le plus
  /// proche). Utile pour afficher « interdit dans 12 min ». Null si aucun.
  static ForbiddenWindow? nextAfter(
    List<ForbiddenWindow> windows,
    DateTime now,
  ) {
    ForbiddenWindow? best;
    for (final w in windows) {
      if (w.start.isAfter(now) &&
          (best == null || w.start.isBefore(best.start))) {
        best = w;
      }
    }
    return best;
  }
}

// =============================================================================
// State machine des écrans contextuels.
//
// L'idée : selon le moment vis-à-vis des prières, l'app affiche soit son
// HUD normal (cartes + horloge), soit un overlay spécial. La transition
// est automatique, pilotée par DisplayModeMachine.compute().
//
// Frise temporelle pour CHAQUE prière obligatoire :
//
//   T = heure de la prière (adhan sonne)
//   T+2min       → fin de l'adhan, dou'a après l'adhan apparaît
//   T+3min       → fin du dou'a, retour à l'écran normal
//   T+iqama-30s  → countdown iqama géant
//   T+iqama      → début de la prière, écran NORMAL pendant 10 min
//   T+iqama+10min → début des adhkar (défilent, 3 cycles complets)
//   T+iqama+23min → retour à l'écran normal
//
// Note : on n'a PAS d'écran "en prière" : pendant les 10 min de prière,
// l'app affiche le HUD normal pour ne pas gêner.
// =============================================================================

import 'prayer_engine.dart';

enum DisplayMode {
  /// HUD principal (cartes + horloge + date hijri).
  normal,

  /// L'adhan vient de sonner — grand écran « الأذان », background Médine.
  adhan,

  /// Invocation à réciter juste après l'adhan (~2-3 min après T).
  postAdhan,

  /// Compte à rebours géant des 30 dernières secondes avant l'iqama.
  iqamaCountdown,

  /// Adhkar récités après la prière. Affichage à plusieurs slides qui
  /// défilent, durée par slide proportionnelle au nombre de mots.
  postPrayer,
}

class DisplayContext {
  final DisplayMode mode;

  /// Slot concerné par le mode (null en mode normal).
  final PrayerSlot? slot;

  /// Heure prévue de la prière concernée.
  final DateTime? prayerTime;

  /// Compte à rebours pertinent (jusqu'à iqama, fin de phase, etc.).
  final Duration? countdown;

  const DisplayContext({
    required this.mode,
    this.slot,
    this.prayerTime,
    this.countdown,
  });

  static const normal = DisplayContext(mode: DisplayMode.normal);
}

class DisplayModeMachine {
  // === Durées des phases (en secondes) ===

  /// L'adhan dure environ 2 minutes — à l'écran on affiche الأذان pendant ce temps.
  static const adhanDurationSec = 120; // 2 min

  /// Après l'adhan, on affiche le dou'a pendant cette durée.
  static const postAdhanDurationSec = 60; // 1 min

  /// Combien de secondes avant l'iqama on bascule sur le countdown géant.
  static const iqamaCountdownLeadSec = 30;

  /// Durée approximative de la prière en commun (après l'iqama).
  /// Pendant ce temps, on reste sur l'écran NORMAL — pas d'overlay "en prière".
  static const prayerDurationSec = 10 * 60; // 10 min

  /// Durée des adhkar (invocations récitées après la prière).
  /// La liste défile 3 cycles complets ; 13 min couvrent la durée totale
  /// des 11 dhikr × 3 répétitions (~3 min 45 par cycle avec les × 33
  /// chronométrés à 25 s).
  static const adhkarDurationSec = 13 * 60; // 13 min

  /// Calcule l'état d'affichage pour [now] en parcourant les 5 prières
  /// obligatoires d'aujourd'hui. Renvoie le premier mode spécial qui matche,
  /// sinon DisplayContext.normal.
  static DisplayContext compute({
    required DateTime now,
    required PrayerSchedule today,
    required int iqamaMinutes,
  }) {
    for (final entry in today.all.entries) {
      final slot = entry.key;
      if (slot == PrayerSlot.sunrise) continue;
      final t = entry.value;
      final ctx = _evaluate(now, slot, t, iqamaMinutes);
      if (ctx.mode != DisplayMode.normal) return ctx;
    }
    return DisplayContext.normal;
  }

  /// Détermine le mode pour une prière donnée. Renvoie normal si on est
  /// hors de toutes les fenêtres spéciales.
  static DisplayContext _evaluate(
    DateTime now,
    PrayerSlot slot,
    DateTime t,
    int iqamaMinutes,
  ) {
    final adhanEnd = t.add(const Duration(seconds: adhanDurationSec));
    final postAdhanEnd =
        adhanEnd.add(const Duration(seconds: postAdhanDurationSec));
    final iqamaTime = t.add(Duration(minutes: iqamaMinutes));
    final iqamaCountdownStart =
        iqamaTime.subtract(const Duration(seconds: iqamaCountdownLeadSec));
    final prayerEnd =
        iqamaTime.add(const Duration(seconds: prayerDurationSec));
    final adhkarEnd =
        prayerEnd.add(const Duration(seconds: adhkarDurationSec));

    // Phase 1 : adhan en cours (T → T+2min).
    if (!now.isBefore(t) && now.isBefore(adhanEnd)) {
      return DisplayContext(
        mode: DisplayMode.adhan,
        slot: slot,
        prayerTime: t,
        countdown: adhanEnd.difference(now),
      );
    }

    // Phase 2 : dou'a après l'adhan (T+2min → T+3min).
    if (!now.isBefore(adhanEnd) && now.isBefore(postAdhanEnd)) {
      return DisplayContext(
        mode: DisplayMode.postAdhan,
        slot: slot,
        prayerTime: t,
        // countdown = temps restant jusqu'à l'iqama, pour information.
        countdown: iqamaTime.difference(now),
      );
    }

    // Phase 3 : countdown iqama (30 dernières secondes avant l'iqama).
    // Important : on ne déclenche QUE si on est dans cette fenêtre stricte,
    // pour ne pas bloquer le HUD normal pendant les 7+ min entre dou'a et iqama.
    if (!now.isBefore(iqamaCountdownStart) && now.isBefore(iqamaTime)) {
      return DisplayContext(
        mode: DisplayMode.iqamaCountdown,
        slot: slot,
        prayerTime: t,
        countdown: iqamaTime.difference(now),
      );
    }

    // Phase 4 : pendant la prière, on reste en NORMAL (pas d'overlay).
    // Donc rien à retourner ici — on tombe sur le check suivant.

    // Phase 5 : adhkar après la prière (iqama+10min → iqama+15min).
    if (!now.isBefore(prayerEnd) && now.isBefore(adhkarEnd)) {
      return DisplayContext(
        mode: DisplayMode.postPrayer,
        slot: slot,
        prayerTime: t,
        countdown: adhkarEnd.difference(now),
      );
    }

    return DisplayContext.normal;
  }
}

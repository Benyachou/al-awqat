// =============================================================================
// PrayerProvider : le cerveau de l'application.
//
// Ce ChangeNotifier est instancié UNE FOIS dans main.dart et partagé à tout
// l'arbre via Provider. Tous les widgets qui ont besoin de l'heure ou des
// horaires l'écoutent via `context.watch<PrayerProvider>()` ou `Consumer`.
//
// Responsabilités :
//   - Lance un timer toutes les secondes (le "tick") qui :
//       1. met à jour _now
//       2. recalcule les horaires si on a changé de jour à minuit
//       3. déclenche l'adhan audio si on vient de passer une heure de prière
//       4. notifie les widgets pour rebuild
//   - Expose des getters dérivés (currentPrayer, nextPrayer, untilNext,
//     iqamaCountdown, displayContext) calculés à la volée.
//   - Gère la persistance du dernier adhan joué (anti-rejeu après reboot).
//   - Délègue les paramètres au SettingsService et la lecture audio à
//     AudioService.
//   - Auto-check des updates GitHub au lancement (1×/24h max).
//
// IMPORTANT : ce provider notifie chaque SECONDE. Tous les widgets qui le
// consomment se rebuildent chaque seconde. Il ne faut donc pas y mettre
// de calculs trop lourds dans les getters, ni de widget trop coûteux à
// reconstruire (utilise const partout où possible).
// =============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/display_mode.dart';
import '../core/prayer_engine.dart';
import '../models/app_settings.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';

class PrayerProvider extends ChangeNotifier {
  /// Au démarrage :
  ///   - instancie tous les services internes
  ///   - applique le volume sauvegardé à l'AudioService
  ///   - restaure le dernier adhan joué (pour ne pas le rejouer au reboot)
  ///   - calcule les horaires d'aujourd'hui et de demain
  ///   - lance le timer 1Hz
  ///   - lance un check de update différé (5s) si activé
  PrayerProvider(this._settingsService) {
    _engine = PrayerEngine();
    _audio = AudioService();
    _updateService = UpdateService();
    _audio.setVolume(settings.adhanVolume);
    _restoreLastTriggered();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _maybeAutoCheckUpdates();
  }

  // --- Dépendances injectées / créées ---
  final SettingsService _settingsService;
  late final PrayerEngine _engine;
  late final AudioService _audio;
  late final UpdateService _updateService;
  late Timer _ticker;

  /// Exposé pour que l'UI puisse écouter audio.isPlaying (afficher le bouton
  /// stop) et déclencher manuellement audio.playAdhan() depuis le bouton test.
  AudioService get audio => _audio;
  UpdateService get updateService => _updateService;

  /// Dernier résultat du check d'update. Null tant qu'on n'a pas vérifié.
  /// `hasUpdate == true` → badge orange sur l'icône ⚙️ du header.
  UpdateInfo? _availableUpdate;
  UpdateInfo? get availableUpdate => _availableUpdate;

  // --- État courant (mutable via _tick) ---
  PrayerSchedule? _today;
  PrayerSchedule? _tomorrow;
  DateTime _now = DateTime.now();
  /// Jour pour lequel _today/_tomorrow ont été calculés. Sert à détecter
  /// le passage de minuit pour relancer un calcul.
  DateTime _scheduleDate = DateTime.now();

  /// Identité du dernier adhan joué (slot + timestamp). Persisté dans
  /// SharedPreferences pour qu'un reboot quelques minutes après une prière
  /// ne rejoue PAS l'adhan une deuxième fois.
  PrayerSlot? _lastTriggered;
  DateTime? _lastTriggeredAt;

  AppSettings get settings => _settingsService.settings;
  PrayerSchedule? get today => _today;
  DateTime get now => _now;

  /// Prochaine prière obligatoire après [_now], en sautant sunrise.
  /// Si l'Isha de today est passée, renvoie le Fajr de tomorrow.
  ({PrayerSlot slot, DateTime time})? get nextPrayer {
    if (_today == null || _tomorrow == null) return null;
    return _engine.nextPrayer(_today!, _tomorrow!, _now);
  }

  /// Prière "en cours" = la plus récente passée. Voir PrayerEngine.
  PrayerSlot? get currentPrayer {
    if (_today == null) return null;
    return _engine.currentPrayer(_today!, _now);
  }

  /// Durée entre maintenant et la prochaine prière. Utilisé par MawaqitClock
  /// pour afficher "Isha dans 1 h 20 min".
  Duration get untilNext {
    final next = nextPrayer;
    if (next == null) return Duration.zero;
    return next.time.difference(_now);
  }

  PrayerSchedule? get tomorrow => _tomorrow;

  /// Détermine quel écran afficher selon le moment de la journée :
  /// normal, adhan en cours, post-adhan, iqama countdown, prière, adhkar.
  /// Voir DisplayModeMachine pour les règles exactes.
  ///
  /// Si un preview est actif, on remplace le « now » réel par un « now »
  /// fictif positionné dans la phase voulue — la state machine fait tout
  /// le reste naturellement, les countdowns décrémentent en temps réel.
  DisplayContext get displayContext {
    if (_today == null) return DisplayContext.normal;
    return DisplayModeMachine.compute(
      now: _effectiveNow,
      today: _today!,
      iqamaMinutes: settings.iqamaMinutes,
    );
  }

  /// Heure « effective » utilisée par la state machine : c'est le `_now`
  /// réel sauf si un preview est actif, auquel cas on rejoue la timeline
  /// à partir d'un instant fictif (avancée 1 s pour 1 s de temps réel).
  DateTime get _effectiveNow {
    if (_previewFakeNow == null || _previewRealStartedAt == null) return _now;
    final realElapsed = _now.difference(_previewRealStartedAt!);
    return _previewFakeNow!.add(realElapsed);
  }

  // --- Mode preview (simulation d'un faux "now" pour valider les écrans) ---
  DateTime? _previewFakeNow;
  DateTime? _previewRealStartedAt;
  Timer? _previewTimer;

  bool get isPreviewing => _previewFakeNow != null;

  /// Lance un aperçu réaliste du mode [mode] : on injecte un faux instant
  /// placé dans la fenêtre temporelle correspondante, puis la state machine
  /// déroule la phase en temps réel (countdowns qui descendent, dou'as qui
  /// défilent, etc.). La durée est calibrée pour montrer la séquence complète.
  void previewMode(DisplayMode mode) {
    _previewTimer?.cancel();
    if (_today == null) return;

    final fakeSlot = currentPrayer ?? PrayerSlot.dhuhr;
    final prayerTime = _today!.all[fakeSlot] ?? _now;
    final iqamaMin = settings.iqamaMinutes;

    // Place un instant fictif au début de la phase choisie, sans tomber pile
    // sur la frontière (sinon on transite immédiatement vers la phase suivante).
    // Et choisit la durée du preview = ce qu'il reste de la phase + un peu.
    final (DateTime fakeNow, Duration previewLen) = switch (mode) {
      // Adhan : on entre 5 s après le début → 30 s d'aperçu suffisent
      // pour voir l'animation et le countdown qui descend.
      DisplayMode.adhan => (
          prayerTime.add(const Duration(seconds: 5)),
          const Duration(seconds: 30),
        ),
      // Post-adhan : juste après la fin de l'adhan. La fenêtre dure 60 s,
      // assez pour les 3 dou'as à 20 s. Preview = toute la fenêtre + 2 s.
      DisplayMode.postAdhan => (
          prayerTime.add(const Duration(
            seconds: DisplayModeMachine.adhanDurationSec + 1,
          )),
          const Duration(
            seconds: DisplayModeMachine.postAdhanDurationSec + 2,
          ),
        ),
      // Iqama countdown : on entre à 29 s avant l'iqama, on reste jusqu'à 0.
      DisplayMode.iqamaCountdown => (
          prayerTime
              .add(Duration(minutes: iqamaMin))
              .subtract(const Duration(seconds: 29)),
          const Duration(
            seconds: DisplayModeMachine.iqamaCountdownLeadSec + 2,
          ),
        ),
      // Post-prière : juste après les 10 min de prière, début des adhkar.
      // 60 s d'aperçu pour voir 3-4 slides défiler.
      DisplayMode.postPrayer => (
          prayerTime.add(Duration(
            minutes: iqamaMin + 10,
            seconds: 1,
          )),
          const Duration(seconds: 60),
        ),
      DisplayMode.normal => (_now, const Duration(seconds: 1)),
    };

    _previewFakeNow = fakeNow;
    _previewRealStartedAt = _now;
    notifyListeners();
    _previewTimer = Timer(previewLen, () {
      _previewFakeNow = null;
      _previewRealStartedAt = null;
      notifyListeners();
    });
  }

  /// Coupe immédiatement un éventuel preview en cours.
  void cancelPreview() {
    _previewTimer?.cancel();
    _previewFakeNow = null;
    _previewRealStartedAt = null;
    notifyListeners();
  }

  /// Point d'entrée pour tout changement de paramètre. Sauvegarde + applique
  /// + recalcule + notifie. Le check `volumeChanged` évite un setVolume()
  /// inutile à chaque rebuild.
  Future<void> updateSettings(AppSettings newSettings) async {
    final volumeChanged = newSettings.adhanVolume != settings.adhanVolume;
    await _settingsService.save(newSettings);
    if (volumeChanged) await _audio.setVolume(newSettings.adhanVolume);
    _recompute();
    notifyListeners();
  }

  /// Coupe l'adhan en cours (bouton stop dans le header).
  Future<void> stopAdhan() => _audio.stop();

  /// Force un check d'update (bouton "Vérifier maintenant" dans Paramètres).
  /// Met à jour [availableUpdate] et notifie.
  Future<UpdateInfo?> checkForUpdates() async {
    final repo = settings.updateRepoUrl;
    if (repo == null || repo.isEmpty) return null;
    final info = await _updateService.checkLatestRelease(repo);
    await _settingsService.setLastUpdateCheck(DateTime.now());
    _availableUpdate = info;
    notifyListeners();
    return info;
  }

  /// Auto-check au démarrage : ne fait rien si pas de repo configuré, ou
  /// si déjà vérifié il y a moins de 24h. Le délai de 5s laisse l'app
  /// terminer son premier frame avant de partir en requête réseau.
  Future<void> _maybeAutoCheckUpdates() async {
    if (!settings.autoCheckUpdates) return;
    final repo = settings.updateRepoUrl;
    if (repo == null || repo.isEmpty) return;
    final last = _settingsService.getLastUpdateCheck();
    final now = DateTime.now();
    if (last != null && now.difference(last).inHours < 24) return;
    await Future.delayed(const Duration(seconds: 5));
    await checkForUpdates();
  }

  /// Au démarrage : lit le dernier adhan joué depuis le storage pour
  /// alimenter le filtre anti-rejeu (voir _maybeTriggerAdhan).
  void _restoreLastTriggered() {
    final last = _settingsService.getLastTriggered();
    if (last == null) return;
    _lastTriggered = last.slot;
    _lastTriggeredAt = last.at;
  }

  /// Appelé chaque seconde par le timer.
  void _tick() {
    _now = DateTime.now();
    // Détection du passage de minuit (changement de jour) → recalcule.
    if (!_isSameDay(_now, _scheduleDate)) {
      _recompute();
    }
    _maybeTriggerAdhan();
    notifyListeners();
  }

  /// Recalcule les horaires d'aujourd'hui et de demain à partir des
  /// settings courants. Appelé au démarrage, à chaque changement de
  /// paramètre, et à minuit.
  void _recompute() {
    _now = DateTime.now();
    _scheduleDate = DateTime(_now.year, _now.month, _now.day);
    _today = _engine.scheduleFor(settings, _scheduleDate);
    _tomorrow = _engine.scheduleFor(
      settings,
      _scheduleDate.add(const Duration(days: 1)),
    );
  }

  /// Calcule les horaires pour un jour arbitraire (utilisé par l'écran
  /// "Calendrier mensuel" qui affiche les 30 prochains jours).
  PrayerSchedule scheduleForDay(DateTime day) =>
      _engine.scheduleFor(settings, day);

  /// Si on vient de franchir l'heure d'une prière (fenêtre 0-5 s), joue
  /// l'adhan. Le filtre _lastTriggered empêche le rejeu en cas de redémarrage
  /// ou de tick décalé.
  void _maybeTriggerAdhan() {
    if (!settings.playAdhan || _today == null) return;
    final current = _engine.currentPrayer(_today!, _now);
    if (current == null) return;
    final prayerTime = _today!.all[current];
    if (prayerTime == null) return;

    // Anti-rejeu : si on a déjà déclenché ce slot il y a moins de 10 min,
    // on ne refait pas. Couvre le cas où l'app redémarre 2 min après une
    // prière — sans ça, l'adhan rejouerait à chaque restart.
    if (_lastTriggered == current && _lastTriggeredAt != null) {
      final sinceLast = _now.difference(_lastTriggeredAt!).abs();
      if (sinceLast.inMinutes < 10) return;
    }

    // Fenêtre stricte 0-5 secondes : on déclenche pile au moment de
    // l'adhan, pas avant, pas longtemps après (ex : si l'app a été en
    // pause puis revient, on ne joue pas un adhan rétroactivement).
    final secondsSince = _now.difference(prayerTime).inSeconds;
    if (secondsSince >= 0 && secondsSince < 5) {
      _audio.playAdhan();
      _lastTriggered = current;
      _lastTriggeredAt = _now;
      _settingsService.setLastTriggered(current, _now);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _ticker.cancel();
    _previewTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }
}

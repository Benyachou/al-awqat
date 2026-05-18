// =============================================================================
// PrayerProvider : le cerveau de l'application.
//
// Ce ChangeNotifier est instancié UNE FOIS dans main.dart et partagé à tout
// l'arbre via Provider. Tous les widgets qui ont besoin de l'heure ou des
// horaires l'écoutent via `context.watch<PrayerProvider>()` ou `Consumer`.
//
// Responsabilités :
//   - Lance un timer toutes les secondes (le "tick") qui :
//       1. met à jour _wallNow
//       2. recalcule les horaires si on a changé de jour à minuit
//       3. déclenche l'adhan audio si on vient de passer une heure de prière
//       4. notifie les widgets pour rebuild
//   - Expose des getters dérivés (currentPrayer, nextPrayer, untilNext,
//     iqamaCountdown, displayContext) calculés à la volée.
//   - Gère la persistance du dernier adhan joué (anti-rejeu après reboot).
//   - Délègue les paramètres au SettingsService et la lecture audio à
//     AudioService.
//   - Auto-check des updates GitHub au lancement (1×/24h max).
//   - Mode simulation : `simulateTo(dt)` injecte un instant fictif dans
//     toute la machine d'état — le calendrier et les countdowns reflètent
//     l'heure simulée, pas l'heure réelle.
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

  final SettingsService _settingsService;
  late final PrayerEngine _engine;
  late final AudioService _audio;
  late final UpdateService _updateService;
  late Timer _ticker;

  AudioService get audio => _audio;
  UpdateService get updateService => _updateService;

  UpdateInfo? _availableUpdate;
  UpdateInfo? get availableUpdate => _availableUpdate;

  // --- Horloge murale (mise à jour chaque seconde par _tick) ---
  DateTime _wallNow = DateTime.now();

  PrayerSchedule? _today;
  PrayerSchedule? _tomorrow;

  /// Jour pour lequel _today/_tomorrow ont été calculés.
  DateTime _scheduleDate = DateTime.now();

  PrayerSlot? _lastTriggered;
  DateTime? _lastTriggeredAt;

  AppSettings get settings => _settingsService.settings;
  PrayerSchedule? get today => _today;
  PrayerSchedule? get tomorrow => _tomorrow;

  // =========================================================================
  // Mode simulation
  // =========================================================================

  /// Point de départ de la simulation (heure fictive choisie par l'user).
  DateTime? _simBase;

  /// Heure murale au moment où la simulation a été démarrée.
  /// Permet de faire avancer la simulation en temps réel.
  DateTime? _simStartWall;

  bool get isSimulating => _simBase != null;

  /// Lance la simulation depuis [fakeNow].
  /// Tous les getters (now, displayContext, nextPrayer…) reflèteront cet instant
  /// et avanceront à vitesse réelle jusqu'à l'appel de [stopSimulation].
  /// Si la phase simulée est l'adhan, l'audio est déclenché immédiatement.
  void simulateTo(DateTime fakeNow) {
    _previewTimer?.cancel();
    _previewFakeNow = null;
    _previewRealStartedAt = null;
    _simBase = fakeNow;
    _simStartWall = _wallNow;
    _recompute();
    // Joue l'adhan si on simule la phase adhan.
    if (displayContext.mode == DisplayMode.adhan && settings.playAdhan) {
      _audio.playAdhan(assetPath: _adhanAsset(currentPrayer));
    } else {
      _audio.stop();
    }
    notifyListeners();
  }

  /// Arrête la simulation et revient au temps réel.
  void stopSimulation() {
    _simBase = null;
    _simStartWall = null;
    _audio.stop();
    _recompute();
    notifyListeners();
  }

  // =========================================================================
  // Mode preview (simulation courte depuis les boutons "Test" des settings)
  // =========================================================================

  DateTime? _previewFakeNow;
  DateTime? _previewRealStartedAt;
  Timer? _previewTimer;

  bool get isPreviewing => _previewFakeNow != null;

  void previewMode(DisplayMode mode) {
    _previewTimer?.cancel();
    if (_today == null) return;

    final fakeSlot = currentPrayer ?? PrayerSlot.dhuhr;
    final prayerTime = _today!.all[fakeSlot] ?? _wallNow;
    final iqamaMin = settings.iqamaMinutes;

    final (DateTime fakeNow, Duration previewLen) = switch (mode) {
      DisplayMode.adhan => (
          prayerTime.add(const Duration(seconds: 5)),
          const Duration(seconds: 30),
        ),
      DisplayMode.postAdhan => (
          prayerTime.add(const Duration(
            seconds: DisplayModeMachine.adhanDurationSec + 1,
          )),
          const Duration(
            seconds: DisplayModeMachine.postAdhanDurationSec + 2,
          ),
        ),
      DisplayMode.iqamaCountdown => (
          prayerTime
              .add(Duration(minutes: iqamaMin))
              .subtract(const Duration(seconds: 29)),
          const Duration(
            seconds: DisplayModeMachine.iqamaCountdownLeadSec + 2,
          ),
        ),
      DisplayMode.postPrayer => (
          prayerTime.add(Duration(
            minutes: iqamaMin + 10,
            seconds: 1,
          )),
          const Duration(seconds: 60),
        ),
      DisplayMode.normal => (_wallNow, const Duration(seconds: 1)),
    };

    _previewFakeNow = fakeNow;
    _previewRealStartedAt = _wallNow;
    // Joue l'adhan si le preview démarre sur la phase adhan.
    if (mode == DisplayMode.adhan && settings.playAdhan) {
      _audio.playAdhan(assetPath: _adhanAsset(fakeSlot));
    } else {
      _audio.stop();
    }
    notifyListeners();
    _previewTimer = Timer(previewLen, () {
      _previewFakeNow = null;
      _previewRealStartedAt = null;
      _audio.stop();
      notifyListeners();
    });
  }

  void cancelPreview() {
    _previewTimer?.cancel();
    _previewFakeNow = null;
    _previewRealStartedAt = null;
    notifyListeners();
  }

  // =========================================================================
  // Getters exposés à l'UI
  // =========================================================================

  /// Heure effective exposée à tous les widgets.
  ///
  /// Priorité :
  ///   1. Simulation active → heure fictive avançant en temps réel depuis [_simBase].
  ///   2. Preview actif → heure fictive pour l'aperçu d'un mode d'affichage.
  ///   3. Sinon → heure murale réelle.
  DateTime get now {
    if (_simBase != null && _simStartWall != null) {
      return _simBase!.add(_wallNow.difference(_simStartWall!));
    }
    if (_previewFakeNow != null && _previewRealStartedAt != null) {
      return _previewFakeNow!.add(_wallNow.difference(_previewRealStartedAt!));
    }
    return _wallNow;
  }

  ({PrayerSlot slot, DateTime time})? get nextPrayer {
    if (_today == null || _tomorrow == null) return null;
    return _engine.nextPrayer(_today!, _tomorrow!, now);
  }

  PrayerSlot? get currentPrayer {
    if (_today == null) return null;
    return _engine.currentPrayer(_today!, now);
  }

  Duration get untilNext {
    final next = nextPrayer;
    if (next == null) return Duration.zero;
    return next.time.difference(now);
  }

  DisplayContext get displayContext {
    if (_today == null) return DisplayContext.normal;
    return DisplayModeMachine.compute(
      now: now,
      today: _today!,
      iqamaMinutes: settings.iqamaMinutes,
    );
  }

  // =========================================================================
  // Actions
  // =========================================================================

  Future<void> updateSettings(AppSettings newSettings) async {
    final volumeChanged = newSettings.adhanVolume != settings.adhanVolume;
    await _settingsService.save(newSettings);
    if (volumeChanged) await _audio.setVolume(newSettings.adhanVolume);
    _recompute();
    notifyListeners();
  }

  Future<void> stopAdhan() => _audio.stop();

  Future<UpdateInfo?> checkForUpdates() async {
    final repo = settings.updateRepoUrl;
    if (repo == null || repo.isEmpty) return null;
    final info = await _updateService.checkLatestRelease(repo);
    await _settingsService.setLastUpdateCheck(DateTime.now());
    _availableUpdate = info;
    notifyListeners();
    return info;
  }

  Future<void> _maybeAutoCheckUpdates() async {
    if (!settings.autoCheckUpdates) return;
    final repo = settings.updateRepoUrl;
    if (repo == null || repo.isEmpty) return;
    final last = _settingsService.getLastUpdateCheck();
    final wallNow = DateTime.now();
    if (last != null && wallNow.difference(last).inHours < 24) return;
    await Future.delayed(const Duration(seconds: 5));
    await checkForUpdates();
  }

  /// Calcule les horaires pour un jour arbitraire (utilisé par l'écran
  /// Calendrier mensuel et le Simulateur).
  PrayerSchedule scheduleForDay(DateTime day) =>
      _engine.scheduleFor(settings, day);

  // =========================================================================
  // Internals
  // =========================================================================

  void _restoreLastTriggered() {
    final last = _settingsService.getLastTriggered();
    if (last == null) return;
    _lastTriggered = last.slot;
    _lastTriggeredAt = last.at;
  }

  void _tick() {
    _wallNow = DateTime.now();
    // Détecte le changement de jour (vrai pour le temps effectif = sim ou réel).
    if (!_isSameDay(now, _scheduleDate)) {
      _recompute();
    }
    // Adhan uniquement en temps réel (jamais pendant une simulation).
    if (!isSimulating) _maybeTriggerAdhan();
    notifyListeners();
  }

  void _recompute() {
    _wallNow = DateTime.now();
    // Calcule pour la date effective : simulée si simulation active, sinon réelle.
    final ref = now;
    _scheduleDate = DateTime(ref.year, ref.month, ref.day);
    _today = _engine.scheduleFor(settings, _scheduleDate);
    _tomorrow = _engine.scheduleFor(
      settings,
      _scheduleDate.add(const Duration(days: 1)),
    );
  }

  /// Retourne le chemin asset du fichier adhan adapté au slot.
  /// Fajr a son propre adhan (avec "الصلاة خير من النوم").
  String _adhanAsset(PrayerSlot? slot) =>
      slot == PrayerSlot.fajr
          ? 'audio/Adhan_al_fajr.mp3'
          : 'audio/Adhan.mp3';

  void _maybeTriggerAdhan() {
    // Pendant la simulation, on ne joue jamais de vrai adhan.
    if (isSimulating) return;
    if (!settings.playAdhan || _today == null) return;
    final current = _engine.currentPrayer(_today!, _wallNow);
    if (current == null) return;
    final prayerTime = _today!.all[current];
    if (prayerTime == null) return;

    if (_lastTriggered == current && _lastTriggeredAt != null) {
      final sinceLast = _wallNow.difference(_lastTriggeredAt!).abs();
      if (sinceLast.inMinutes < 10) return;
    }

    final secondsSince = _wallNow.difference(prayerTime).inSeconds;
    if (secondsSince >= 0 && secondsSince < 5) {
      _audio.playAdhan(assetPath: _adhanAsset(current));
      _lastTriggered = current;
      _lastTriggeredAt = _wallNow;
      _settingsService.setLastTriggered(current, _wallNow);
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

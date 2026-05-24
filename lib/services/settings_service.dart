// =============================================================================
// SettingsService : persistance des préférences utilisateur.
//
// Wrapper autour de SharedPreferences (KV store natif Android/iOS, ou
// localStorage côté web). Convertit l'objet AppSettings (immuable) en
// paires clé/valeur typées et inversement.
//
// Pourquoi pas un seul JSON sérialisé ? Plus simple à debugger (on peut
// inspecter les clés une à une dans les DevTools navigateur), et migrable
// (on peut ajouter une clé sans casser les anciens enregistrements).
//
// Ce service gère aussi 3 valeurs "runtime" qui ne font PAS partie
// d'AppSettings (parce que purement techniques, jamais éditées par l'UI) :
//   - lastTriggeredSlot/At : anti-rejeu adhan (voir PrayerProvider).
//   - lastUpdateCheckAt    : pour limiter l'auto-check à 1×/24h.
// =============================================================================

import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/prayer_engine.dart';
import '../models/app_settings.dart';

class SettingsService {
  // --- Clés de persistance ---
  // Une constante par setting pour éviter les fautes de frappe. Si tu
  // renommes une clé, tu invalide tous les anciens enregistrements des
  // utilisateurs — fais-le seulement si nécessaire.
  static const _kLatitude = 'latitude';
  static const _kLongitude = 'longitude';
  static const _kCityName = 'cityName';
  static const _kMosqueeName = 'mosqueeName';
  static const _kPreset = 'calculationPresetKey';
  static const _kMadhab = 'madhab';
  static const _kPlayAdhan = 'playAdhan';
  static const _kAdhanVolume = 'adhanVolume';
  static const _kIqamaMinutes = 'iqamaMinutes';
  static const _kJumuahEnabled = 'jumuahEnabled';
  static const _kJumuahHour = 'jumuahHour';
  static const _kJumuahMinute = 'jumuahMinute';
  static const _kHijriOffset = 'hijriOffset';
  static const _kMawaqitSlug = 'mawaqitSlug';
  static const _kUseMawaqit = 'useMawaqit';
  static const _kUpdateRepoUrl = 'updateRepoUrl';
  static const _kAutoCheckUpdates = 'autoCheckUpdates';
  static const _kBackgroundDimming = 'backgroundDimming';
  static const _kClockScale = 'clockScale';
  static const _kSideScale = 'sideScale';
  static const _kCardScale = 'cardScale';
  static const _kHeaderScale = 'headerScale';
  static const _kFontScale = 'fontScale';
  /// Préfixe pour les offsets par prière. La clé complète est par exemple
  /// "prayerOffset_fajr" pour le décalage du Fajr en minutes.
  static const _kPrayerOffsetPrefix = 'prayerOffset_';

  // --- Clés "runtime" (état technique, pas dans AppSettings) ---
  static const _kLastTriggeredSlot = 'lastTriggeredSlot';
  static const _kLastTriggeredAt = 'lastTriggeredAt';
  static const _kLastUpdateCheckAt = 'lastUpdateCheckAt';

  late SharedPreferences _prefs;
  AppSettings _settings = AppSettings.defaults;

  /// Settings actuellement en mémoire. PrayerProvider y accède via
  /// `provider.settings` (qui pointe ici).
  AppSettings get settings => _settings;

  /// Lit toutes les valeurs depuis SharedPreferences. À appeler UNE FOIS
  /// au démarrage avant d'instancier le PrayerProvider, sinon le premier
  /// rendu serait fait avec les defaults puis "sauterait".
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final offsets = <PrayerSlot, int>{};
    for (final slot in PrayerSlot.values) {
      final v = _prefs.getInt('$_kPrayerOffsetPrefix${slot.name}');
      if (v != null && v != 0) offsets[slot] = v;
    }
    _settings = AppSettings(
      latitude: _prefs.getDouble(_kLatitude) ?? AppSettings.defaults.latitude,
      longitude:
          _prefs.getDouble(_kLongitude) ?? AppSettings.defaults.longitude,
      cityName: _prefs.getString(_kCityName) ?? AppSettings.defaults.cityName,
      mosqueeName: _prefs.getString(_kMosqueeName) ??
          AppSettings.defaults.mosqueeName,
      calculationPresetKey: _prefs.getString(_kPreset) ??
          AppSettings.defaults.calculationPresetKey,
      madhab: _decodeMadhab(_prefs.getString(_kMadhab)),
      playAdhan: _prefs.getBool(_kPlayAdhan) ?? AppSettings.defaults.playAdhan,
      adhanVolume:
          _prefs.getDouble(_kAdhanVolume) ?? AppSettings.defaults.adhanVolume,
      iqamaMinutes:
          _prefs.getInt(_kIqamaMinutes) ?? AppSettings.defaults.iqamaMinutes,
      jumuahEnabled: _prefs.getBool(_kJumuahEnabled) ??
          AppSettings.defaults.jumuahEnabled,
      jumuahHour:
          _prefs.getInt(_kJumuahHour) ?? AppSettings.defaults.jumuahHour,
      jumuahMinute:
          _prefs.getInt(_kJumuahMinute) ?? AppSettings.defaults.jumuahMinute,
      hijriOffset:
          _prefs.getInt(_kHijriOffset) ?? AppSettings.defaults.hijriOffset,
      mawaqitSlug: _prefs.getString(_kMawaqitSlug),
      useMawaqit:
          _prefs.getBool(_kUseMawaqit) ?? AppSettings.defaults.useMawaqit,
      updateRepoUrl: _prefs.getString(_kUpdateRepoUrl),
      autoCheckUpdates: _prefs.getBool(_kAutoCheckUpdates) ??
          AppSettings.defaults.autoCheckUpdates,
      prayerOffsets: offsets,
      backgroundDimming: _prefs.getDouble(_kBackgroundDimming) ??
          AppSettings.defaults.backgroundDimming,
      clockScale: _prefs.getDouble(_kClockScale) ??
          AppSettings.defaults.clockScale,
      sideScale: _prefs.getDouble(_kSideScale) ??
          AppSettings.defaults.sideScale,
      cardScale: _prefs.getDouble(_kCardScale) ??
          AppSettings.defaults.cardScale,
      headerScale: _prefs.getDouble(_kHeaderScale) ??
          AppSettings.defaults.headerScale,
      fontScale: _prefs.getDouble(_kFontScale) ??
          AppSettings.defaults.fontScale,
    );
  }

  /// Sauvegarde l'intégralité des settings. Appelé après chaque updateSettings()
  /// du PrayerProvider. L'écriture est asynchrone mais on lance toutes les
  /// clés en parallèle (Future.wait) pour minimiser la latence.
  Future<void> save(AppSettings newSettings) async {
    _settings = newSettings;
    final futures = <Future<bool>>[
      _prefs.setDouble(_kLatitude, newSettings.latitude),
      _prefs.setDouble(_kLongitude, newSettings.longitude),
      _prefs.setString(_kCityName, newSettings.cityName),
      _prefs.setString(_kMosqueeName, newSettings.mosqueeName),
      _prefs.setString(_kPreset, newSettings.calculationPresetKey),
      _prefs.setString(_kMadhab, newSettings.madhab.name),
      _prefs.setBool(_kPlayAdhan, newSettings.playAdhan),
      _prefs.setDouble(_kAdhanVolume, newSettings.adhanVolume),
      _prefs.setInt(_kIqamaMinutes, newSettings.iqamaMinutes),
      _prefs.setBool(_kJumuahEnabled, newSettings.jumuahEnabled),
      _prefs.setInt(_kJumuahHour, newSettings.jumuahHour),
      _prefs.setInt(_kJumuahMinute, newSettings.jumuahMinute),
      _prefs.setInt(_kHijriOffset, newSettings.hijriOffset),
      _prefs.setBool(_kUseMawaqit, newSettings.useMawaqit),
      _prefs.setBool(_kAutoCheckUpdates, newSettings.autoCheckUpdates),
      _prefs.setDouble(_kBackgroundDimming, newSettings.backgroundDimming),
      _prefs.setDouble(_kClockScale, newSettings.clockScale),
      _prefs.setDouble(_kSideScale, newSettings.sideScale),
      _prefs.setDouble(_kCardScale, newSettings.cardScale),
      _prefs.setDouble(_kHeaderScale, newSettings.headerScale),
      _prefs.setDouble(_kFontScale, newSettings.fontScale),
    ];
    if (newSettings.mawaqitSlug != null) {
      futures.add(_prefs.setString(_kMawaqitSlug, newSettings.mawaqitSlug!));
    } else {
      await _prefs.remove(_kMawaqitSlug);
    }
    // Cas null : on supprime la clé pour ne pas la lire au prochain load().
    if (newSettings.updateRepoUrl != null) {
      futures.add(_prefs.setString(_kUpdateRepoUrl, newSettings.updateRepoUrl!));
    } else {
      await _prefs.remove(_kUpdateRepoUrl);
    }
    // Offsets par prière : on ne stocke que les non-zéro (économie de
    // place + plus rapide à charger).
    for (final slot in PrayerSlot.values) {
      final offset = newSettings.prayerOffsets[slot] ?? 0;
      final key = '$_kPrayerOffsetPrefix${slot.name}';
      if (offset == 0) {
        await _prefs.remove(key);
      } else {
        futures.add(_prefs.setInt(key, offset));
      }
    }
    await Future.wait(futures);
  }

  /// Lit le dernier adhan déclenché (slot + timestamp). Utilisé au démarrage
  /// par PrayerProvider pour ne pas rejouer un adhan déjà sonné juste avant
  /// un reboot.
  ({PrayerSlot slot, DateTime at})? getLastTriggered() {
    final slotName = _prefs.getString(_kLastTriggeredSlot);
    final at = _prefs.getInt(_kLastTriggeredAt);
    if (slotName == null || at == null) return null;
    final slot = PrayerSlot.values.firstWhere(
      (s) => s.name == slotName,
      orElse: () => PrayerSlot.fajr,
    );
    return (slot: slot, at: DateTime.fromMillisecondsSinceEpoch(at));
  }

  /// Mémorise qu'on vient de jouer l'adhan de [slot] à [at]. Appelé par
  /// PrayerProvider juste après chaque déclenchement.
  Future<void> setLastTriggered(PrayerSlot slot, DateTime at) async {
    await _prefs.setString(_kLastTriggeredSlot, slot.name);
    await _prefs.setInt(_kLastTriggeredAt, at.millisecondsSinceEpoch);
  }

  /// Date du dernier check d'update. Null si jamais vérifié.
  DateTime? getLastUpdateCheck() {
    final v = _prefs.getInt(_kLastUpdateCheckAt);
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v);
  }

  Future<void> setLastUpdateCheck(DateTime at) async {
    await _prefs.setInt(_kLastUpdateCheckAt, at.millisecondsSinceEpoch);
  }

  /// Décode le madhab depuis sa string (le `.name` de l'enum). En cas
  /// d'erreur (string corrompue ou inconnue), on retombe sur le défaut Shafi.
  Madhab _decodeMadhab(String? raw) {
    if (raw == null) return AppSettings.defaults.madhab;
    return Madhab.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppSettings.defaults.madhab,
    );
  }
}

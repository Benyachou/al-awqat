// =============================================================================
// Modèle immuable de la configuration utilisateur.
//
// Tous les réglages que l'utilisateur peut modifier dans l'écran Paramètres
// vivent ici. La classe est immuable (tous les champs `final`) — pour la
// modifier on appelle `copyWith(...)` qui renvoie une nouvelle instance.
// C'est plus sûr (pas d'effet de bord) et c'est ce que Provider attend
// pour redéclencher les rebuilds correctement.
//
// Persistance : sérialisée champ par champ dans SharedPreferences via
// SettingsService.save() à chaque updateSettings() du provider.
// =============================================================================

import 'package:adhan/adhan.dart';

import '../core/calculation_preset.dart';
import '../core/prayer_engine.dart';

class AppSettings {
  // --- Géolocalisation ---
  /// Latitude en degrés décimaux (-90 à 90).
  final double latitude;
  /// Longitude en degrés décimaux (-180 à 180).
  final double longitude;
  /// Libellé affiché de la ville (ex: "Ganges, France (34190)").
  /// Peut être un preset PresetCities OU un résultat Nominatim OU du free-text.
  final String cityName;

  /// Nom de la mosquée affiché en gros dans le header. Indépendant de la
  /// ville pour permettre "Mosquée de Ganges" sans répéter "Ganges".
  final String mosqueeName;

  // --- Calcul des horaires ---
  /// Clé du preset (mosquee_paris, mwl, umm_al_qura, etc.). Voir CalculationPreset.
  final String calculationPresetKey;
  /// Choisi par l'utilisateur — impacte uniquement l'heure du Asr.
  /// Shafi/Maliki/Hanbali = ombre × 1 (standard), Hanafi = ombre × 2 (Asr ~1h plus tard).
  final Madhab madhab;

  // --- Adhan ---
  /// Lecture automatique du fichier adhan.mp3 à chaque prière.
  final bool playAdhan;
  /// 0.0 (muet) à 1.0 (volume max).
  final double adhanVolume;

  // --- Iqama ---
  /// Délai entre l'adhan et l'iqama (la prière en commun). En minutes.
  /// Standard 10-15 min.
  final int iqamaMinutes;

  // --- Jumu'ah (vendredi) ---
  /// Si true, remplace Dhuhr par Jumu'ah le vendredi.
  final bool jumuahEnabled;
  /// Heure de la khutba du vendredi (heure fixée par la mosquée).
  final int jumuahHour;
  final int jumuahMinute;

  // --- Calendrier ---
  /// Décalage manuel de la date hijrie (en jours). Permet de s'aligner sur
  /// l'observation lunaire locale qui peut différer du calcul astronomique.
  /// Plage : -15 à +15. Voir HijriHelper.offsetForObservedDate.
  final int hijriOffset;

  // --- Mawaqit ---
  /// Slug de la mosquée Mawaqit (ex: "ascg-ganges-34190-france").
  /// Null si non configuré.
  final String? mawaqitSlug;
  /// Utiliser l'API Mawaqit comme source principale des horaires.
  /// Si false (ou si le fetch échoue), on utilise PrayerEngine en local.
  final bool useMawaqit;

  // --- Mises à jour ---
  /// Dépôt GitHub "owner/repo" à interroger pour les nouvelles versions.
  /// Null si non configuré.
  final String? updateRepoUrl;
  /// Vérification automatique 1×/jour au démarrage.
  final bool autoCheckUpdates;

  // --- Ajustements fins par prière ---
  /// Décalage en minutes appliqué à chaque prière individuellement.
  /// Permet d'aligner avec la mosquée locale (ex: certaines mosquées
  /// font Maghrib +2 min, etc.). Plage par slot : -15 à +15.
  final Map<PrayerSlot, int> prayerOffsets;

  // --- Affichage ---
  /// Opacité du voile sombre par-dessus l'image de fond. 0 = image pure
  /// (peu lisible), 1 = quasi-noir (texte ultra net). Défaut 0.55.
  final double backgroundDimming;

  /// 5 facteurs multiplicatifs pour ajuster la taille des éléments en live
  /// depuis Settings → Affichage. Tous = 1.0 par défaut.
  /// - clockScale : la grande horloge centrale + chip countdown + date hijri.
  /// - sideScale  : les pilules Shurûq / Jumu'ah.
  /// - cardScale  : les 6 cartes des prières en bas (taille de la bulle).
  /// - headerScale: le nom mosquée + ville en haut.
  /// - fontScale  : facteur GLOBAL qui multiplie tous les autres.
  ///
  /// Au final, la taille effective = sizeNominal × scaleParZone × fontScale.
  final double clockScale;
  final double sideScale;
  final double cardScale;
  final double headerScale;
  final double fontScale;

  const AppSettings({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.mosqueeName,
    required this.calculationPresetKey,
    required this.madhab,
    required this.playAdhan,
    required this.adhanVolume,
    required this.iqamaMinutes,
    required this.jumuahEnabled,
    required this.jumuahHour,
    required this.jumuahMinute,
    required this.hijriOffset,
    required this.mawaqitSlug,
    required this.useMawaqit,
    required this.updateRepoUrl,
    required this.autoCheckUpdates,
    required this.prayerOffsets,
    required this.backgroundDimming,
    required this.clockScale,
    required this.sideScale,
    required this.cardScale,
    required this.headerScale,
    required this.fontScale,
  });

  /// Valeurs utilisées au tout premier lancement (avant qu'un seul setting
  /// soit sauvegardé). Ganges/Mosquée de Paris/Shafi = profil de Yassine.
  /// Si tu veux changer le défaut pour quelqu'un d'autre, c'est ici.
  static const AppSettings defaults = AppSettings(
    latitude: 43.9333,
    longitude: 3.7167,
    cityName: 'Ganges, France (34190)',
    mosqueeName: 'Mosquée de Ganges',
    calculationPresetKey: 'mosquee_paris',
    madhab: Madhab.shafi,
    playAdhan: true,
    adhanVolume: 1.0,
    iqamaMinutes: 10,
    jumuahEnabled: true,
    jumuahHour: 14,
    jumuahMinute: 0,
    hijriOffset: 0,
    mawaqitSlug: null,
    useMawaqit: false,
    updateRepoUrl: null,
    autoCheckUpdates: true,
    prayerOffsets: <PrayerSlot, int>{},
    backgroundDimming: 0.55,
    clockScale: 1.0,
    sideScale: 1.0,
    cardScale: 1.0,
    headerScale: 1.0,
    fontScale: 1.0,
  );

  /// Raccourci : récupère l'objet CalculationPreset complet (avec sa fonction
  /// build()) à partir de la clé stockée.
  CalculationPreset get preset =>
      CalculationPreset.byKey(calculationPresetKey);

  /// Offset en minutes pour [slot], 0 si non configuré.
  int offsetFor(PrayerSlot slot) => prayerOffsets[slot] ?? 0;

  /// Copie immuable avec quelques champs remplacés. Utilisé partout dans
  /// Settings pour modifier UN setting sans toucher au reste.
  ///
  /// Cas spécial `clearUpdateRepoUrl: true` → force à null (sinon impossible
  /// car `null` est utilisé pour "ne pas changer").
  AppSettings copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? mosqueeName,
    String? calculationPresetKey,
    Madhab? madhab,
    bool? playAdhan,
    double? adhanVolume,
    int? iqamaMinutes,
    bool? jumuahEnabled,
    int? jumuahHour,
    int? jumuahMinute,
    int? hijriOffset,
    String? mawaqitSlug,
    bool clearMawaqitSlug = false,
    bool? useMawaqit,
    String? updateRepoUrl,
    bool clearUpdateRepoUrl = false,
    bool? autoCheckUpdates,
    Map<PrayerSlot, int>? prayerOffsets,
    double? backgroundDimming,
    double? clockScale,
    double? sideScale,
    double? cardScale,
    double? headerScale,
    double? fontScale,
  }) {
    return AppSettings(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      mosqueeName: mosqueeName ?? this.mosqueeName,
      calculationPresetKey:
          calculationPresetKey ?? this.calculationPresetKey,
      madhab: madhab ?? this.madhab,
      playAdhan: playAdhan ?? this.playAdhan,
      adhanVolume: adhanVolume ?? this.adhanVolume,
      iqamaMinutes: iqamaMinutes ?? this.iqamaMinutes,
      jumuahEnabled: jumuahEnabled ?? this.jumuahEnabled,
      jumuahHour: jumuahHour ?? this.jumuahHour,
      jumuahMinute: jumuahMinute ?? this.jumuahMinute,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      mawaqitSlug:
          clearMawaqitSlug ? null : (mawaqitSlug ?? this.mawaqitSlug),
      useMawaqit: useMawaqit ?? this.useMawaqit,
      updateRepoUrl: clearUpdateRepoUrl
          ? null
          : (updateRepoUrl ?? this.updateRepoUrl),
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      prayerOffsets: prayerOffsets ?? this.prayerOffsets,
      backgroundDimming: backgroundDimming ?? this.backgroundDimming,
      clockScale: clockScale ?? this.clockScale,
      sideScale: sideScale ?? this.sideScale,
      cardScale: cardScale ?? this.cardScale,
      headerScale: headerScale ?? this.headerScale,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

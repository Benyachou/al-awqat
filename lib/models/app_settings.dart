import 'package:adhan/adhan.dart';

import '../core/calculation_preset.dart';

class AppSettings {
  final double latitude;
  final double longitude;
  final String cityName;
  final String calculationPresetKey;
  final Madhab madhab;
  final bool playAdhan;
  final int iqamaMinutes;
  final bool jumuahEnabled;
  final int jumuahHour;
  final int jumuahMinute;
  final int hijriOffset;
  final String? updateRepoUrl;

  const AppSettings({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.calculationPresetKey,
    required this.madhab,
    required this.playAdhan,
    required this.iqamaMinutes,
    required this.jumuahEnabled,
    required this.jumuahHour,
    required this.jumuahMinute,
    required this.hijriOffset,
    required this.updateRepoUrl,
  });

  static const AppSettings defaults = AppSettings(
    latitude: 43.9333,
    longitude: 3.7167,
    cityName: 'Ganges, France (34190)',
    calculationPresetKey: 'mosquee_paris',
    madhab: Madhab.shafi,
    playAdhan: true,
    iqamaMinutes: 10,
    jumuahEnabled: true,
    jumuahHour: 14,
    jumuahMinute: 0,
    hijriOffset: 0,
    updateRepoUrl: null,
  );

  CalculationPreset get preset =>
      CalculationPreset.byKey(calculationPresetKey);

  AppSettings copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? calculationPresetKey,
    Madhab? madhab,
    bool? playAdhan,
    int? iqamaMinutes,
    bool? jumuahEnabled,
    int? jumuahHour,
    int? jumuahMinute,
    int? hijriOffset,
    String? updateRepoUrl,
  }) {
    return AppSettings(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      calculationPresetKey:
          calculationPresetKey ?? this.calculationPresetKey,
      madhab: madhab ?? this.madhab,
      playAdhan: playAdhan ?? this.playAdhan,
      iqamaMinutes: iqamaMinutes ?? this.iqamaMinutes,
      jumuahEnabled: jumuahEnabled ?? this.jumuahEnabled,
      jumuahHour: jumuahHour ?? this.jumuahHour,
      jumuahMinute: jumuahMinute ?? this.jumuahMinute,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      updateRepoUrl: updateRepoUrl ?? this.updateRepoUrl,
    );
  }
}

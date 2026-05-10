import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService {
  static const _kLatitude = 'latitude';
  static const _kLongitude = 'longitude';
  static const _kCityName = 'cityName';
  static const _kPreset = 'calculationPresetKey';
  static const _kMadhab = 'madhab';
  static const _kPlayAdhan = 'playAdhan';
  static const _kIqamaMinutes = 'iqamaMinutes';
  static const _kJumuahEnabled = 'jumuahEnabled';
  static const _kJumuahHour = 'jumuahHour';
  static const _kJumuahMinute = 'jumuahMinute';
  static const _kHijriOffset = 'hijriOffset';
  static const _kUpdateRepoUrl = 'updateRepoUrl';

  late SharedPreferences _prefs;
  AppSettings _settings = AppSettings.defaults;

  AppSettings get settings => _settings;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _settings = AppSettings(
      latitude: _prefs.getDouble(_kLatitude) ?? AppSettings.defaults.latitude,
      longitude:
          _prefs.getDouble(_kLongitude) ?? AppSettings.defaults.longitude,
      cityName: _prefs.getString(_kCityName) ?? AppSettings.defaults.cityName,
      calculationPresetKey: _prefs.getString(_kPreset) ??
          AppSettings.defaults.calculationPresetKey,
      madhab: _decodeMadhab(_prefs.getString(_kMadhab)),
      playAdhan: _prefs.getBool(_kPlayAdhan) ?? AppSettings.defaults.playAdhan,
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
      updateRepoUrl: _prefs.getString(_kUpdateRepoUrl),
    );
  }

  Future<void> save(AppSettings newSettings) async {
    _settings = newSettings;
    await Future.wait([
      _prefs.setDouble(_kLatitude, newSettings.latitude),
      _prefs.setDouble(_kLongitude, newSettings.longitude),
      _prefs.setString(_kCityName, newSettings.cityName),
      _prefs.setString(_kPreset, newSettings.calculationPresetKey),
      _prefs.setString(_kMadhab, newSettings.madhab.name),
      _prefs.setBool(_kPlayAdhan, newSettings.playAdhan),
      _prefs.setInt(_kIqamaMinutes, newSettings.iqamaMinutes),
      _prefs.setBool(_kJumuahEnabled, newSettings.jumuahEnabled),
      _prefs.setInt(_kJumuahHour, newSettings.jumuahHour),
      _prefs.setInt(_kJumuahMinute, newSettings.jumuahMinute),
      _prefs.setInt(_kHijriOffset, newSettings.hijriOffset),
      if (newSettings.updateRepoUrl != null)
        _prefs.setString(_kUpdateRepoUrl, newSettings.updateRepoUrl!)
      else
        _prefs.remove(_kUpdateRepoUrl),
    ]);
  }

  Madhab _decodeMadhab(String? raw) {
    if (raw == null) return AppSettings.defaults.madhab;
    return Madhab.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppSettings.defaults.madhab,
    );
  }
}

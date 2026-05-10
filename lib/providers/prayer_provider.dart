import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/prayer_engine.dart';
import '../core/prayer_period.dart';
import '../models/app_settings.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';

class PrayerProvider extends ChangeNotifier {
  PrayerProvider(this._settingsService) {
    _engine = PrayerEngine();
    _periods = PrayerPeriodCalculator();
    _audio = AudioService();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final SettingsService _settingsService;
  late final PrayerEngine _engine;
  late final PrayerPeriodCalculator _periods;
  late final AudioService _audio;
  late Timer _ticker;

  PrayerSchedule? _today;
  PrayerSchedule? _tomorrow;
  DateTime _now = DateTime.now();
  DateTime _scheduleDate = DateTime.now();
  PrayerSlot? _lastTriggered;

  AppSettings get settings => _settingsService.settings;
  PrayerSchedule? get today => _today;
  DateTime get now => _now;

  ({PrayerSlot slot, DateTime time})? get nextPrayer {
    if (_today == null || _tomorrow == null) return null;
    return _engine.nextPrayer(_today!, _tomorrow!, _now);
  }

  PrayerSlot? get currentPrayer {
    if (_today == null) return null;
    return _engine.currentPrayer(_today!, _now);
  }

  /// The prayer slot whose time was reached within the last 5 minutes,
  /// used to trigger the blinking "adhan vient de sonner" highlight.
  PrayerSlot? get freshlyStartedSlot {
    if (_today == null) return null;
    final current = _engine.currentPrayer(_today!, _now);
    if (current == null) return null;
    final time = _today!.all[current];
    if (time == null) return null;
    final elapsed = _now.difference(time);
    if (elapsed.inSeconds >= 0 && elapsed.inMinutes < 5) {
      return current;
    }
    return null;
  }

  Duration get untilNext {
    final next = nextPrayer;
    if (next == null) return Duration.zero;
    return next.time.difference(_now);
  }

  PrayerPeriod? get currentPeriod {
    if (_today == null || _tomorrow == null) return null;
    return _periods.currentPeriod(_today!, _tomorrow!, _now);
  }

  List<PrayerPeriod> get dayPeriods {
    if (_today == null || _tomorrow == null) return const [];
    return _periods.buildDay(_today!, _tomorrow!);
  }

  PrayerSchedule? get tomorrow => _tomorrow;

  /// If we are within the iqama window after the last adhan, returns
  /// the time remaining until iqama. Otherwise null.
  ({PrayerSlot slot, Duration remaining})? get iqamaCountdown {
    if (_today == null) return null;
    final current = _engine.currentPrayer(_today!, _now);
    if (current == null) return null;
    final prayerTime = _today!.all[current];
    if (prayerTime == null) return null;
    final iqamaTime =
        prayerTime.add(Duration(minutes: settings.iqamaMinutes));
    if (_now.isBefore(iqamaTime)) {
      return (slot: current, remaining: iqamaTime.difference(_now));
    }
    return null;
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    await _settingsService.save(newSettings);
    _recompute();
    notifyListeners();
  }

  void _tick() {
    _now = DateTime.now();
    if (!_isSameDay(_now, _scheduleDate)) {
      _recompute();
    }
    _maybeTriggerAdhan();
    notifyListeners();
  }

  void _recompute() {
    _now = DateTime.now();
    _scheduleDate = DateTime(_now.year, _now.month, _now.day);
    _today = _engine.scheduleFor(settings, _scheduleDate);
    _tomorrow = _engine.scheduleFor(
      settings,
      _scheduleDate.add(const Duration(days: 1)),
    );
  }

  void _maybeTriggerAdhan() {
    if (!settings.playAdhan || _today == null) return;
    final current = _engine.currentPrayer(_today!, _now);
    if (current == null || current == _lastTriggered) return;
    final prayerTime = _today!.all[current];
    if (prayerTime == null) return;
    final secondsSince = _now.difference(prayerTime).inSeconds;
    if (secondsSince >= 0 && secondsSince < 5) {
      _audio.playAdhan();
      _lastTriggered = current;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _ticker.cancel();
    _audio.dispose();
    super.dispose();
  }
}

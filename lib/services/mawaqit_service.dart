import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/prayer_engine.dart';

enum MawaqitStatus { disabled, loading, ok, error }

class MawaqitSchedule {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime? jumua;
  final DateTime date;

  const MawaqitSchedule({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    this.jumua,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  PrayerSchedule toPrayerSchedule({
    bool isJumuah = false,
    DateTime? jumuahFallback,
  }) {
    final jumuahTime =
        (isJumuah && jumua != null) ? jumua! : (jumuahFallback ?? dhuhr);
    return PrayerSchedule(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: isJumuah ? jumuahTime : dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      isJumuah: isJumuah,
    );
  }

  // -------------------------------------------------------------------------
  // Sérialisation / désérialisation
  // -------------------------------------------------------------------------

  static MawaqitSchedule? _fromApiJson(Map<String, dynamic> json) {
    try {
      final rawTimes = json['times'];
      if (rawTimes == null || rawTimes is! List || rawTimes.length < 6) {
        return null;
      }
      final times = rawTimes.map((t) => t.toString()).toList();
      final today = DateTime.now();

      DateTime t(String hm) {
        final p = hm.split(':');
        return DateTime(today.year, today.month, today.day,
            int.parse(p[0]), int.parse(p[1]));
      }

      // Mawaqit utilise "jumua" ou "jumuaTime" selon la version de l'API.
      final jumuaRaw =
          (json['jumua'] as String?) ?? (json['jumuaTime'] as String?);

      return MawaqitSchedule(
        fajr: t(times[0]),
        sunrise: t(times[1]),
        dhuhr: t(times[2]),
        asr: t(times[3]),
        maghrib: t(times[4]),
        isha: t(times[5]),
        jumua: (jumuaRaw != null && jumuaRaw.isNotEmpty) ? t(jumuaRaw) : null,
        date: today,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return {
      'times': [
        fmt(fajr),
        fmt(sunrise),
        fmt(dhuhr),
        fmt(asr),
        fmt(maghrib),
        fmt(isha),
      ],
      if (jumua != null) 'jumua': fmt(jumua!),
      '_date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
  }

  static MawaqitSchedule? fromCacheJson(Map<String, dynamic> json) {
    try {
      final dateStr = json['_date'] as String?;
      if (dateStr == null) return null;
      final date = DateTime.parse(dateStr);
      final rawTimes = (json['times'] as List).cast<String>();

      DateTime t(String hm) {
        final p = hm.split(':');
        return DateTime(
            date.year, date.month, date.day, int.parse(p[0]), int.parse(p[1]));
      }

      final jumuaRaw = json['jumua'] as String?;
      return MawaqitSchedule(
        fajr: t(rawTimes[0]),
        sunrise: t(rawTimes[1]),
        dhuhr: t(rawTimes[2]),
        asr: t(rawTimes[3]),
        maghrib: t(rawTimes[4]),
        isha: t(rawTimes[5]),
        jumua: jumuaRaw != null ? t(jumuaRaw) : null,
        date: date,
      );
    } catch (_) {
      return null;
    }
  }
}

// =============================================================================
// MawaqitService : récupère les horaires depuis l'API Mawaqit + cache local.
//
// Endpoint utilisé : GET https://mawaqit.net/api/2.0/mosque/{slug}/times
// Le cache est stocké dans SharedPreferences, une entrée par jour et par slug.
// Si la réponse API est invalide ou le réseau indisponible, on retourne null
// → le PrayerProvider bascule automatiquement sur le calcul local (PrayerEngine).
// =============================================================================
class MawaqitService {
  static const _baseUrl = 'https://mawaqit.net/api/2.0/mosque';
  static const _cachePrefKey = 'mawaqit_cache_';

  Future<MawaqitSchedule?> fetchTimes(String slug) async {
    final cached = await _loadCache(slug);
    if (cached != null && cached.isToday) return cached;

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$slug/times'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final schedule = MawaqitSchedule._fromApiJson(data);
      if (schedule != null) await _saveCache(slug, schedule);
      return schedule;
    } catch (_) {
      return null;
    }
  }

  Future<MawaqitSchedule?> _loadCache(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefKey$slug');
    if (raw == null) return null;
    try {
      return MawaqitSchedule.fromCacheJson(
          json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(String slug, MawaqitSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefKey$slug', json.encode(schedule.toJson()));
  }
}

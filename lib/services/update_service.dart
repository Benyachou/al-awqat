import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String? apkDownloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.apkDownloadUrl,
    required this.releaseNotes,
  });

  bool get hasUpdate => _isNewer(latestVersion, currentVersion);

  static bool _isNewer(String latest, String current) {
    final l = _parseVersion(latest);
    final c = _parseVersion(current);
    for (var i = 0; i < l.length || i < c.length; i++) {
      final lp = i < l.length ? l[i] : 0;
      final cp = i < c.length ? c[i] : 0;
      if (lp > cp) return true;
      if (lp < cp) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    return v
        .replaceAll(RegExp(r'^v'), '')
        .split('.')
        .map((s) => int.tryParse(RegExp(r'\d+').stringMatch(s) ?? '') ?? 0)
        .toList();
  }
}

/// Inspired by simple update-check patterns: hit GitHub's releases API,
/// compare semver, return info. The user (or a future scheduler) decides
/// when to call this — typically once per day on app start when online.
class UpdateService {
  /// repoSlug: "owner/repo" (e.g. "yassine/al-awqat").
  Future<UpdateInfo?> checkLatestRelease(String repoSlug) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$repoSlug/releases/latest',
    );
    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name']?.toString() ?? '';
      final htmlUrl = json['html_url']?.toString() ?? '';
      final body = json['body']?.toString() ?? '';
      final assets = (json['assets'] as List?) ?? const [];
      String? apkUrl;
      for (final asset in assets) {
        final name = asset['name']?.toString() ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = asset['browser_download_url']?.toString();
          break;
        }
      }

      final info = await PackageInfo.fromPlatform();
      return UpdateInfo(
        currentVersion: info.version,
        latestVersion: tag,
        releaseUrl: htmlUrl,
        apkDownloadUrl: apkUrl,
        releaseNotes: body,
      );
    } catch (_) {
      return null;
    }
  }
}

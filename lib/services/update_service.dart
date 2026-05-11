// =============================================================================
// UpdateService : vérifie la dernière release GitHub et compare les versions.
//
// Workflow :
//   1. L'utilisateur saisit "owner/repo" dans Paramètres → Mises à jour.
//   2. L'app interroge https://api.github.com/repos/owner/repo/releases/latest
//   3. Compare la version actuelle (depuis pubspec.yaml via package_info_plus)
//      avec le tag de la release.
//   4. Si une .apk est attachée à la release, on garde son URL pour le
//      bouton "Télécharger APK" (sinon on tombe sur la page release).
//
// L'app fonctionne sans : si pas de repo configuré ou pas de réseau,
// rien ne se passe — pas de crash, pas de badge.
// =============================================================================

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Résultat d'un check : versions, URL de la release, URL de l'APK si fourni.
class UpdateInfo {
  /// Version installée localement (depuis pubspec.yaml).
  final String currentVersion;
  /// Tag de la dernière release GitHub (ex: "v1.2.0").
  final String latestVersion;
  /// URL HTML de la page release (fallback si pas d'APK).
  final String releaseUrl;
  /// URL directe du .apk si la release en contient un.
  final String? apkDownloadUrl;
  /// Description Markdown de la release (notes de version).
  final String releaseNotes;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.apkDownloadUrl,
    required this.releaseNotes,
  });

  /// True si latest > current. Pilote l'affichage du badge orange.
  bool get hasUpdate => isNewer(latestVersion, currentVersion);

  /// Compare deux versions style "1.2.3" ou "v1.2.3-beta".
  /// Statique pour faciliter les tests.
  ///
  /// Algorithme : on parse en liste d'entiers (parseVersion), puis on
  /// compare composant par composant. Tout ce qui n'est pas un nombre
  /// est considéré comme 0 (donc "1.2.3-beta" == "1.2.3" — discutable
  /// mais suffisant pour notre cas où les release tags sont propres).
  static bool isNewer(String latest, String current) {
    final l = parseVersion(latest);
    final c = parseVersion(current);
    for (var i = 0; i < l.length || i < c.length; i++) {
      final lp = i < l.length ? l[i] : 0;
      final cp = i < c.length ? c[i] : 0;
      if (lp > cp) return true;
      if (lp < cp) return false;
    }
    return false;
  }

  /// "v1.2.3" → [1, 2, 3]. Retire le préfixe "v" et tout ce qui n'est
  /// pas numérique. "1.2.3-rc1" → [1, 2, 3] (le -rc1 est ignoré).
  static List<int> parseVersion(String v) {
    return v
        .replaceAll(RegExp(r'^v'), '')
        .split('.')
        .map((s) => int.tryParse(RegExp(r'\d+').stringMatch(s) ?? '') ?? 0)
        .toList();
  }
}

/// Service réseau côté update. Stateless : peut être instancié et appelé
/// à la volée. Le PrayerProvider en garde une instance pour réutiliser.
class UpdateService {
  /// Interroge GitHub pour la dernière release de [repoSlug].
  /// Format attendu : "owner/repo" (ex : "yassine/al-awqat").
  /// Renvoie null en cas de problème (404, réseau, JSON invalide…).
  Future<UpdateInfo?> checkLatestRelease(String repoSlug) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$repoSlug/releases/latest',
    );
    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      // 404 = pas de release, 403 = rate limit, etc.
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name']?.toString() ?? '';
      final htmlUrl = json['html_url']?.toString() ?? '';
      final body = json['body']?.toString() ?? '';
      final assets = (json['assets'] as List?) ?? const [];

      // Cherche un asset .apk attaché à la release pour le bouton direct.
      String? apkUrl;
      for (final asset in assets) {
        final name = asset['name']?.toString() ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = asset['browser_download_url']?.toString();
          break;
        }
      }

      // Version locale lue dans pubspec.yaml (via package_info_plus).
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

  /// Ouvre une URL externe (navigateur par défaut sur Android, application
  /// associée sur autres plateformes). Utilisé pour le bouton "Télécharger APK".
  /// Renvoie false si l'URL est invalide ou si aucune app ne peut l'ouvrir.
  Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

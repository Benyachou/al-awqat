// =============================================================================
// GeocodingService : recherche de villes en ligne via OpenStreetMap.
//
// Utilisé UNIQUEMENT depuis le dialog "Chercher une autre ville" dans
// les Paramètres. Le reste de l'app fonctionne 100 % offline.
//
// API : Nominatim (https://nominatim.openstreetmap.org), libre et sans clé.
// Limitations :
//   - 1 requête/seconde max (CGU). On ne lance qu'une recherche par submit
//     utilisateur, donc on respecte naturellement.
//   - User-Agent obligatoire — sans, l'API renvoie 403.
//   - Pas de service garanti, on peut tomber en panne. D'où le try/catch
//     qui renvoie [] plutôt que de propager une exception.
// =============================================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Un résultat de recherche Nominatim : libellé long + coordonnées.
class GeocodingResult {
  /// Adresse complète retournée par OSM (ex : "Lille, Nord, Hauts-de-France,
  /// France métropolitaine, France"). Affichée tel quel dans la liste.
  final String displayName;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

/// Wrapper autour de l'API Nominatim. Pas d'état, méthode unique `search`.
class GeocodingService {
  /// User-Agent identifiant l'app — Nominatim refuse les requêtes anonymes.
  static const _userAgent = 'AlAwqat/1.0 (offline prayer times app)';

  /// Lance une recherche. Retourne jusqu'à 8 résultats triés par pertinence
  /// OSM, ou [] en cas de problème réseau / aucun résultat / requête vide.
  Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().isEmpty) return const [];

    // Note : `addressdetails=0` allège la réponse JSON — on ne veut que
    // le display_name complet et les coordonnées, pas le détail rue/code postal.
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '8',
      'addressdetails': '0',
    });
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) {
        final m = e as Map<String, dynamic>;
        return GeocodingResult(
          displayName: m['display_name']?.toString() ?? query,
          // Nominatim renvoie lat/lon comme strings, d'où le double.tryParse.
          latitude: double.tryParse(m['lat']?.toString() ?? '') ?? 0,
          longitude: double.tryParse(m['lon']?.toString() ?? '') ?? 0,
        );
      }).toList();
    } catch (_) {
      // Timeout, DNS échec, JSON malformé… on renvoie liste vide et l'UI
      // affiche "Aucun résultat (réseau ?)".
      return const [];
    }
  }
}

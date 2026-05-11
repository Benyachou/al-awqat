// =============================================================================
// QiblaService : calcule la direction de la Kaaba depuis n'importe quel point.
//
// Algorithme : formule de l'azimut grand-cercle (great-circle bearing) —
// la même que pour une trajectoire d'avion. Pas une ligne droite sur
// une carte plate, mais la trajectoire la plus courte à la surface
// d'une sphère. C'est la méthode standard utilisée par toutes les apps
// Qibla pour rester précis quel que soit l'éloignement.
//
// Tout est `static` : pas d'instance, pas d'état. Importe juste et appelle
// QiblaService.bearingFrom(lat, lng).
// =============================================================================

import 'dart:math' as math;

class QiblaService {
  /// Coordonnées de la Kaaba à La Mecque (centre de la Mosquée Sacrée).
  /// Source : Wikipédia / Google Maps. Précision suffisante (~10 m).
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  /// Azimut en degrés (0 = nord géographique, sens horaire) depuis (lat, lng)
  /// vers la Kaaba. Exemples connus :
  ///   - Paris (48.85, 2.35)   → ~119° (sud-est)
  ///   - New York (40.7, -74)  → ~58°  (nord-est)
  ///   - Médine (24.52, 39.57) → ~180° (presque plein sud)
  ///   - Le Cap (-33.92, 18.42) → ~34° (nord-nord-est)
  ///
  /// Formule : atan2(sin(Δλ)·cos(φ2), cos(φ1)·sin(φ2) - sin(φ1)·cos(φ2)·cos(Δλ))
  /// où φ = latitude, λ = longitude, Δλ = différence de longitude.
  static double bearingFrom(double lat, double lng) {
    final phi1 = _toRad(lat);
    final phi2 = _toRad(kaabaLat);
    final deltaLambda = _toRad(kaabaLng - lng);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final bearing = math.atan2(y, x);
    // Normalise dans [0, 360) — atan2 renvoie [-π, π].
    return (_toDeg(bearing) + 360) % 360;
  }

  /// Distance grand-cercle (km) entre (lat, lng) et la Kaaba.
  /// Formule de Haversine. Rayon terrestre moyen = 6371 km.
  /// Précision ~0.5 % (la Terre n'est pas une sphère parfaite).
  static double distanceKmFrom(double lat, double lng) {
    const earthRadius = 6371.0;
    final phi1 = _toRad(lat);
    final phi2 = _toRad(kaabaLat);
    final dPhi = _toRad(kaabaLat - lat);
    final dLambda = _toRad(kaabaLng - lng);

    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Helpers degrés ↔ radians (dart:math travaille en radians).
  static double _toRad(double deg) => deg * math.pi / 180;
  static double _toDeg(double rad) => rad * 180 / math.pi;
}

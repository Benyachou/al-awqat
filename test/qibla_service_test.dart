import 'package:al_awqat/services/qibla_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Qibla depuis La Mecque ≈ 0 km de distance', () {
    final d = QiblaService.distanceKmFrom(
        QiblaService.kaabaLat, QiblaService.kaabaLng);
    expect(d, closeTo(0, 0.5));
  });

  test('Qibla depuis Paris pointe SE (≈ 119°)', () {
    final b = QiblaService.bearingFrom(48.8566, 2.3522);
    expect(b, closeTo(119, 2));
  });

  test('Qibla depuis Médine pointe SO (≈ 176°)', () {
    final b = QiblaService.bearingFrom(24.5247, 39.5692);
    // Médine est presque pile au nord de la Mecque, donc bearing ≈ 180°.
    expect(b, closeTo(180, 5));
  });

  test('Distance Paris → Mecque ≈ 4500 km', () {
    final d = QiblaService.distanceKmFrom(48.8566, 2.3522);
    expect(d, closeTo(4500, 100));
  });
}

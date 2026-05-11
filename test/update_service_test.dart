import 'package:al_awqat/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateInfo.isNewer', () {
    test('1.0.1 > 1.0.0', () {
      expect(UpdateInfo.isNewer('1.0.1', '1.0.0'), isTrue);
    });

    test('1.0.0 == 1.0.0', () {
      expect(UpdateInfo.isNewer('1.0.0', '1.0.0'), isFalse);
    });

    test('v2.1.0 > 2.0.5', () {
      expect(UpdateInfo.isNewer('v2.1.0', '2.0.5'), isTrue);
    });

    test('1.0 == 1.0.0', () {
      expect(UpdateInfo.isNewer('1.0', '1.0.0'), isFalse);
    });

    test('1.0.0-beta < 1.0.0', () {
      expect(UpdateInfo.isNewer('1.0.0-beta', '1.0.0'), isFalse);
    });

    test('parseVersion gère le préfixe v et les suffixes', () {
      expect(UpdateInfo.parseVersion('v1.2.3'), [1, 2, 3]);
      expect(UpdateInfo.parseVersion('1.2.3-rc1'), [1, 2, 3]);
    });
  });
}

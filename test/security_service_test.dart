import 'package:flutter_test/flutter_test.dart';
import 'package:medhistory/core/security/security_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityService Tests', () {
    late SecurityService securityService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      securityService = SecurityService();
    });

    test('getOrCreateDatabaseKey generates 256-bit hex key and reuses it', () async {
      final key1 = await securityService.getOrCreateDatabaseKey();
      expect(key1, isNotEmpty);
      expect(key1.length, equals(64)); // 32 bytes en hex = 64 caractères

      final key2 = await securityService.getOrCreateDatabaseKey();
      expect(key2, equals(key1));
    });

    test('setPin and verifyPin work accurately', () async {
      expect(await securityService.hasPin(), isFalse);

      await securityService.setPin('123456');
      expect(await securityService.hasPin(), isTrue);

      expect(await securityService.verifyPin('123456'), isTrue);
      expect(await securityService.verifyPin('000000'), isFalse);
    });

    test('setBiometricsEnabled and isBiometricsEnabled work as expected', () async {
      expect(await securityService.isBiometricsEnabled(), isFalse);

      await securityService.setBiometricsEnabled(true);
      expect(await securityService.isBiometricsEnabled(), isTrue);

      await securityService.setBiometricsEnabled(false);
      expect(await securityService.isBiometricsEnabled(), isFalse);
    });
  });
}

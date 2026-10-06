import 'package:flutter_test/flutter_test.dart';
import 'package:medhistory/features/auth/domain/auth_controller.dart';
import 'package:medhistory/core/security/security_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController Lifecycle and Grace Period Tests', () {
    late SecurityService securityService;
    late AuthController authController;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      securityService = SecurityService();
      authController = AuthController(securityService: securityService);
    });

    tearDown(() {
      authController.dispose();
    });

    test('Initial state is unconfigured when no PIN set', () async {
      await authController.checkInitialState();
      expect(authController.debugState.status, equals(AuthStatus.unconfigured));
    });

    test('setupPin configures PIN and sets status to authenticated', () async {
      final success = await authController.setupPin('123456');
      expect(success, isTrue);
      expect(authController.debugState.status, equals(AuthStatus.authenticated));
    });

    test('App lifecycle within grace period keeps user authenticated', () async {
      await authController.setupPin('123456');

      // Pause app
      authController.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(authController.debugState.status, equals(AuthStatus.authenticated));

      // Resume app instantly (< 2 minutes)
      authController.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(authController.debugState.status, equals(AuthStatus.authenticated));
    });
  });
}

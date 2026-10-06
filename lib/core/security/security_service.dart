import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Service gérant la clé de chiffrement du coffre-fort SQLCipher,
/// le stockage sécurisé du PIN et l'authentification biométrique.
class SecurityService {
  static const String _dbKeyStorageKey = 'medhistory_db_encryption_key_v1';
  static const String _pinHashKey = 'medhistory_user_pin_hash_v1';
  static const String _pinSaltKey = 'medhistory_user_pin_salt_v1';
  static const String _biometricsEnabledKey = 'medhistory_biometrics_enabled_v1';

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  SecurityService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Récupère ou génère une clé aléatoire de 256 bits (32 octets) codée en Hex.
  Future<String> getOrCreateDatabaseKey() async {
    try {
      String? existingKey = await _secureStorage.read(key: _dbKeyStorageKey);
      if (existingKey != null && existingKey.isNotEmpty) {
        return existingKey;
      }

      final random = Random.secure();
      final keyBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        keyBytes[i] = random.nextInt(256);
      }

      final newKey = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _secureStorage.write(key: _dbKeyStorageKey, value: newKey);
      return newKey;
    } catch (e) {
      throw Exception('Erreur lors de la récupération/génération de la clé cryptographique: $e');
    }
  }

  /// Vérifie si un code PIN a déjà été configuré.
  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Définit un nouveau code PIN en le hachant avec un sel aléatoire (SHA-256).
  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('Le code PIN doit contenir au moins 4 chiffres.');
    }
    final random = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    final saltHex = saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    final hash = _hashPinWithSalt(pin, saltHex);

    await _secureStorage.write(key: _pinSaltKey, value: saltHex);
    await _secureStorage.write(key: _pinHashKey, value: hash);
  }

  /// Valide la saisie du code PIN.
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final storedSalt = await _secureStorage.read(key: _pinSaltKey);

    if (storedHash == null || storedSalt == null) {
      return false;
    }

    final computedHash = _hashPinWithSalt(pin, storedSalt);
    return computedHash == storedHash;
  }

  /// Active ou désactive la biométrie.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricsEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Vérifie si la biométrie est activée pour l'utilisateur.
  Future<bool> isBiometricsEnabled() async {
    final value = await _secureStorage.read(key: _biometricsEnabledKey);
    return value == 'true';
  }

  /// Vérifie si l'appareil prend en charge la biométrie.
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Déclenche l'authentification par biométrie (Empreinte / FaceID).
  Future<bool> authenticateWithBiometrics({
    String localizedReason = 'Veuillez vous authentifier pour accéder à MedHistory',
  }) async {
    try {
      if (!await isBiometricsAvailable()) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  String _hashPinWithSalt(String pin, String saltHex) {
    final bytes = utf8.encode('$pin:$saltHex');
    return sha256.convert(bytes).toString();
  }
}

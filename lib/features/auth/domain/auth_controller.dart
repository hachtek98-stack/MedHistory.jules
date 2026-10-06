import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/security_service.dart';

enum AuthStatus {
  initial,
  unconfigured, // Premier lancement : aucun PIN configuré
  locked,       // PIN configuré, écran de déverrouillage actif
  authenticated,// Utilisateur authentifié avec succès
}

class AuthState {
  final AuthStatus status;
  final DateTime? lastActiveTime;
  final String? errorMessage;
  final bool isBiometricsAvailable;

  AuthState({
    required this.status,
    this.lastActiveTime,
    this.errorMessage,
    this.isBiometricsAvailable = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    DateTime? lastActiveTime,
    String? errorMessage,
    bool? isBiometricsAvailable,
  }) {
    return AuthState(
      status: status ?? this.status,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      errorMessage: errorMessage,
      isBiometricsAvailable: isBiometricsAvailable ?? this.isBiometricsAvailable,
    );
  }
}

class AuthController extends StateNotifier<AuthState> with WidgetsBindingObserver {
  final SecurityService _securityService;
  static const Duration gracePeriod = Duration(minutes: 2);

  AuthController({SecurityService? securityService})
      : _securityService = securityService ?? SecurityService(),
        super(AuthState(status: AuthStatus.initial)) {
    WidgetsBinding.instance.addObserver(this);
    checkInitialState();
  }

  /// Vérifie l'état d'authentification initial au démarrage.
  Future<void> checkInitialState() async {
    final hasPin = await _securityService.hasPin();
    final biometricsAvailable = await _securityService.isBiometricsAvailable();

    if (!hasPin) {
      state = state.copyWith(
        status: AuthStatus.unconfigured,
        isBiometricsAvailable: biometricsAvailable,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.locked,
        isBiometricsAvailable: biometricsAvailable,
      );
    }
  }

  /// Configure un nouveau PIN lors de la première utilisation.
  Future<bool> setupPin(String pin, {bool enableBiometrics = false}) async {
    try {
      if (pin.length < 4) {
        state = state.copyWith(errorMessage: 'Le PIN doit comporter au moins 4 chiffres');
        return false;
      }
      await _securityService.setPin(pin);
      if (enableBiometrics) {
        await _securityService.setBiometricsEnabled(true);
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        lastActiveTime: DateTime.now(),
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erreur lors de la configuration du PIN: $e');
      return false;
    }
  }

  /// Tente de déverrouiller l'application avec le PIN saisi.
  Future<bool> unlockWithPin(String pin) async {
    final isValid = await _securityService.verifyPin(pin);
    if (isValid) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        lastActiveTime: DateTime.now(),
        errorMessage: null,
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Code PIN incorrect');
      return false;
    }
  }

  /// Tente de déverrouiller l'application via biométrie.
  Future<bool> unlockWithBiometrics() async {
    final isBiometricsEnabled = await _securityService.isBiometricsEnabled();
    if (!isBiometricsEnabled) {
      state = state.copyWith(errorMessage: 'La biométrie n\'est pas activée');
      return false;
    }

    final success = await _securityService.authenticateWithBiometrics(
      localizedReason: 'Déverrouillez MedHistory avec votre empreinte ou visage',
    );

    if (success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        lastActiveTime: DateTime.now(),
        errorMessage: null,
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Échec de l\'authentification biométrique');
      return false;
    }
  }

  /// Verrouille manuellement l'application.
  void lock() {
    state = state.copyWith(status: AuthStatus.locked);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (state.status != AuthStatus.authenticated) return;

    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      state = state.copyWith(lastActiveTime: DateTime.now());
    } else if (lifecycleState == AppLifecycleState.resumed) {
      final lastActive = state.lastActiveTime;
      if (lastActive != null) {
        final elapsed = DateTime.now().difference(lastActive);
        if (elapsed > gracePeriod) {
          lock();
        } else {
          state = state.copyWith(lastActiveTime: DateTime.now());
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final securityService = ref.watch(securityServiceProvider);
  return AuthController(securityService: securityService);
});

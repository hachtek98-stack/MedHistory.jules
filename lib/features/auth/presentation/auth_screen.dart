import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_controller.dart';

/// Écran d'authentification et de configuration PIN conforme aux normes seniors (min 56dp).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirmingStep = false;
  bool _enableBiometrics = true;

  void _onNumberClick(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
      });
    }
  }

  void _onDeleteClick() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _onSubmit(AuthState authState, AuthController authController) async {
    if (authState.status == AuthStatus.unconfigured) {
      if (!_isConfirmingStep) {
        if (_enteredPin.length < 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le code PIN doit contenir au moins 4 chiffres.')),
          );
          return;
        }
        setState(() {
          _confirmPin = _enteredPin;
          _enteredPin = '';
          _isConfirmingStep = true;
        });
      } else {
        if (_enteredPin != _confirmPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Les codes PIN ne correspondent pas. Recommencez.')),
          );
          setState(() {
            _enteredPin = '';
            _confirmPin = '';
            _isConfirmingStep = false;
          });
          return;
        }
        await authController.setupPin(
          _enteredPin,
          enableBiometrics: _enableBiometrics,
        );
      }
    } else if (authState.status == AuthStatus.locked) {
      final success = await authController.unlockWithPin(_enteredPin);
      if (!success) {
        setState(() {
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    final isSetup = authState.status == AuthStatus.unconfigured;

    String title;
    if (isSetup) {
      title = _isConfirmingStep
          ? 'Confirmez votre code PIN'
          : 'Créez votre code PIN de sécurité';
    } else {
      title = 'Déverrouiller le coffre-fort MedHistory';
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text('MedHistory - Sécurité'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (isSetup)
                const Text(
                  'Ce code permettra d\'accéder à vos données médicales chiffrées en toute sécurité.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Affichage visuel du PIN (masqué)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final filled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              if (isSetup && !_isConfirmingStep)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _enableBiometrics,
                      onChanged: (val) {
                        setState(() {
                          _enableBiometrics = val ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Activer l\'empreinte / FaceID',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              const Spacer(),
              // Clavier numérique tactile Senior (minimum 56 x 56 dp)
              _buildNumpad(authState, authController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(AuthState authState, AuthController authController) {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((num) => _buildNumpadButton(num)).toList(),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bouton Biométrie ou Effacer
            if (authState.status == AuthStatus.locked && authState.isBiometricsAvailable)
              SizedBox(
                width: 72,
                height: 72,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => authController.unlockWithBiometrics(),
                  child: const Icon(Icons.fingerprint, size: 36),
                ),
              )
            else
              const SizedBox(width: 72, height: 72),

            _buildNumpadButton('0'),

            SizedBox(
              width: 72,
              height: 72,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  shape: const CircleBorder(),
                ),
                onPressed: _onDeleteClick,
                child: const Icon(Icons.backspace_outlined, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56, // Respect strict de la norme 56px senior
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _enteredPin.isNotEmpty
                ? () => _onSubmit(authState, authController)
                : null,
            child: Text(
              authState.status == AuthStatus.unconfigured
                  ? (_isConfirmingStep ? 'VALIDER LE PIN' : 'SUIVANT')
                  : 'DÉVERROUILLER',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumpadButton(String number) {
    return SizedBox(
      width: 72,
      height: 72, // Target tactile 72x72 (>56x56) pour confort senior optimal
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          elevation: 2,
        ),
        onPressed: () => _onNumberClick(number),
        child: Text(
          number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

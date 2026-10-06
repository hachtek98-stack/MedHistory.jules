import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/domain/auth_controller.dart';
import 'features/auth/presentation/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MedHistoryApp(),
    ),
  );
}

class MedHistoryApp extends ConsumerWidget {
  const MedHistoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'MedHistory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F52BA), // Bleu médical professionnel
          brightness: Brightness.light,
        ),
        // Accessibilité Senior : Dynamic Type support & contraste élevé
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthStatus.unconfigured:
      case AuthStatus.locked:
        return const AuthScreen();
      case AuthStatus.authenticated:
        return const HomeScreen();
    }
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedHistory - Coffre-fort'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, size: 28),
            tooltip: 'Verrouiller',
            onPressed: () {
              ref.read(authControllerProvider.notifier).lock();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.green.shade50,
                elevation: 2,
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.green, size: 40),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Coffre-fort local chiffré (AES-256) actif',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bienvenue dans MedHistory',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vos données médicales sont sécurisées sur cet appareil.',
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              SizedBox(
                height: 56, // Senior size
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  label: const Text('NOUVELLE CONSULTATION', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    // Action consultation (Sprint 2)
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

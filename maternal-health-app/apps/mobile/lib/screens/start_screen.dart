import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_config.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return Scaffold(
        body: Center(
          child: _WelcomeShell(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _BrandMark(icon: Icons.cloud_outlined),
              const SizedBox(height: 24),
              Text('Connect your account', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text('Add your Supabase project URL and public key to the .env file, then restart the app.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
        ),
      );
    }

    final user = Supabase.instance.client.auth.currentSession?.user;

    if (user != null) {
      // User is already authenticated, go to role selection
      return const RoleSelectionScreen();
    }

    // Show the welcome screen to unauthenticated users.
    return Scaffold(
      body: _WelcomeShell(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _BrandMark(icon: Icons.spa_outlined),
          const SizedBox(height: 32),
          Text('MatruCare', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('A little more support for every step.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Get started'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Pregnancy and postpartum care, made personal.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
    );
  }
}

class _WelcomeShell extends StatelessWidget {
  final Widget child;
  const _WelcomeShell({required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(padding: const EdgeInsets.all(30), child: child),
              ),
            ),
          ),
        ),
      );
}

class _BrandMark extends StatelessWidget {
  final IconData icon;
  const _BrandMark({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(color: const Color(0xFFF1E8ED), borderRadius: BorderRadius.circular(24)),
        child: Icon(icon, color: const Color(0xFF70445E), size: 30),
      );
}

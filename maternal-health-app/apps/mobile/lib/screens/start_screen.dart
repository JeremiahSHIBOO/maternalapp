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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.cloud_off, size: 56, color: Color(0xFF880E4F)),
              SizedBox(height: 16),
              Text('Connect Supabase to start', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Run the app with SUPABASE_URL and SUPABASE_ANON_KEY dart defines. See README.md.'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star,
              size: 100,
              color: Color(0xFF880E4F),
            ),
            const SizedBox(height: 24),
            const Text(
              'MatruCare',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF880E4F),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pregnancy & Postpartum Companion',
              style: TextStyle(fontSize: 16, color: Color(0xFFAD1457)),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                // Go to login/signup
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ));
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

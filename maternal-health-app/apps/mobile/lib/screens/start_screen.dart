import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final supabase = Supabase.instance.client;
    final user = supabase.auth.getSession().user;

    if (user != null) {
      // User is already authenticated, go to role selection
      return const MaterialApp(home: RoleSelectionScreen());
    }

    // Show role selection for new users
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
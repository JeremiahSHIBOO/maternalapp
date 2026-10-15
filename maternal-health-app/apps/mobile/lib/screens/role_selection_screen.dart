import 'package:flutter/material.dart';
import 'screens/mother_home_screen.dart';
import 'screens/partner_home_screen.dart';
import 'screens/doctor_portal_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person,
              size: 100,
              color: Color(0xFF880E4F),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Your Role',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF880E4F),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'MatruCare Platform',
              style: TextStyle(fontSize: 16, color: Color(0xFFAD1457)),
            ),
            const SizedBox(height: 48),
            _buildRoleCard(
              context,
              '🤰 Mother',
              'Track pregnancy, baby growth, and wellbeing',
              Colors.pink[100]!,
              Colors.pink[300]!,
              () => Navigator.pushNamed(context, '/mother-home'),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              '👨‍💼 Partner',
              'Family support, tasks, and expenses',
              Color(0xFFE8F5E9),
              Color(0xFFA5D6A7),
              () => Navigator.pushNamed(context, '/partner-home'),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              '🩺 Doctor',
              'Clinical dashboard and patient records',
              Color(0xFFE3F2FD),
              Color(0xBBDEFB),
              () => Navigator.pushNamed(context, '/doctor-portal'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Already have an account?',
              style: TextStyle(fontSize: 12, color: Color(0xFF880E4F)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String title,
    String subtitle,
    Color backgroundColor,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF880E4F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
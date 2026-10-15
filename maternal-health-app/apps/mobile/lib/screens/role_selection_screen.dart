import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _savingRole = false;

  Future<void> _selectRole(String role, String route) async {
    if (_savingRole) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    setState(() => _savingRole = true);
    try {
      await Supabase.instance.client.from('profiles').update({'role': role}).eq('id', user.id);
      if (role == 'mother') {
        await Supabase.instance.client.from('pregnancy_profiles').upsert(
          {'user_id': user.id},
          onConflict: 'user_id',
        );
      }
      if (mounted) Navigator.pushReplacementNamed(context, route);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save your role: $error')));
    } finally {
      if (mounted) setState(() => _savingRole = false);
    }
  }

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
            if (_savingRole) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
            const SizedBox(height: 48),
            _buildRoleCard(
              context,
              '🤰 Mother',
              'Track pregnancy, baby growth, and wellbeing',
              Colors.pink[100]!,
              Colors.pink[300]!,
              () => _selectRole('mother', '/mother-home'),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              '👨‍💼 Partner',
              'Partner dashboard; shared records are not set up yet',
              Color(0xFFE8F5E9),
              Color(0xFFA5D6A7),
              () => _selectRole('partner', '/partner-home'),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              '🩺 Doctor',
              'Clinician dashboard; patient assignments are not set up yet',
              Color(0xFFE3F2FD),
              Color(0xBBDEFB),
              () => _selectRole('doctor', '/doctor-portal'),
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

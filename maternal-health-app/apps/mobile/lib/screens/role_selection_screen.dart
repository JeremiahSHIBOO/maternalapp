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
      if (mounted) {
        // Keep the signed-in flow as the root of the navigation stack so
        // Back from a dashboard cannot reveal the welcome screen.
        Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save your role: $error')));
    } finally {
      if (mounted) setState(() => _savingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PERSONALISE YOUR SPACE', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4, color: const Color(0xFF789080), fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('How will you use MatruCare?', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Choose the experience that fits you. You can change this later.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 28),
                _buildRoleCard(context, Icons.favorite_outline, 'Mother', 'Pregnancy, baby growth and wellbeing', () => _selectRole('mother', '/mother-home')),
                const SizedBox(height: 12),
                _buildRoleCard(context, Icons.people_outline, 'Partner', 'Support and shared family care', () => _selectRole('partner', '/partner-home')),
                const SizedBox(height: 12),
                _buildRoleCard(context, Icons.medical_services_outlined, 'Doctor', 'Clinical care and patient overview', () => _selectRole('doctor', '/doctor-portal')),
                if (_savingRole) const Padding(padding: EdgeInsets.only(top: 24), child: Center(child: CircularProgressIndicator())),
                const SizedBox(height: 20),
                Center(child: TextButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Use a different account'))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _savingRole ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF1E8ED), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: const Color(0xFF70445E))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)])),
            const Icon(Icons.arrow_forward_ios, size: 15, color: Color(0xFF968B92)),
          ]),
        ),
      ),
    );
  }
}

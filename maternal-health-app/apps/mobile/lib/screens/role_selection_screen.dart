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
      await Supabase.instance.client
          .from('profiles')
          .update({'role': role}).eq('id', user.id);
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save your role: $error')));
    } finally {
      if (mounted) setState(() => _savingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: LayoutBuilder(builder: (context, viewport) {
        final compact = viewport.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 18 : 36, vertical: compact ? 24 : 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1020),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF3E8ED),
                              borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.spa_outlined,
                              color: Color(0xFF70445E), size: 24)),
                      const SizedBox(width: 12),
                      Text('MatruCare',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 20)),
                    ]),
                    SizedBox(height: compact ? 34 : 56),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                          compact ? 22 : 32,
                          compact ? 22 : 28,
                          compact ? 22 : 32,
                          compact ? 22 : 28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF8EEF1), Color(0xFFF5F1ED)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR CARE SPACE',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: const Color(0xFF806276),
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Text('Choose the role that fits you.',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontSize: compact ? 26 : 32)),
                            const SizedBox(height: 8),
                            Text(
                                'We’ll shape your MatruCare space around the support you need.',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ]),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, content) {
                      final tiles = content.maxWidth >= 640;
                      final roleCards = [
                        _buildRoleCard(
                            context,
                            Icons.favorite_outline,
                            'Mother',
                            'Pregnancy, baby growth and wellbeing',
                            const Color(0xFF70445E),
                            tiles,
                            () => _selectRole('mother', '/mother-home')),
                        _buildRoleCard(
                            context,
                            Icons.people_outline,
                            'Partner',
                            'Support and shared family care',
                            const Color(0xFF718979),
                            tiles,
                            () => _selectRole('partner', '/partner-home')),
                        _buildRoleCard(
                            context,
                            Icons.medical_services_outlined,
                            'Doctor',
                            'Clinical care and patient overview',
                            const Color(0xFF9A6E61),
                            tiles,
                            () => _selectRole('doctor', '/doctor-portal')),
                      ];
                      if (tiles) {
                        return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < roleCards.length; i++) ...[
                                if (i > 0) const SizedBox(width: 14),
                                Expanded(child: roleCards[i]),
                              ],
                            ]);
                      }
                      return Column(children: [
                        roleCards[0],
                        const SizedBox(height: 12),
                        roleCards[1],
                        const SizedBox(height: 12),
                        roleCards[2],
                      ]);
                    }),
                    if (_savingRole)
                      const Padding(
                          padding: EdgeInsets.only(top: 22),
                          child: Center(child: CircularProgressIndicator())),
                    const SizedBox(height: 20),
                    Center(
                        child: Text(
                            'Your role controls which care tools you see. You can change it later.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall)),
                    const SizedBox(height: 8),
                    Center(
                        child: TextButton(
                            onPressed: _savingRole
                                ? null
                                : () => Navigator.pushNamed(context, '/login'),
                            child: const Text('Use a different account'))),
                  ]),
            ),
          ),
        );
      })),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color accent,
    bool tile,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _savingRole ? null : onTap,
        child: Padding(
          padding: EdgeInsets.all(tile ? 20 : 16),
          child: tile
              ? SizedBox(
                  height: 172,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                  color: accent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Icon(icon, color: accent, size: 27)),
                          const Spacer(),
                          Icon(Icons.arrow_outward_rounded,
                              color: accent.withOpacity(0.75), size: 20),
                        ]),
                        const SizedBox(height: 16),
                        Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 19)),
                        const SizedBox(height: 6),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Row(children: [
                          Text('Continue as ${title.toLowerCase()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: accent)),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: accent),
                        ]),
                      ]),
                )
              : Row(children: [
                  Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(icon, color: accent, size: 25)),
                  const SizedBox(width: 15),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodyMedium)
                      ])),
                  Icon(Icons.arrow_forward_rounded, size: 19, color: accent),
                ]),
        ),
      ),
    );
  }
}

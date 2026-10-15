import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MotherHomeScreen extends StatefulWidget {
  const MotherHomeScreen({super.key});

  @override
  State<MotherHomeScreen> createState() => _MotherHomeScreenState();
}

class _MotherHomeScreenState extends State<MotherHomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _currentWeek = '—';
  double _progress = 0;
  String _activeStage = 'Add your last menstrual period date';

  @override
  void initState() {
    super.initState();
    _loadCurrentWeek();
  }

  Future<void> _loadCurrentWeek() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final profile = await _supabase.from('pregnancy_profiles').select('lmp_date').eq('user_id', user.id).maybeSingle();
      final rawDate = profile?['lmp_date'] as String?;
      if (rawDate == null) return;
      final days = DateTime.now().difference(DateTime.parse(rawDate)).inDays;
      final week = (days ~/ 7).clamp(0, 42);
      final trimester = week < 13 ? 1 : week < 28 ? 2 : 3;
      if (!mounted) return;
      setState(() {
        _currentWeek = '$week';
        _progress = (week / 40).clamp(0.0, 1.0).toDouble();
        _activeStage = 'Trimester $trimester · Week $week';
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load pregnancy profile: $error')));
    }
  }

  Future<void> _editPregnancyDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 140)),
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
      helpText: 'Select the first day of your last period',
    );
    if (picked == null) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('pregnancy_profiles').update({'lmp_date': DateFormat('yyyy-MM-dd').format(picked)}).eq('user_id', user.id);
      await _loadCurrentWeek();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save pregnancy date: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MatruCare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Set pregnancy date',
            onPressed: _editPregnancyDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregnancy stage banner
            Card(
              color: const Color(0xFFF1E8ED),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('YOUR JOURNEY', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4, color: const Color(0xFF70445E), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(_activeStage, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22)),
                  const SizedBox(height: 18),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _progress, minHeight: 8, backgroundColor: Colors.white, color: const Color(0xFF70445E))),
                  const SizedBox(height: 10),
                  Text('${(_progress * 100).round()}% of the 40-week journey', style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // Quick stats cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              children: [
                _buildStatCard(
                  Icons.schedule,
                  'Appointments',
                  'No appointments yet',
                  Color(0xFFF4F0F2),
                  Color(0xFF70445E),
                ),
                _buildStatCard(
                  Icons.favorite,
                  'Movement',
                  'Follow your care team’s guidance',
                  Color(0xFFF4F0F2),
                  Color(0xFF70445E),
                ),
                _buildStatCard(
                  Icons.water_drop,
                  'Hydration',
                  'Track in daily check-in',
                  Color(0xFFF4F0F2),
                  Color(0xFF789080),
                ),
                _buildStatCard(
                  Icons.favorite,
                  'Weight',
                  'No measurements yet',
                  Color(0xFFF4F0F2),
                  Color(0xFF789080),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Navigation buttons to key screens
            Text(
              'Quick Access',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _navButton(
                  context,
                  Icons.dashboard,
                  'Dashboard',
                  Color(0xFFF4F0F2),
                  Color(0xFF70445E),
                  '/mother-home',
                ),
                _navButton(
                  context,
                  Icons.check_circle_outline,
                  'Daily check-in',
                  Color(0xFFF4F0F2),
                  Color(0xFF789080),
                  '/check-in',
                ),
                _navButton(
                  context,
                  Icons.health_and_safety,
                  'Track symptoms',
                  Color(0xFFF4F0F2),
                  Color(0xFF70445E),
                  '/symptoms',
                ),
                _navButton(
                  context,
                  Icons.medical_services,
                  'Doctor',
                  Color(0xFFF4F0F2),
                  Color(0xFF789080),
                  '/doctor-portal',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Baby growth weekly viewer
            _buildBabyGrowthSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String subtitle,
      Color color, Color accentColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF1E8ED), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: accentColor, size: 22)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF766E76), fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF28212A), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    Color accentColor,
    String route,
  ) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon, color: accentColor),
      label: Text(label),
      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF70445E), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), side: const BorderSide(color: Color(0xFFE7E0E3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }

  Widget _buildBabyGrowthSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Baby Growth - Week $_currentWeek',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF880E4F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  'Pregnancy week $_currentWeek',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Size comparison
            Row(
              children: [
                const Icon(Icons.compare_arrows, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Your pregnancy timeline is an estimate based on your last period.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Development text
            Text(
              'Ask your clinician about growth measurements at your visits.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            // Educational summary
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'This app does not provide diagnosis or replace prenatal care. Contact your clinician with health concerns.',
                style: TextStyle(fontSize: 10, color: Colors.grey[700], height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

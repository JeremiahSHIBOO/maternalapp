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
  String _currentWeek = '20';
  double _progress = 0.60;
  String _activeStage = 'Trimester 2 (Wk 20)';

  @override
  void initState() {
    super.initState();
    _loadCurrentWeek();
  }

  Future<void> _loadCurrentWeek() async {
    // In a real app, this would fetch from Supabase
    // For now, set default
    setState(() {
      _currentWeek = '20';
      _progress = 0.60;
      _activeStage = 'Trimester 2 (Wk 20)';
    });
  }

  void _updateWeek(String week) {
    setState(() {
      _currentWeek = week;
      // Update progress based on week
      final weekNum = int.tryParse(week.replaceAll('Week ', '')) ?? 1;
      _progress = weekNum / 40.0;
      _activeStage = 'Week $_currentWeek';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MatruCare - Mother'),
        backgroundColor: const Color(0xFF880E4F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregnancy stage banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Stage: $_activeStage',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    color: Color(0xFF880E4F),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Progress: ${(_progress * 100).round()}%',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF880E4F)),
                  ),
                ],
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
                  '2 this month',
                  Color(0xFFE3F2FD),
                  Colors.blue,
                ),
                _buildStatCard(
                  Icons.favorite,
                  'Baby Kicks',
                  'Daily movements',
                  Color(0xFFF3E5F5),
                  Color(0xFFE91E63),
                ),
                _buildStatCard(
                  Icons.water,
                  'Hydration',
                  '2.5L / 3.0L',
                  Color(0xFFE8F5E9),
                  Color(0xFF4CAF50),
                ),
                _buildStatCard(
                  Icons.favorite,
                  'Weight',
                  '13.2 kg',
                  Color(0xFFE8F5E9),
                  Color(0xFF8BC34A),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Navigation buttons to key screens
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF880E4F),
              ),
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
                  Color(0xFFE3F2FD),
                  Colors.pink[100]!,
                  '/mother-home',
                ),
                _navButton(
                  context,
                  Icons.calendar_today,
                  'Appointments',
                  Color(0xFFE8F5E9),
                  Color(0xFF8BC34A),
                  '/appointments',
                ),
                _navButton(
                  context,
                  Icons.baby_changing_station,
                  'Baby Care',
                  Color(0xFFF3E5F5),
                  Color(0xFFE91E63),
                  '/baby-care',
                ),
                _navButton(
                  context,
                  Icons.medical_services,
                  'Doctor',
                  Color(0xFFE3F2FD),
                  Colors.blue,
                  '/doctor',
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF880E4F)),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon, color: accentColor),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
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
            const Text(
              'Baby Growth - Week $_currentWeek',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF880E4F),
              ),
            ),
            const SizedBox(height: 12),
            // Placeholder for 3D growth illustration
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  '3D Illustration\nWeek $_currentWeek',
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
                    'About the size of a Banana 🍌',
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
            const Text(
              'Length: ~25.6 cm | Weight: ~300 g',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 12),
            // Educational summary
            const Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Text(
                'Baby is developing rapidly this week. Internal organs are forming, and baby can hear sounds from outside the womb.',
                style: TextStyle(fontSize: 10, color: Colors.grey[700], height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
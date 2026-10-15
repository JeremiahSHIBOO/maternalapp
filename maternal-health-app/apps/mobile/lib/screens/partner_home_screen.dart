import 'package:flutter/material.dart';

class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MatruCare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                _buildSummaryCard(
                  Icons.task,
                  'Pending Tasks',
                  'No shared data',
                  Color(0xFFF4F0F2),
                  Color(0xFF70445E),
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  Icons.money,
                  'Monthly Expenses',
                  'No shared data',
                  Color(0xFFF4F0F2),
                  Color(0xFF789080),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _actionButton(
                  context,
                  Icons.task_alt,
                  'Tasks',
                  Color(0xFFF4F0F2),
                  Color(0xFF789080),
                  '/partner/tasks',
                ),
                _actionButton(
                  context,
                  Icons.medical_services,
                  'Expenses',
                  Color(0xFFF4F0F2),
                  Color(0xFF70445E),
                  '/partner/expenses',
                ),
                _actionButton(
                  context,
                  Icons.calendar_today,
                  'Calendar',
                  Color(0xFFF4F0F2),
                  Color(0xFF789080),
                  '/partner/calendar',
                ),
                _actionButton(
                  context,
                  Icons.people,
                  'Family',
                  Color(0xFFF4F0F2),
                  Color(0xFF70445E),
                  '/partner/family',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Baby care log
            _buildBabyCareSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String title, String subtitle,
      Color color, Color accentColor) {
    return Expanded(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                [
                  Icon(icon, color: accentColor, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF880E4F)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    Color accentColor,
    String route,
  ) {
    return OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label will appear after a mother shares access with your account.')),
      ),
      icon: Icon(icon, color: accentColor),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: Color(0xFFE7E0E3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildBabyCareSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Baby Care',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF880E4F)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.baby_changing_station, color: Color(0xFF880E4F), size: 20),
                const SizedBox(width: 8),
                const Text('Last Feed:'),
                const Spacer(),
                Text('No shared data', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF880E4F), size: 20),
                const SizedBox(width: 8),
                const Text('Next Feeding:'),
                const Spacer(),
                Text('Connect to a mother profile to view care logs', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

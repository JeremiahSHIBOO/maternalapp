import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _sleepController = TextEditingController();
  final _moodController = TextEditingController();
  final _energyController = TextEditingController();
  final _stressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _hydrationOptions = ['poor', 'fair', 'good', 'excellent'];
  String? _selectedHydration;

  @override
  void initState() {
    super.initState();
    _selectedHydration = null;
  }

  @override
  void dispose() {
    _sleepController.dispose();
    _moodController.dispose();
    _energyController.dispose();
    _stressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckIn() async {
    if (_selectedHydration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select hydration status')),
      );
      return;
    }
    final sleep = double.tryParse(_sleepController.text);
    final enteredScores = [_moodController.text, _energyController.text, _stressController.text]
        .where((value) => value.trim().isNotEmpty)
        .map(int.tryParse)
        .toList();
    if ((_sleepController.text.trim().isNotEmpty && (sleep == null || sleep < 0 || sleep > 24)) ||
        enteredScores.any((value) => value == null || value < 1 || value > 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter sleep from 0–24 hours and scores from 1–10.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _supabase.from('daily_check_ins').insert({
        'mother_profile_id': await ProfileService.motherProfileId(),
        'check_in_date': DateTime.now().toIso8601String(),
        'sleep_duration_hours': sleep,
        'mood': int.tryParse(_moodController.text),
        'energy': int.tryParse(_energyController.text),
        'stress': int.tryParse(_stressController.text),
        'hydration_status': _selectedHydration,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _notesController.clear();
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in logged successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting check-in: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-in'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Health Check-in',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Sleep
              _buildFieldRow(
                Icons.bed,
                'Sleep Duration (hours)',
                _sleepController,
                const Text('e.g., 7.5'),
              ),
              const SizedBox(height: 16),

              // Mood, Energy, Stress in a row
              Row(
                children: [
                  Expanded(
                    child: _buildScoreRow(Icons.emoji_events, 'Mood', _moodController,
                        const Text('1-10')),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildScoreRow(Icons.bolt, 'Energy', _energyController,
                        const Text('1-10')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildScoreRow(Icons.mood, 'Stress', _stressController,
                  const Text('1-10')),
              const SizedBox(height: 16),

              // Hydration
              const Text(
                'Hydration Status',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedHydration,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select hydration status',
                ),
                items: _hydrationOptions.map((String hydration) {
                  return DropdownMenuItem<String>(
                    value: hydration,
                    child: Text(hydration),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHydration = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select hydration status' : null,
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'How are you feeling today?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit button
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitCheckIn,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Submit Check-in'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldRow(IconData icon, String label, TextEditingController controller,
      Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Color(0xFF880E4F)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF880E4F)),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 7.5',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildScoreRow(IconData icon, String label, TextEditingController controller,
      Widget trailing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF880E4F)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF880E4F)),
              ),
            ),
            Text(
              controller.text,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter a score from 1 to 10',
            border: OutlineInputBorder(),
            suffixText: '1–10',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ((double.tryParse(controller.text) ?? 5) / 10).clamp(0.0, 1.0).toDouble(),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

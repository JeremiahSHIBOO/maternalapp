import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _symptomController = TextEditingController();
  String _selectedSymptom = '';
  int _severity = 5;
  bool _isLoggingIn = false;
  final List<String> _symptoms = [
    'Morning Sickness',
    'Lower Back Pain',
    'Headache',
    'Swelling',
    'Heartburn',
    'Fatigue',
    'Sleep Issues'
  ];

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _logSymptom() async {
    if (_selectedSymptom.isEmpty) return;

    setState(() => _isLoggingIn = true);
    try {
      await _supabase.from('symptom_logs').insert({
        'mother_profile_id': await ProfileService.motherProfileId(),
        'symptom_name': _selectedSymptom,
        'severity': _severity,
        'log_date': DateTime.now().toIso8601String(),
        'notes': _symptomController.text.trim().isEmpty ? null : _symptomController.text.trim(),
      });

      if (!mounted) return;
      _symptomController.clear();
      _selectedSymptom = '';
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptom logged successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging symptom: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log a Symptom',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Symptom selection
            DropdownButtonFormField<String>(
              initialValue: _selectedSymptom.isEmpty ? null : _selectedSymptom,
              decoration: const InputDecoration(
                labelText: 'Select Symptom',
                border: OutlineInputBorder(),
              ),
              items: _symptoms.map((String symptom) {
                return DropdownMenuItem<String>(
                  value: symptom,
                  child: Text(symptom),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSymptom = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a symptom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Severity slider
            const Text(
              'Severity (1-10)',
              style: TextStyle(fontSize: 16),
            ),
            Slider(
              value: _severity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _severity.toString(),
              onChanged: (double value) {
                setState(() {
                  _severity = value.round();
                });
              },
            ),
            const SizedBox(height: 4),
            Text(
              'You selected: $_severity',
              style: const TextStyle(fontSize: 12, color: Color(0xFF880E4F)),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _symptomController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Describe additional details',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Log button
            ElevatedButton(
              onPressed: _logSymptom,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoggingIn
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Log Symptom', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

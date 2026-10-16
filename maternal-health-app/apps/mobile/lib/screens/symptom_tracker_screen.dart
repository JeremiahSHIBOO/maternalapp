import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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
  bool _isLoadingHistory = true;
  String? _historyLoadError;
  String? _editingId;
  DateTime _symptomDate = DateTime.now();
  List<Map<String, dynamic>> _history = [];
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
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _isLoadingHistory = true;
        _historyLoadError = null;
      });
    }
    try {
      final profileId = await ProfileService.motherProfileId();
      final rows = await _supabase
          .from('symptom_logs')
          .select('id,symptom_name,severity,log_date,notes')
          .eq('mother_profile_id', profileId)
          .order('log_date', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() => _history = List<Map<String, dynamic>>.from(rows));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _historyLoadError = error.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load symptom history: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _pickSymptomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _symptomDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
      helpText: 'When did this symptom begin?',
    );
    if (picked != null && mounted) {
      setState(() => _symptomDate = DateTime(picked.year, picked.month,
          picked.day, _symptomDate.hour, _symptomDate.minute));
    }
  }

  void _editEntry(Map<String, dynamic> entry) {
    final date =
        DateTime.tryParse(entry['log_date'] as String? ?? '')?.toLocal();
    setState(() {
      _editingId = entry['id'] as String?;
      _selectedSymptom = entry['symptom_name'] as String? ?? '';
      _severity = (entry['severity'] as num?)?.toInt() ?? 5;
      _symptomController.text = entry['notes'] as String? ?? '';
      _symptomDate = date ?? DateTime.now();
    });
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete symptom entry?'),
        content:
            const Text('This removes this entry from your symptom history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final profileId = await ProfileService.motherProfileId();
      final deleted = await _supabase
          .from('symptom_logs')
          .delete()
          .eq('id', entry['id'] as String)
          .eq('mother_profile_id', profileId)
          .select('id')
          .maybeSingle();
      if (deleted == null)
        throw StateError('Symptom entry was not found to delete.');
      if (!mounted) return;
      if (_editingId == entry['id']) _clearEditor();
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Symptom entry deleted')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete symptom entry: $error')),
        );
      }
    }
  }

  void _clearEditor() {
    setState(() {
      _editingId = null;
      _selectedSymptom = '';
      _severity = 5;
      _symptomDate = DateTime.now();
      _symptomController.clear();
    });
  }

  Future<void> _logSymptom() async {
    if (_isLoggingIn) return;
    if (_selectedSymptom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a symptom')),
      );
      return;
    }

    setState(() => _isLoggingIn = true);
    try {
      final wasEditing = _editingId != null;
      final profileId = await ProfileService.motherProfileId();
      final values = {
        'mother_profile_id': profileId,
        'symptom_name': _selectedSymptom,
        'severity': _severity,
        'log_date': _symptomDate.toUtc().toIso8601String(),
        'notes': _symptomController.text.trim().isEmpty
            ? null
            : _symptomController.text.trim(),
      };
      if (_editingId case final id?) {
        final saved = await _supabase
            .from('symptom_logs')
            .update(values)
            .eq('id', id)
            .eq('mother_profile_id', profileId)
            .select('id')
            .maybeSingle();
        if (saved == null)
          throw StateError('Symptom entry could not be found to update.');
      } else {
        await _supabase.from('symptom_logs').insert(values);
      }

      if (!mounted) return;
      _clearEditor();
      await _loadHistory();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(!wasEditing
                ? 'Symptom saved successfully'
                : 'Symptom updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save symptom: $e')),
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
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log a Symptom',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            Text(
              'Get help right away for severe or worsening symptoms such as trouble breathing, chest pain, a severe headache that will not go away, heavy bleeding or fluid leaking, fainting, seizures, or severe abdominal pain. Contact your maternity care team; if you cannot reach them, go to emergency care. This log cannot assess your health.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

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

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Symptom onset / date'),
              subtitle: Text(DateFormat('d MMM yyyy').format(_symptomDate)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickSymptomDate,
            ),

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
              onPressed: _isLoggingIn ? null : _logSymptom,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoggingIn
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_editingId == null ? 'Log Symptom' : 'Update Symptom',
                      style: const TextStyle(fontSize: 18)),
            ),
            if (_editingId != null) ...[
              const SizedBox(height: 8),
              TextButton(
                  onPressed: _clearEditor, child: const Text('Cancel edit')),
            ],
            const SizedBox(height: 24),
            Text('Symptom history',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_isLoadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (_historyLoadError != null)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Symptom history could not be loaded. $_historyLoadError',
                    style: Theme.of(context).textTheme.bodyMedium),
                TextButton(onPressed: _loadHistory, child: const Text('Retry')),
              ])
            else if (_history.isEmpty)
              Text('No symptoms recorded yet.',
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              ..._history.map((entry) {
                final date =
                    DateTime.tryParse(entry['log_date'] as String? ?? '')
                        ?.toLocal();
                return Card(
                  child: ListTile(
                    title: Text(entry['symptom_name'] as String? ?? 'Symptom'),
                    subtitle: Text(
                        '${date == null ? 'Date unavailable' : DateFormat('d MMM yyyy').format(date)} · Self-reported${(entry['notes'] as String?)?.isNotEmpty == true ? '\n${entry['notes']}' : ''}'),
                    isThreeLine:
                        (entry['notes'] as String?)?.isNotEmpty == true,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${entry['severity']}/10'),
                      IconButton(
                          tooltip: 'Edit symptom',
                          onPressed: () => _editEntry(entry),
                          icon: const Icon(Icons.edit_outlined)),
                      IconButton(
                          tooltip: 'Delete symptom',
                          onPressed: () => _deleteEntry(entry),
                          icon: const Icon(Icons.delete_outline)),
                    ]),
                  ),
                );
              }),
          ],
        )),
      ),
    );
  }
}

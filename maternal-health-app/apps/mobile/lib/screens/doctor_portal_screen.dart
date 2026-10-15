import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorPortalScreen extends StatefulWidget {
  const DoctorPortalScreen({super.key});

  @override
  State<DoctorPortalScreen> createState() => _DoctorPortalScreenState;
}

class _DoctorPortalScreenState extends State<DoctorPortalScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, this would query the database with proper RLS
      // For now, use demo data
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _patients.addAll([
          {
            'id': '1',
            'name': 'Ananya Sharma',
            'age': '28',
            'gestationalAge': '20 weeks',
            'status': 'active',
          },
          {
            'id': '2',
            'name': 'Priya Patel',
            'age': '32',
            'gestationalAge': '34 weeks',
            'status': 'high-risk',
          },
          {
            'id': '3',
            'name': 'Sunita Singh',
            'age': '26',
            'gestationalAge': '15 weeks',
            'status': 'active',
          },
        ]);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patients: $e')),
      );
    }
  }

  Future<void> _searchPatient() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        // Filter patients based on search
        _patients.clear();
        if (_searchController.text.isNotEmpty) {
          _patients.add({
            'id': '1',
            'name': 'Ananya Sharma',
            'age': '28',
            'gestationalAge': '20 weeks',
            'status': 'active',
          });
        } else {
          _loadPatients();
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Portal'),
        backgroundColor: const Color(0xFF880E4F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchPatient,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Patient',
                border: OutlineInputBorder(),
                hintText: 'Enter name or MCI number',
              ),
              onSubmitted: (_) => _searchPatient(),
            ),
            const SizedBox(height: 24),

            // Patients list
            const Text(
              'Patients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF880E4F)),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const CircularProgressIndicator()
                : _patients.isEmpty
                    ? const Text('No patients found')
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _patients.length,
                          itemBuilder: (context, index) {
                            final patient = _patients[index];
                            return Card(
                              color: Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(0xFF880E4F),
                                  child: Text(
                                    patient['name'][0],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(patient['name']),
                                subtitle: Text(
                                  'Gestational Age: ${patient['gestationalAge']} | ${patient['age']} yrs',
                                ),
                                trailing: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: patient['status'] == 'high-risk'
                                        ? Color(0xFFFFEBEE)
                                        : Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    patient['status'],
                                    style: TextStyle(
                                      color: patient['status'] == 'high-risk'
                                          ? Color(0xFFM64043)
                                          : Color(0xFF2E7D32),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  // Navigate to patient details
                                  Navigator.pushNamed(
                                    context,
                                    '/patient-details',
                                    arguments: patient,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 24),

            // Quick stats
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF880E4F)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _quickStat(Icons.pregnant_woman, 'Active Patients', '12', Colors.pink),
                const SizedBox(width: 16),
                _quickStat(Icons.calendar_today, 'Appointments Today', '8', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF880E4F)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                    textAlign: TextAlign.center,
                  ),
                ],
          ),
        ),
      ),
    );
  }
}
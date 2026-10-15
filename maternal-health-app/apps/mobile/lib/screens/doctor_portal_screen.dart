import 'package:flutter/material.dart';

class DoctorPortalScreen extends StatefulWidget {
  const DoctorPortalScreen({super.key});

  @override
  State<DoctorPortalScreen> createState() => _DoctorPortalScreenState();
}

class _DoctorPortalScreenState extends State<DoctorPortalScreen> {
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
      if (!mounted) return;
      setState(() {
        _patients.clear();
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
      if (!mounted) return;
      setState(() {
        _patients.clear();
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
            Text(
              'Patients',
            style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const CircularProgressIndicator()
                : _patients.isEmpty
                    ? const Text('No assigned patients are available for this account.')
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
                                          ? Color(0xFFB00020)
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

          ],
        ),
      ),
    );
  }

}

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
  DateTime? _lmpDate;
  DateTime? _dueDate;
  Map<String, dynamic>? _latestCheckIn;
  List<Map<String, dynamic>> _recentSymptoms = [];
  Map<String, dynamic>? _nextAppointment;
  bool _appointmentsTableMissing = false;
  bool _isLoadingDashboard = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoadingDashboard = true;
        _appointmentsTableMissing = false;
      });
    }
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final profile = await _supabase
          .from('pregnancy_profiles')
          .select('id,lmp_date,edd_date')
          .eq('user_id', user.id)
          .maybeSingle();
      final rawDate = profile?['lmp_date'] as String?;
      final rawDueDate = profile?['edd_date'] as String?;
      final lmpDate = rawDate == null ? null : DateTime.tryParse(rawDate);
      final dueDate = rawDueDate != null
          ? DateTime.tryParse(rawDueDate)
          : (lmpDate == null ? null : lmpDate.add(const Duration(days: 280)));

      Map<String, dynamic>? checkIn;
      List<Map<String, dynamic>> symptoms = [];
      Map<String, dynamic>? appointment;
      final pregnancyId = profile?['id'] as String?;
      if (pregnancyId != null) {
        final checkInResult = await _supabase
            .from('daily_check_ins')
            .select('check_in_date,mood,energy,stress,sleep_duration_hours,hydration_status')
            .eq('mother_profile_id', pregnancyId)
            .order('check_in_date', ascending: false)
            .limit(1)
            .maybeSingle();
        checkIn = checkInResult;
        final symptomResult = await _supabase
            .from('symptom_logs')
            .select('symptom_name,severity,log_date')
            .eq('mother_profile_id', pregnancyId)
            .order('log_date', ascending: false)
            .limit(3);
        symptoms = List<Map<String, dynamic>>.from(symptomResult);
      }

      try {
        appointment = await _supabase
            .from('care_appointments')
            .select('starts_at,clinician,location')
            .eq('user_id', user.id)
            .gte('starts_at', DateTime.now().toIso8601String())
            .order('starts_at')
            .limit(1)
            .maybeSingle();
      } on PostgrestException catch (error) {
        if (error.code == 'PGRST205' || error.code == '42P01') {
          _appointmentsTableMissing = true;
        } else {
          rethrow;
        }
      }

      var week = 0;
      if (lmpDate != null) {
        week = (DateTime.now().difference(lmpDate).inDays ~/ 7).clamp(0, 42);
      }
      final trimester = week < 13 ? 1 : week < 28 ? 2 : 3;
      if (!mounted) return;
      setState(() {
        _lmpDate = lmpDate;
        _dueDate = dueDate;
        _latestCheckIn = checkIn;
        _recentSymptoms = symptoms;
        _nextAppointment = appointment;
        _currentWeek = lmpDate == null ? '—' : '$week';
        _progress = lmpDate == null ? 0 : (week / 40).clamp(0.0, 1.0).toDouble();
        _activeStage = lmpDate == null
            ? 'Add your last menstrual period date'
            : 'Trimester $trimester · Week $week';
        _isLoadingDashboard = false;
      });
    } catch (error) {
      if (mounted) setState(() => _isLoadingDashboard = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load pregnancy profile: $error')));
    }
  }

  Future<void> _editPregnancyDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmpDate ?? now.subtract(const Duration(days: 140)),
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
      helpText: 'Select the first day of your last period',
    );
    if (picked == null) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final dueDate = picked.add(const Duration(days: 280));
      await _supabase.from('pregnancy_profiles').update({
        'lmp_date': DateFormat('yyyy-MM-dd').format(picked),
        'edd_date': DateFormat('yyyy-MM-dd').format(dueDate),
      }).eq('user_id', user.id);
      await _loadDashboardData();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save pregnancy date: $error')));
    }
  }

  Future<void> _addAppointment() async {
    if (_appointmentsTableMissing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Run the dashboard appointments SQL setup file in your Supabase project first.')),
      );
      return;
    }
    final clinicianController = TextEditingController();
    final locationController = TextEditingController();
    var selectedDate = DateTime.now().add(const Duration(days: 7));
    var saving = false;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(DateFormat('EEE, d MMM yyyy · h:mm a').format(selectedDate)),
                onTap: () async {
                  final day = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (day == null || !context.mounted) return;
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedDate));
                  if (time == null) return;
                  setDialogState(() => selectedDate = DateTime(day.year, day.month, day.day, time.hour, time.minute));
                },
              ),
              TextField(controller: clinicianController, decoration: const InputDecoration(labelText: 'Clinician (optional)')),
              const SizedBox(height: 12),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location (optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  await _supabase.from('care_appointments').insert({
                    'user_id': _supabase.auth.currentUser!.id,
                    'starts_at': selectedDate.toUtc().toIso8601String(),
                    'clinician': clinicianController.text.trim().isEmpty ? null : clinicianController.text.trim(),
                    'location': locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  setDialogState(() => saving = false);
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Could not save appointment: $error')));
                  }
                }
              },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    clinicianController.dispose();
    locationController.dispose();
    if (shouldSave == true) await _loadDashboardData();
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
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.event_available_outlined, size: 19, color: Color(0xFF70445E)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_dueDate == null ? 'Estimated due date not set' : 'Estimated due date · ${DateFormat('d MMM yyyy').format(_dueDate!)}', style: Theme.of(context).textTheme.titleMedium)),
                    TextButton(onPressed: _editPregnancyDate, child: Text(_lmpDate == null ? 'Set dates' : 'Edit')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            _buildAppointmentCard(context),
            const SizedBox(height: 16),
            _buildWellbeingCard(context),
            const SizedBox(height: 16),
            _buildSymptomsCard(context),
            const SizedBox(height: 24),

            // Navigation buttons to key screens
            Text('Your care', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _navButton(
                  context,
                  Icons.dashboard,
                  'Dashboard',
                  Color(0xFF70445E),
                  '/mother-home',
                ),
                _navButton(
                  context,
                  Icons.check_circle_outline,
                  'Daily check-in',
                  Color(0xFF789080),
                  '/check-in',
                ),
                _navButton(
                  context,
                  Icons.health_and_safety,
                  'Track symptoms',
                  Color(0xFF70445E),
                  '/symptoms',
                ),
                _navButton(
                  context,
                  Icons.medical_services,
                  'Doctor',
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

  Widget _buildAppointmentCard(BuildContext context) {
    final appointment = _nextAppointment;
    final clinician = appointment?['clinician'] as String?;
    final location = appointment?['location'] as String?;
    final appointmentDate = appointment == null
        ? null
        : DateTime.tryParse(appointment['starts_at'] as String? ?? '')?.toLocal();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF70445E)),
            const SizedBox(width: 10),
            Expanded(child: Text('Next appointment', style: Theme.of(context).textTheme.titleLarge)),
            IconButton(tooltip: 'Add appointment', onPressed: _addAppointment, icon: const Icon(Icons.add_circle_outline)),
          ]),
          if (_isLoadingDashboard)
            const LinearProgressIndicator()
          else if (_appointmentsTableMissing)
            Text('Appointment setup is needed. Run supabase/dashboard_appointments.sql from this app folder in your Supabase SQL editor.', style: Theme.of(context).textTheme.bodyMedium)
          else if (appointmentDate == null)
            Text('No upcoming appointments. Add one to keep your care plan close.', style: Theme.of(context).textTheme.bodyMedium)
          else ...[
            Text(DateFormat('EEEE, d MMMM · h:mm a').format(appointmentDate), style: Theme.of(context).textTheme.titleMedium),
            if (clinician != null && clinician.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(clinician, style: Theme.of(context).textTheme.bodyMedium)),
            if (location != null && location.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 2), child: Text(location, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ]),
      ),
    );
  }

  Widget _buildWellbeingCard(BuildContext context) {
    final checkIn = _latestCheckIn;
    final date = checkIn == null
        ? null
        : DateTime.tryParse(checkIn['check_in_date'] as String? ?? '')?.toLocal();
    final details = <String>[];
    if (checkIn?['mood'] != null) details.add('Mood ${checkIn!['mood']}/10');
    if (checkIn?['energy'] != null) details.add('Energy ${checkIn!['energy']}/10');
    if (checkIn?['stress'] != null) details.add('Stress ${checkIn!['stress']}/10');
    if (checkIn?['sleep_duration_hours'] != null) details.add('${checkIn!['sleep_duration_hours']}h sleep');
    if (checkIn?['hydration_status'] != null) details.add('${checkIn!['hydration_status']} hydration');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.favorite_border, color: Color(0xFF789080)),
            const SizedBox(width: 10),
            Expanded(child: Text('Your wellbeing', style: Theme.of(context).textTheme.titleLarge)),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/check-in').then((_) => _loadDashboardData()), child: const Text('Check in')),
          ]),
          Text(
            date == null ? 'No check-in yet' : 'Last checked in ${DateFormat('d MMM').format(date)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(details.isEmpty ? 'Log how you are feeling today.' : details.join('  ·  '), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Self-reported · For your personal tracking, not a diagnosis.', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _buildSymptomsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.health_and_safety_outlined, color: Color(0xFF70445E)),
            const SizedBox(width: 10),
            Expanded(child: Text('Recent symptoms', style: Theme.of(context).textTheme.titleLarge)),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/symptoms').then((_) => _loadDashboardData()), child: const Text('Log')),
          ]),
          if (_isLoadingDashboard)
            const LinearProgressIndicator()
          else if (_recentSymptoms.isEmpty)
            Text('No symptoms logged recently.', style: Theme.of(context).textTheme.bodyMedium)
          else
            ..._recentSymptoms.map((symptom) {
              final loggedAt = DateTime.tryParse(symptom['log_date'] as String? ?? '')?.toLocal();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(symptom['symptom_name'] as String? ?? 'Symptom'),
                subtitle: Text(loggedAt == null ? 'Self-reported' : 'Self-reported · ${DateFormat('d MMM').format(loggedAt)}'),
                trailing: Text('${symptom['severity'] ?? '—'}/10', style: Theme.of(context).textTheme.titleMedium),
              );
            }),
        ]),
      ),
    );
  }

  Widget _navButton(
    BuildContext context,
    IconData icon,
    String label,
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

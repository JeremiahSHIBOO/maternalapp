
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'daily_checkin_screen.dart';

class MotherHomeScreen extends StatefulWidget {
  const MotherHomeScreen({super.key});

  @override
  State<MotherHomeScreen> createState() => _MotherHomeScreenState();
}

class _MotherHomeScreenState extends State<MotherHomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _currentWeek = '—';
  String? _pregnancyProfileId;
  int? _pregnancyWeekNumber;
  int _pregnancyDay = 0;
  int _selectedGrowthWeek = 1;
  String _pregnancyType = 'single';
  String _profileNotes = '';
  int? _dateConflictDays;
  bool _profileDatesInvalid = false;
  double _progress = 0;
  String _activeStage = 'Add your last menstrual period date';
  DateTime? _lmpDate;
  DateTime? _dueDate;
  Map<String, dynamic>? _latestCheckIn;
  List<Map<String, dynamic>> _recentCheckIns = [];
  String? _checkInLoadError;
  bool _measurementColumnsAvailable = true;
  List<Map<String, dynamic>> _recentSymptoms = [];
  Map<String, dynamic>? _nextAppointment;
  bool _appointmentsTableMissing = false;
  bool _checkedInToday = false;
  bool _isLoadingDashboard = true;
  bool _isOpeningCheckIn = false;
  int _dashboardLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final generation = ++_dashboardLoadGeneration;
    if (mounted) {
      setState(() {
        _isLoadingDashboard = true;
        _appointmentsTableMissing = false;
        _checkInLoadError = null;
      });
    }
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingDashboard = false);
        return;
      }
      final profile = await _supabase
          .from('pregnancy_profiles')
          .select('id,lmp_date,edd_date,pregnancy_type,notes')
          .eq('user_id', user.id)
          .maybeSingle();
      final rawDate = profile?['lmp_date'] as String?;
      final rawDueDate = profile?['edd_date'] as String?;
      final lmpDate = rawDate == null ? null : DateTime.tryParse(rawDate);
      final dueDate = rawDueDate != null
          ? DateTime.tryParse(rawDueDate)
          : (lmpDate == null ? null : lmpDate.add(const Duration(days: 280)));
      final normalizedLmp = lmpDate ??
          (dueDate == null
              ? null
              : dueDate.subtract(const Duration(days: 280)));
      final dateConflictDays = lmpDate != null && dueDate != null
          ? dueDate.difference(lmpDate.add(const Duration(days: 280))).inDays
          : null;
      final profileDatesInvalid =
          normalizedLmp != null && normalizedLmp.isAfter(DateTime.now());

      Map<String, dynamic>? checkIn;
      List<Map<String, dynamic>> recentCheckIns = [];
      String? checkInLoadError;
      var measurementColumnsAvailable = true;
      List<Map<String, dynamic>> symptoms = [];
      Map<String, dynamic>? appointment;
      final pregnancyId = profile?['id'] as String?;
      if (pregnancyId != null) {
        List<Map<String, dynamic>> loadedCheckIns = [];
        try {
          final checkInResult = await _supabase
              .from('daily_check_ins')
              .select(
                  'id,check_in_date,mood,energy,stress,sleep_duration_hours,sleep_quality,hydration_status,notes,bp_systolic_mmhg,bp_diastolic_mmhg,heart_rate_bpm,hrv_ms,spo2_percent,respiratory_rate_per_min,skin_temperature_c,weight_kg,steps_count,measurement_source')
              .eq('mother_profile_id', pregnancyId)
              .order('check_in_date', ascending: false)
              .limit(24);
          loadedCheckIns = List<Map<String, dynamic>>.from(checkInResult);
        } catch (error) {
          if (error is! PostgrestException ||
              !_isMissingMeasurementColumn(error)) {
            checkInLoadError = 'Could not load your saved check-ins.';
            debugPrint('Check-in history could not be loaded: $error');
          } else {
            measurementColumnsAvailable = false;
            try {
              final legacyCheckIns = await _supabase
                  .from('daily_check_ins')
                  .select(
                      'id,check_in_date,mood,energy,stress,sleep_duration_hours,sleep_quality,hydration_status,notes')
                  .eq('mother_profile_id', pregnancyId)
                  .order('check_in_date', ascending: false)
                  .limit(24);
              loadedCheckIns = List<Map<String, dynamic>>.from(legacyCheckIns);
            } catch (legacyError) {
              checkInLoadError = 'Could not load your saved check-ins.';
              debugPrint(
                  'Legacy check-in history could not be loaded: $legacyError');
            }
          }
        }
        if (checkInLoadError == null) {
          recentCheckIns = loadedCheckIns;
          checkIn = loadedCheckIns.isEmpty ? null : loadedCheckIns.first;
        }
        final symptomResult = await _supabase
            .from('symptom_logs')
            .select('id,symptom_name,severity,log_date,notes')
            .eq('mother_profile_id', pregnancyId)
            .order('log_date', ascending: false)
            .limit(3);
        symptoms = List<Map<String, dynamic>>.from(symptomResult);
      }

      try {
        appointment = await _supabase
            .from('care_appointments')
            .select('id,starts_at,clinician,location,notes')
            .eq('user_id', user.id)
            .gte('starts_at', DateTime.now().toUtc().toIso8601String())
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

      final gestationDays = normalizedLmp == null || profileDatesInvalid
          ? null
          : DateTime.now().difference(normalizedLmp).inDays;
      final completedWeeks =
          gestationDays == null ? null : (gestationDays ~/ 7).clamp(0, 42);
      final dayInWeek = gestationDays == null ? 0 : gestationDays % 7;
      final checkInDate =
          DateTime.tryParse(checkIn?['check_in_date'] as String? ?? '')
              ?.toLocal();
      final checkedInToday = checkInDate != null &&
          checkInDate.year == DateTime.now().year &&
          checkInDate.month == DateTime.now().month &&
          checkInDate.day == DateTime.now().day;
      final weeksForTrimester = completedWeeks ?? 0;
      final trimester = weeksForTrimester < 13
          ? 1
          : weeksForTrimester < 28
              ? 2
              : 3;
      if (!mounted || generation != _dashboardLoadGeneration) return;
      setState(() {
        _pregnancyProfileId = profile?['id'] as String?;
        _lmpDate = normalizedLmp;
        _dueDate = dueDate;
        _pregnancyType = profile?['pregnancy_type'] as String? ?? 'single';
        _profileNotes = profile?['notes'] as String? ?? '';
        _dateConflictDays =
            dateConflictDays != null && dateConflictDays.abs() > 14
                ? dateConflictDays
                : null;
        _profileDatesInvalid = profileDatesInvalid;
        // Keep a just-saved Supabase row visible if a history refresh fails.
        if (checkInLoadError == null) {
          _latestCheckIn = checkIn;
          _recentCheckIns = recentCheckIns;
        }
        _checkInLoadError = checkInLoadError;
        _measurementColumnsAvailable = measurementColumnsAvailable;
        _checkedInToday = checkedInToday;
        _recentSymptoms = symptoms;
        _nextAppointment = appointment;
        _pregnancyWeekNumber = completedWeeks;
        _pregnancyDay = dayInWeek;
        _currentWeek = completedWeeks == null
            ? '—'
            : 'Week $completedWeeks · Day $dayInWeek';
        if (completedWeeks != null) {
          _selectedGrowthWeek =
              (completedWeeks == 0 ? 1 : completedWeeks).clamp(1, 42);
        }
        _progress = gestationDays == null
            ? 0
            : (gestationDays / 280).clamp(0.0, 1.0).toDouble();
        _activeStage = completedWeeks == null
            ? profileDatesInvalid
                ? 'Review your pregnancy dates'
                : 'Add your last menstrual period or due date'
            : 'Trimester $trimester · Week $completedWeeks, day $dayInWeek';
        _isLoadingDashboard = false;
      });
    } catch (error) {
      if (mounted && generation == _dashboardLoadGeneration) {
        setState(() => _isLoadingDashboard = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not load pregnancy profile: $error')));
      }
    }
  }

  Future<void> _editPregnancyDate() async {
    final now = DateTime.now();
    final dateController = TextEditingController(text: _profileNotes);
    var useDueDate = _lmpDate == null && _dueDate != null;
    var picked = useDueDate
        ? _dueDate!
        : (_lmpDate ?? now.subtract(const Duration(days: 140)));
    var pregnancyType = _pregnancyType;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_pregnancyProfileId == null
              ? 'Set pregnancy profile'
              : 'Edit pregnancy profile'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<bool>(
                value: useDueDate,
                decoration: const InputDecoration(labelText: 'Date to enter'),
                items: const [
                  DropdownMenuItem(
                      value: false, child: Text('Last menstrual period')),
                  DropdownMenuItem(
                      value: true, child: Text('Estimated due date')),
                ],
                onChanged: (value) => setDialogState(() {
                  useDueDate = value ?? false;
                  picked = useDueDate
                      ? (_dueDate ?? now.add(const Duration(days: 140)))
                      : (_lmpDate ?? now.subtract(const Duration(days: 140)));
                }),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(useDueDate ? 'Due date' : 'Last period date'),
                subtitle: Text(DateFormat('d MMM yyyy').format(picked)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () async {
                  final first = now.subtract(const Duration(days: 365));
                  final last =
                      useDueDate ? now.add(const Duration(days: 280)) : now;
                  final initial = picked.isBefore(first)
                      ? first
                      : (picked.isAfter(last) ? last : picked);
                  final date = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: first,
                    lastDate: last,
                    helpText: useDueDate
                        ? 'Select estimated due date'
                        : 'Select the first day of your last period',
                  );
                  if (date != null) setDialogState(() => picked = date);
                },
              ),
              DropdownButtonFormField<String>(
                value: pregnancyType,
                decoration: const InputDecoration(labelText: 'Pregnancy type'),
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('Single')),
                  DropdownMenuItem(value: 'twin', child: Text('Twin')),
                  DropdownMenuItem(value: 'multiple', child: Text('Multiple')),
                ],
                onChanged: (value) =>
                    setDialogState(() => pregnancyType = value ?? 'single'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 8),
              Text(
                  'The other date is estimated using a 280-day pregnancy timeline. Confirm dates with your clinician.',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (shouldSave != true) {
      dateController.dispose();
      return;
    }
    try {
      final user = _supabase.auth.currentUser;
      if (user == null)
        throw StateError('Please sign in to save your pregnancy profile.');
      final lmp =
          useDueDate ? picked.subtract(const Duration(days: 280)) : picked;
      final dueDate =
          useDueDate ? picked : picked.add(const Duration(days: 280));
      if (lmp.isAfter(DateTime.now())) {
        throw StateError('The due date must be within 280 days from today.');
      }
      final values = {
        'lmp_date': DateFormat('yyyy-MM-dd').format(lmp),
        'edd_date': DateFormat('yyyy-MM-dd').format(dueDate),
        'pregnancy_type': pregnancyType,
        'notes': dateController.text.trim().isEmpty
            ? null
            : dateController.text.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (_pregnancyProfileId != null) {
        final saved = await _supabase
            .from('pregnancy_profiles')
            .update(values)
            .eq('id', _pregnancyProfileId!)
            .eq('user_id', user.id)
            .select('id')
            .maybeSingle();
        if (saved == null)
          throw StateError('Your pregnancy profile was not found to update.');
      } else {
        final saved = await _supabase
            .from('pregnancy_profiles')
            .insert({...values, 'user_id': user.id})
            .select('id')
            .single();
        _pregnancyProfileId = saved['id'] as String;
      }
      dateController.dispose();
      await _loadDashboardData();
    } catch (error) {
      dateController.dispose();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save pregnancy date: $error')));
    }
  }

  Future<void> _addAppointment() => _manageAppointment();

  Future<void> _editAppointment(Map<String, dynamic> appointment) =>
      _manageAppointment(appointment: appointment);

  Future<void> _manageAppointment({Map<String, dynamic>? appointment}) async {
    final screenContext = context;
    if (_appointmentsTableMissing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Run the dashboard appointments SQL setup file in your Supabase project first.')),
      );
      return;
    }
    final clinicianController =
        TextEditingController(text: appointment?['clinician'] as String? ?? '');
    final locationController =
        TextEditingController(text: appointment?['location'] as String? ?? '');
    final notesController =
        TextEditingController(text: appointment?['notes'] as String? ?? '');
    final existingDate =
        DateTime.tryParse(appointment?['starts_at'] as String? ?? '')
            ?.toLocal();
    var selectedDate =
        existingDate ?? DateTime.now().add(const Duration(days: 7));
    var saving = false;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              appointment == null ? 'Add appointment' : 'Edit appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(DateFormat('EEE, d MMM yyyy · h:mm a')
                    .format(selectedDate)),
                onTap: () async {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final lastDate = today.add(const Duration(days: 730));
                  final selectedDay = DateTime(
                      selectedDate.year, selectedDate.month, selectedDate.day);
                  final initialDate = selectedDay.isBefore(today)
                      ? today
                      : selectedDay.isAfter(lastDate)
                          ? lastDate
                          : selectedDay;
                  final day = await showDatePicker(
                    context: screenContext,
                    initialDate: initialDate,
                    firstDate: today,
                    lastDate: lastDate,
                  );
                  if (day == null ||
                      !screenContext.mounted ||
                      !dialogContext.mounted) {
                    return;
                  }
                  final time = await showTimePicker(
                      context: screenContext,
                      initialTime: TimeOfDay.fromDateTime(selectedDate));
                  if (time == null || !dialogContext.mounted) return;
                  setDialogState(() => selectedDate = DateTime(
                      day.year, day.month, day.day, time.hour, time.minute));
                },
              ),
              TextField(
                  controller: clinicianController,
                  decoration:
                      const InputDecoration(labelText: 'Clinician (optional)')),
              const SizedBox(height: 12),
              TextField(
                  controller: locationController,
                  decoration:
                      const InputDecoration(labelText: 'Location (optional)')),
              const SizedBox(height: 12),
              TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(screenContext, rootNavigator: true)
                        .pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        final user = _supabase.auth.currentUser;
                        if (user == null)
                          throw StateError('Please sign in first.');
                        if (!selectedDate.isAfter(DateTime.now())) {
                          throw StateError('Choose a future date and time.');
                        }
                        final values = {
                          'user_id': user.id,
                          'starts_at': selectedDate.toUtc().toIso8601String(),
                          'clinician': clinicianController.text.trim().isEmpty
                              ? null
                              : clinicianController.text.trim(),
                          'location': locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                          'notes': notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                        };
                        if (appointment != null) {
                          final saved = await _supabase
                              .from('care_appointments')
                              .update(values)
                              .eq('id', appointment['id'] as String)
                              .eq('user_id', user.id)
                              .select('id')
                              .maybeSingle();
                          if (saved == null)
                            throw StateError(
                                'Appointment was not found to update.');
                        } else {
                          await _supabase
                              .from('care_appointments')
                              .insert(values)
                              .select('id')
                              .single();
                        }
                        if (dialogContext.mounted && screenContext.mounted) {
                          Navigator.of(screenContext, rootNavigator: true)
                              .pop(true);
                        }
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => saving = false);
                        if (screenContext.mounted) {
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Could not save appointment: $error')));
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(appointment == null ? 'Save' : 'Update'),
            ),
          ],
        ),
      ),
    );
    clinicianController.dispose();
    locationController.dispose();
    notesController.dispose();
    if (shouldSave == true) await _loadDashboardData();
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This removes the appointment from your schedule.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancel appointment')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw StateError('Please sign in first.');
      final deleted = await _supabase
          .from('care_appointments')
          .delete()
          .eq('id', appointment['id'] as String)
          .eq('user_id', user.id)
          .select('id')
          .maybeSingle();
      if (deleted == null)
        throw StateError('Appointment was not found to cancel.');
      await _loadDashboardData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel appointment: $error')),
        );
      }
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBabyGrowthSection(),
                const SizedBox(height: 24),
                _buildAppointmentCard(context),
                const SizedBox(height: 16),
                _buildWellbeingCard(context),
                const SizedBox(height: 16),
                _buildSymptomsCard(context),
                const SizedBox(height: 24),

                // Navigation buttons to key screens
                Text('Your care',
                    style: Theme.of(context).textTheme.titleLarge),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context) {
    final appointment = _nextAppointment;
    final clinician = appointment?['clinician'] as String?;
    final location = appointment?['location'] as String?;
    final showClinician = clinician != null &&
        clinician.trim().isNotEmpty &&
        clinician.trim().toLowerCase() != location?.trim().toLowerCase();
    final showLocation = location != null && location.trim().isNotEmpty;
    final appointmentDate = appointment == null
        ? null
        : DateTime.tryParse(appointment['starts_at'] as String? ?? '')
            ?.toLocal();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF70445E)),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Next appointment',
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
                tooltip: 'Add appointment',
                onPressed: _addAppointment,
                icon: const Icon(Icons.add_circle_outline)),
          ]),
          if (_isLoadingDashboard)
            const LinearProgressIndicator()
          else if (_appointmentsTableMissing)
            Text(
                'Appointment setup is needed. Run supabase/dashboard_appointments.sql from this app folder in your Supabase SQL editor.',
                style: Theme.of(context).textTheme.bodyMedium)
          else if (appointmentDate == null)
            Text(
                'No upcoming appointments. Add one to keep your care plan close.',
                style: Theme.of(context).textTheme.bodyMedium)
          else ...[
            Text(DateFormat('EEEE, d MMMM · h:mm a').format(appointmentDate),
                style: Theme.of(context).textTheme.titleMedium),
            if (showClinician)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(clinician!.trim(),
                      style: Theme.of(context).textTheme.bodyMedium)),
            if (showLocation)
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(location!.trim(),
                      style: Theme.of(context).textTheme.bodyMedium)),
            if ((appointment?['notes'] as String?)?.isNotEmpty == true)
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(appointment!['notes'] as String,
                      style: Theme.of(context).textTheme.bodyMedium)),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: 4, children: [
                TextButton.icon(
                  onPressed: () => _editAppointment(appointment!),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _cancelAppointment(appointment!),
                  icon: const Icon(Icons.event_busy_outlined, size: 18),
                  label: const Text('Cancel'),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  bool _isMissingMeasurementColumn(PostgrestException error) {
    if (error.code != '42703' && error.code != 'PGRST204') return false;
    const measurementColumns = [
      'bp_systolic_mmhg',
      'bp_diastolic_mmhg',
      'heart_rate_bpm',
      'hrv_ms',
      'spo2_percent',
      'respiratory_rate_per_min',
      'skin_temperature_c',
      'weight_kg',
      'steps_count',
      'measurement_source',
    ];
    final message = error.message.toLowerCase();
    return measurementColumns.any(message.contains);
  }

  Widget _buildWellbeingCard(BuildContext context) {
    final checkIn = _latestCheckIn;
    final date = checkIn == null
        ? null
        : DateTime.tryParse(checkIn['check_in_date'] as String? ?? '')
            ?.toLocal();
    final readings = _wellbeingReadings(checkIn);
    final reflection = _checkInLoadError == null || checkIn != null
        ? _wellbeingReflection(checkIn)
        : null;
    final measurementSource = checkIn?['measurement_source']?.toString();
    final note = checkIn?['notes']?.toString().trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.favorite_border, color: Color(0xFF789080)),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Your wellbeing',
                    style: Theme.of(context).textTheme.titleLarge)),
            TextButton(
                onPressed: _openCheckIn,
                child: Text(_checkedInToday
                    ? 'Edit today’s check-in'
                    : 'Morning check-in')),
          ]),
          Text(
            _checkInLoadError != null && checkIn == null
                ? _checkInLoadError!
                : _checkedInToday
                    ? 'You checked in today · ${DateFormat('d MMM yyyy · h:mm a').format(date!)}'
                    : date == null
                        ? 'Whenever you’re ready, tell us how today is going.'
                        : 'Today is still open · Last check-in ${DateFormat('d MMM · h:mm a').format(date)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Text('What you shared',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_checkInLoadError != null && checkIn == null)
            Row(children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 18, color: Color(0xFF9B5969)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We couldn’t reach your saved check-ins, so this reflection is paused.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ])
          else if (readings.isEmpty)
            Text(
              'No check-in details to reflect on yet. Your answers are optional; start with whatever feels easy.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: readings
                  .map((reading) => _wellbeingReadingChip(reading))
                  .toList(),
            ),
          if (_checkInLoadError != null && checkIn != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: Text(
                  'Your saved check-in is shown; older entries could not refresh.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ]),
          ],
          if (readings.any((reading) => _isMeasurementLabel(reading.key))) ...[
            const SizedBox(height: 8),
            Text(
              measurementSource == null
                  ? 'These readings were entered in your check-in; this app did not measure them.'
                  : 'Source you selected: ${_measurementSourceLabel(measurementSource)}. These readings were entered in your check-in; this app did not measure them.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Your note: $note',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          if (reflection != null) ...[
            Text('A gentle read of today',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(reflection['summary'] as String,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (reflection != null && reflection['pattern'] != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFE3E8)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_outlined,
                      size: 18, color: Color(0xFF70445E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(reflection['pattern'] as String,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ],
          if (reflection != null) ...[
            const SizedBox(height: 16),
            Text('A caring plan for today',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...((reflection['steps'] as List<String>)
                .asMap()
                .entries
                .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5E8ED),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${entry.key + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: const Color(0xFF70445E))),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(entry.value,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ))),
            Text(
              'This is supportive reflection on what you chose to log, not a diagnosis or a check of your or your baby’s health. Follow your care team’s advice. If something feels worrying or gets worse, contact them; urgent or unusual symptoms need prompt medical care.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ]),
      ),
    );
  }

  List<MapEntry<String, String>> _wellbeingReadings(
      Map<String, dynamic>? checkIn) {
    if (checkIn == null) return [];
    final readings = <MapEntry<String, String>>[];
    void addScore(String key, String label, String Function(num) describe) {
      final value = num.tryParse(checkIn[key]?.toString() ?? '');
      if (value != null) readings.add(MapEntry(label, describe(value)));
    }

    String threeLevel(num value, String low, String middle, String high) =>
        value <= 3 ? low : value <= 6 ? middle : high;
    addScore('mood', 'Mood', (value) => threeLevel(value, 'Low', 'Okay', 'Good'));
    addScore('energy', 'Energy', (value) => threeLevel(value, 'Low', 'Some', 'Plenty'));
    addScore('stress', 'Stress', (value) => threeLevel(value, 'Low', 'Some', 'High'));
    addScore('sleep_quality', 'Sleep quality',
        (value) => threeLevel(value, 'Poor', 'Okay', 'Good'));

    final sleep = num.tryParse(checkIn['sleep_duration_hours']?.toString() ?? '');
    if (sleep != null) {
      readings.add(MapEntry('Sleep', '${_formatCheckInNumber(sleep)} hours'));
    }
    final hydration = checkIn['hydration_status']?.toString();
    if (hydration != null && hydration.isNotEmpty) {
      readings.add(MapEntry('Hydration', _capitalize(hydration)));
    }

    final systolic = checkIn['bp_systolic_mmhg'];
    final diastolic = checkIn['bp_diastolic_mmhg'];
    if (systolic != null && diastolic != null) {
      readings.add(MapEntry('Blood pressure', '$systolic/$diastolic mmHg'));
    }
    final measurementFields = <Map<String, String>>[
      {'field': 'heart_rate_bpm', 'label': 'Pulse', 'unit': 'bpm'},
      {'field': 'hrv_ms', 'label': 'Heart rate variability', 'unit': 'ms'},
      {'field': 'spo2_percent', 'label': 'Blood oxygen', 'unit': '%'},
      {
        'field': 'respiratory_rate_per_min',
        'label': 'Breathing rate',
        'unit': 'breaths/min'
      },
      {
        'field': 'skin_temperature_c',
        'label': 'Skin temperature',
        'unit': '°C'
      },
      {'field': 'weight_kg', 'label': 'Weight', 'unit': 'kg'},
      {'field': 'steps_count', 'label': 'Steps', 'unit': 'steps'},
    ];
    for (final measurement in measurementFields) {
      final value = checkIn[measurement['field']];
      if (value != null) {
        readings.add(MapEntry(
            measurement['label']!, '$value ${measurement['unit']}'));
      }
    }
    return readings;
  }

  Widget _wellbeingReadingChip(MapEntry<String, String> reading) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFE3E8)),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(
            text: '${reading.key}: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: reading.value),
        ])),
      );

  bool _isMeasurementLabel(String label) => const {
        'Blood pressure',
        'Pulse',
        'Heart rate variability',
        'Blood oxygen',
        'Breathing rate',
        'Skin temperature',
        'Weight',
        'Steps',
      }.contains(label);

  String _measurementSourceLabel(String source) {
    switch (source) {
      case 'blood_pressure_cuff':
        return 'blood pressure cuff';
      case 'home_device':
        return 'home device';
      case 'clinic':
        return 'clinic or care team';
      case 'wearable':
        return 'wearable display (entered by you)';
      case 'multiple':
        return 'multiple sources';
      case 'other':
        return 'other source';
      default:
        return 'manual entry';
    }
  }

  String _capitalize(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';

  String _formatCheckInNumber(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  Map<String, dynamic> _wellbeingReflection(
      Map<String, dynamic>? checkIn) {
    if (checkIn == null) {
      return {
        'summary':
            'There’s no check-in to reflect on yet, and that’s okay. When you’re ready, we’ll shape today around what you tell us.',
        'pattern': null,
        'steps': <String>[
          'Start with a quick check-in whenever it suits you; share only what you feel comfortable sharing.',
          'Afterwards, come back here for a few gentle ideas based on your answers.',
        ],
      };
    }

    final energy = num.tryParse(checkIn['energy']?.toString() ?? '');
    final stress = num.tryParse(checkIn['stress']?.toString() ?? '');
    final mood = num.tryParse(checkIn['mood']?.toString() ?? '');
    final sleepQuality = num.tryParse(checkIn['sleep_quality']?.toString() ?? '');
    final sleepDuration =
        num.tryParse(checkIn['sleep_duration_hours']?.toString() ?? '');
    final hydration = checkIn['hydration_status']?.toString().toLowerCase();
    final lowMood = mood != null && mood <= 3;
    final highStress = stress != null && stress >= 7;
    final lowEnergy = energy != null && energy <= 3;
    final poorSleep = (sleepQuality != null && sleepQuality <= 3) ||
        (sleepDuration != null && sleepDuration < 6);
    final positiveDay =
        ((mood != null && mood >= 7) || (energy != null && energy >= 7)) &&
        (mood == null || mood >= 4) &&
        (energy == null || energy >= 4) &&
        (stress == null || stress <= 3);

    final recent = _recentCheckIns.take(6).toList();
    String? pattern;
    String? recurringSignal;
    if (recent.length >= 3) {
      final patterns = <MapEntry<String, int>>[
        MapEntry('low mood', recent.where((row) {
          final value = num.tryParse(row['mood']?.toString() ?? '');
          return value != null && value <= 3;
        }).length),
        MapEntry('low energy', recent.where((row) {
          final value = num.tryParse(row['energy']?.toString() ?? '');
          return value != null && value <= 3;
        }).length),
        MapEntry('high stress', recent.where((row) {
          final value = num.tryParse(row['stress']?.toString() ?? '');
          return value != null && value >= 7;
        }).length),
        MapEntry('poor sleep quality', recent.where((row) {
          final value = num.tryParse(row['sleep_quality']?.toString() ?? '');
          return value != null && value <= 3;
        }).length),
        MapEntry('short sleep', recent.where((row) {
          final value = num.tryParse(
              row['sleep_duration_hours']?.toString() ?? '');
          return value != null && value < 6;
        }).length),
        MapEntry('low hydration', recent.where((row) {
          final value = row['hydration_status']?.toString().toLowerCase();
          return value == 'poor' || value == 'fair';
        }).length),
      ];
      patterns.sort((a, b) => b.value.compareTo(a.value));
      final leading = patterns.first;
      if (leading.value >= 2) {
        recurringSignal = leading.key;
        pattern = 'In your last ${recent.length} check-ins, you noted ${leading.key} ${leading.value} times. That’s a pattern in what you’ve logged—not a health judgment. If it keeps coming up, consider sharing it with someone you trust or your care team.';
      }
    }

    final summary = lowMood
        ? 'Thank you for being honest about your mood. This sounds like a day to make things a little less lonely and ask for the care you deserve.'
        : highStress
            ? 'You’ve shared that stress feels high today. Let’s make the next part of the day smaller and bring someone supportive alongside you.'
            : (lowEnergy || poorSleep)
                ? 'You’ve logged low energy or a difficult night. It’s okay to give yourself a softer pace and ask for a hand.'
                : positiveDay
                    ? 'There’s some steadiness in what you shared today. You deserve to enjoy the good moments without needing to fill every minute.'
                    : 'Thank you for checking in. Let’s use what you shared to make the next part of today feel a little more supported.';

    final steps = <String>[];
    if (lowMood) {
      steps.add('Send a simple message to someone you trust: “Today feels heavy. Could you check in with me or keep me company?”');
      steps.add('Pick one small comfort for the next hour—something gentle that feels manageable to you.');
    }
    if (highStress) {
      steps.add('Pause and choose just one next task; let a non-urgent task wait if you can. Ask someone close to help with one thing.');
    }
    if (lowEnergy || poorSleep) {
      steps.add('Make space for a comfortable rest break and ask your support person to take one task off your hands.');
    }
    if (hydration == 'poor' || hydration == 'fair') {
      steps.add('If it feels right for you and your care team has not advised otherwise, keep a drink nearby and sip when you can.');
    }
    if (positiveDay) {
      steps.add('Choose one thing you’d enjoy today and share that good moment with someone close; keep room for breaks, too.');
    }
    // Today's needs come first; use older entries as context after them.
    if (recurringSignal == 'low mood' && !lowMood) {
      steps.add('Low mood has appeared in several recent check-ins, though you marked it as okay today. If it returns or concerns you, consider asking someone you trust for support.');
    } else if (recurringSignal == 'low energy' && !lowEnergy) {
      steps.add('Low energy has come up in several recent check-ins. If it continues, consider mentioning it to your care team.');
    } else if (recurringSignal == 'high stress' && !highStress) {
      steps.add('Stress has felt high in several recent check-ins. If it continues, consider simplifying the day and letting your support person know.');
    } else if ((recurringSignal == 'poor sleep quality' ||
            recurringSignal == 'short sleep') &&
        !poorSleep) {
      steps.add('Difficult or short sleep has come up in several check-ins. If it continues or concerns you, consider mentioning it to your care team.');
    } else if (recurringSignal == 'low hydration' &&
        hydration != 'poor' &&
        hydration != 'fair') {
      steps.add('You’ve marked hydration as poor or fair in several check-ins. If appropriate for you, keep a drink within reach and follow your care team’s advice.');
    }
    if (steps.isEmpty) {
      steps.add('Choose one small thing that would make the next hour feel easier or more enjoyable.');
      steps.add('If you would like company or help, tell someone close what would be useful.');
    }
    steps.add('If how you feel worries you, continues, or gets worse, contact your care team for personal guidance.');

    return {
      'summary': summary,
      'pattern': pattern,
      'steps': steps.take(4).toList(),
    };
  }

  Future<void> _openCheckIn() async {
    if (_isOpeningCheckIn) return;
    _isOpeningCheckIn = true;
    try {
      final savedCheckIn = await Navigator.of(context, rootNavigator: true)
          .push<Map<String, dynamic>>(MaterialPageRoute<Map<String, dynamic>>(
        settings: const RouteSettings(name: '/check-in'),
        builder: (_) => DailyCheckInScreen(
          initialCheckIn: _checkedInToday ? _latestCheckIn : null,
        ),
      ));
      if (!mounted) return;
      if (savedCheckIn != null) {
        final savedId = savedCheckIn['id']?.toString();
        final updatedHistory = [
          savedCheckIn,
          ..._recentCheckIns.where((row) => row['id']?.toString() != savedId),
        ].take(24).toList();
        final savedAt = DateTime.tryParse(
          savedCheckIn['check_in_date']?.toString() ?? '',
        )?.toLocal();
        final now = DateTime.now();
        setState(() {
          _latestCheckIn = savedCheckIn;
          _recentCheckIns = updatedHistory;
          _checkedInToday = savedAt != null &&
              savedAt.year == now.year &&
              savedAt.month == now.month &&
              savedAt.day == now.day;
          _checkInLoadError = null;
        });
      }
      await _loadDashboardData();
      if (savedCheckIn != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
                content: Text('Check-in saved. Your wellbeing has been updated.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open check-in. Please try again.')),
        );
      }
    } finally {
      _isOpeningCheckIn = false;
    }
  }

  Widget _buildSymptomsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.health_and_safety_outlined,
                color: Color(0xFF70445E)),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Recent symptoms',
                    style: Theme.of(context).textTheme.titleLarge)),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, '/symptoms')
                    .then((_) => _loadDashboardData()),
                child: const Text('Log')),
          ]),
          if (_isLoadingDashboard)
            const LinearProgressIndicator()
          else if (_recentSymptoms.isEmpty)
            Text('No symptoms logged recently.',
                style: Theme.of(context).textTheme.bodyMedium)
          else
            ..._recentSymptoms.map((symptom) {
              final loggedAt =
                  DateTime.tryParse(symptom['log_date'] as String? ?? '')
                      ?.toLocal();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(symptom['symptom_name'] as String? ?? 'Symptom'),
                subtitle: Text(loggedAt == null
                    ? 'Self-reported'
                    : 'Self-reported · ${DateFormat('d MMM').format(loggedAt)}'),
                trailing: Text('${symptom['severity'] ?? '—'}/10',
                    style: Theme.of(context).textTheme.titleMedium),
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
      onPressed: route == '/check-in'
          ? _openCheckIn
          : () => Navigator.pushNamed(context, route),
      icon: Icon(icon, color: accentColor),
      label: Text(label),
      style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF70445E),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          side: const BorderSide(color: Color(0xFFE7E0E3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }

  Widget _buildBabyGrowthSection() {
    final week = _pregnancyWeekNumber;
    final comparison = _growthComparison(_selectedGrowthWeek);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF70445E)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Baby growth',
                      style: Theme.of(context).textTheme.titleLarge)),
              DropdownButton<int>(
                value: _selectedGrowthWeek,
                underline: const SizedBox.shrink(),
                items: List.generate(
                    42,
                    (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('Week ${index + 1}'),
                        )),
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedGrowthWeek = value);
                },
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E8ED),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR JOURNEY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.4,
                            color: const Color(0xFF70445E),
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 6),
                  Text(_activeStage,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 20)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 7,
                      backgroundColor: Colors.white,
                      color: const Color(0xFF70445E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(_progress * 100).round()}% of the 40-week journey',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.event_available_outlined,
                        size: 18, color: Color(0xFF70445E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Estimated due date not set'
                            : 'Due date · ${DateFormat('d MMM yyyy').format(_dueDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _editPregnancyDate,
                      child: Text(_lmpDate == null ? 'Set dates' : 'Edit'),
                    ),
                  ]),
                  if (_profileDatesInvalid)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'The saved dates need review. Edit one date to recalculate the pair.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (_dateConflictDays != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'The saved dates differ from the 280-day estimate by ${_dateConflictDays!.abs()} days. Confirm your dates with your clinician.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (_profileNotes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Profile note · $_profileNotes',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 440;
              return Container(
                height: compact ? 186 : 178,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF5F3), Color(0xFFF5ECF2)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  SizedBox(
                    width: compact ? 104 : 150,
                    height: 160,
                    child: CustomPaint(painter: const _GrowthBabyPainter()),
                  ),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 18, 16),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              week == null
                                  ? 'Educational week $_selectedGrowthWeek'
                                  : 'Estimated $_currentWeek',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: const Color(0xFF70445E))),
                          const SizedBox(height: 6),
                          Text(
                              'A size comparison for selected week $_selectedGrowthWeek.',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ]),
                  )),
                ]),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F4),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: Color(0xFFEAF0E9), shape: BoxShape.circle),
                    child: const Icon(Icons.spa_outlined,
                        color: Color(0xFF789080), size: 21)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('A size comparison',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(comparison,
                          style: Theme.of(context).textTheme.titleMedium),
                    ])),
              ]),
            ),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFF789080)),
              const SizedBox(width: 7),
              Expanded(
                  child: Text(
                'Illustration and fruit comparison are educational only, not a scan, measurement, or medical assessment.',
                style: Theme.of(context).textTheme.bodySmall,
              )),
            ]),
            const SizedBox(height: 8),
            Text(
                'The selected week changes this fruit comparison only. Week-specific illustrations and reviewed growth information are not available yet. Ask your clinician about growth measurements.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String _growthComparison(int week) {
    if (week <= 5) return 'poppy seed';
    if (week <= 7) return 'blueberry';
    if (week <= 9) return 'raspberry';
    if (week <= 11) return 'strawberry';
    if (week <= 12) return 'plum';
    if (week <= 13) return 'peach';
    if (week <= 15) return 'lemon';
    if (week <= 17) return 'avocado';
    if (week <= 19) return 'bell pepper';
    if (week <= 21) return 'banana';
    if (week <= 23) return 'papaya';
    if (week <= 25) return 'courgette';
    if (week <= 26) return 'cucumber';
    if (week <= 27) return 'zucchini';
    if (week <= 28) return 'aubergine';
    if (week <= 29) return 'butternut squash';
    if (week <= 31) return 'cabbage';
    if (week <= 33) return 'pineapple';
    if (week <= 35) return 'cantaloupe';
    if (week <= 37) return 'romaine lettuce';
    if (week <= 39) return 'honeydew melon';
    if (week <= 40) return 'watermelon';
    return 'pumpkin';
  }
}

class _GrowthBabyPainter extends CustomPainter {
  const _GrowthBabyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 4);

    final shadow = Paint()..color = const Color(0x2270445E);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(1, 55), width: 68, height: 12),
        shadow);

    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.55, -0.55),
        colors: [Color(0xFFFFE2D1), Color(0xFFF4BFAE), Color(0xFFD88F88)],
      ).createShader(Rect.fromLTWH(-44, -20, 94, 94));
    final body = Path()
      ..moveTo(-3, -14)
      ..cubicTo(29, -17, 43, 8, 33, 30)
      ..cubicTo(27, 45, 8, 50, -8, 40)
      ..cubicTo(-20, 33, -27, 18, -19, 5)
      ..cubicTo(-14, -4, -10, -10, -3, -14)
      ..close();
    canvas.drawShadow(body, const Color(0x3370445E), 8, false);
    canvas.drawPath(body, bodyPaint);

    final limbPaint = Paint()
      ..color = const Color(0xFFF0B8A5)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final legs = Path()
      ..moveTo(14, 31)
      ..cubicTo(30, 40, 23, 52, 8, 44)
      ..moveTo(-1, 34)
      ..cubicTo(-13, 47, -23, 38, -13, 28);
    canvas.drawPath(legs, limbPaint);

    final headPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.55, -0.6),
        colors: [Color(0xFFFFE8D8), Color(0xFFFFCBB4), Color(0xFFE7A28E)],
      ).createShader(
          Rect.fromCircle(center: const Offset(-18, -20), radius: 33));
    canvas.drawCircle(const Offset(-18, -20), 27, headPaint);
    canvas.drawCircle(
        const Offset(-26, -29), 7, Paint()..color = const Color(0x55FFFFFF));

    final armPaint = Paint()
      ..color = const Color(0xFFF8C7B1)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arm = Path()
      ..moveTo(-4, 3)
      ..cubicTo(8, 2, 16, 12, 10, 21);
    canvas.drawPath(arm, armPaint);

    final facePaint = Paint()..color = const Color(0xFF70445E);
    canvas.drawCircle(const Offset(-27, -20), 1.7, facePaint);
    canvas.drawCircle(const Offset(-13, -20), 1.7, facePaint);
    final smile = Path()
      ..moveTo(-24, -11)
      ..quadraticBezierTo(-20, -7, -16, -11);
    canvas.drawPath(
        smile,
        Paint()
          ..color = const Color(0xFFB46D70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        const Offset(-31, -13), 3, Paint()..color = const Color(0x66E88E8C));
    canvas.drawCircle(
        const Offset(-9, -13), 3, Paint()..color = const Color(0x66E88E8C));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GrowthBabyPainter oldDelegate) => false;
}

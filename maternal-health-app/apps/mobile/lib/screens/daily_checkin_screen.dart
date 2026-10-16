import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key, this.initialCheckIn});

  final Map<String, dynamic>? initialCheckIn;

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _sleepController = TextEditingController();
  final _sleepQualityController = TextEditingController();
  final _moodController = TextEditingController();
  final _energyController = TextEditingController();
  final _stressController = TextEditingController();
  final _notesController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _hrvController = TextEditingController();
  final _oxygenController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _skinTemperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _stepsController = TextEditingController();
  bool _isSubmitting = false;
  String _measurementSource = 'manual';

  final List<String> _hydrationOptions = ['poor', 'fair', 'good', 'excellent'];
  String? _selectedHydration;

  @override
  void initState() {
    super.initState();
    final checkIn = widget.initialCheckIn;
    if (checkIn != null) {
      _sleepController.text = checkIn['sleep_duration_hours']?.toString() ?? '';
      _sleepQualityController.text = checkIn['sleep_quality']?.toString() ?? '';
      _moodController.text = checkIn['mood']?.toString() ?? '';
      _energyController.text = checkIn['energy']?.toString() ?? '';
      _stressController.text = checkIn['stress']?.toString() ?? '';
      _notesController.text = checkIn['notes']?.toString() ?? '';
      _systolicController.text = checkIn['bp_systolic_mmhg']?.toString() ?? '';
      _diastolicController.text = checkIn['bp_diastolic_mmhg']?.toString() ?? '';
      _heartRateController.text = checkIn['heart_rate_bpm']?.toString() ?? '';
      _hrvController.text = checkIn['hrv_ms']?.toString() ?? '';
      _oxygenController.text = checkIn['spo2_percent']?.toString() ?? '';
      _respiratoryRateController.text =
          checkIn['respiratory_rate_per_min']?.toString() ?? '';
      _skinTemperatureController.text =
          checkIn['skin_temperature_c']?.toString() ?? '';
      _weightController.text = checkIn['weight_kg']?.toString() ?? '';
      _stepsController.text = checkIn['steps_count']?.toString() ?? '';
      _selectedHydration = checkIn['hydration_status']?.toString();
      _measurementSource =
          checkIn['measurement_source']?.toString() ?? 'manual';
    }
  }

  @override
  void dispose() {
    _sleepController.dispose();
    _sleepQualityController.dispose();
    _moodController.dispose();
    _energyController.dispose();
    _stressController.dispose();
    _notesController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _hrvController.dispose();
    _oxygenController.dispose();
    _respiratoryRateController.dispose();
    _skinTemperatureController.dispose();
    _weightController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckIn() async {
    if (_isSubmitting) return;
    if (_selectedHydration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select hydration status')),
      );
      return;
    }
    final sleep = double.tryParse(_sleepController.text);
    final enteredScores = [
      _sleepQualityController.text,
      _moodController.text,
      _energyController.text,
      _stressController.text
    ].where((value) => value.trim().isNotEmpty).map(int.tryParse).toList();
    if ((_sleepController.text.trim().isNotEmpty &&
            (sleep == null || sleep < 0 || sleep > 24)) ||
        enteredScores
            .any((value) => value == null || value < 1 || value > 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Enter sleep from 0–24 hours and sleep quality, mood, energy, and stress from 1–10.')),
      );
      return;
    }

    late final double? systolic;
    late final double? diastolic;
    late final double? heartRate;
    late final double? hrv;
    late final double? oxygen;
    late final double? respiratoryRate;
    late final double? skinTemperature;
    late final double? weight;
    late final double? steps;
    try {
      systolic = _parseOptionalReading(
          _systolicController, 'Systolic pressure', 1, 300,
          wholeNumber: true);
      diastolic = _parseOptionalReading(
          _diastolicController, 'Diastolic pressure', 1, 200,
          wholeNumber: true);
      if ((systolic == null) != (diastolic == null)) {
        throw const FormatException(
            'Enter both systolic and diastolic blood pressure.');
      }
      if (systolic != null && diastolic != null && systolic <= diastolic) {
        throw const FormatException(
            'Systolic pressure must be higher than diastolic pressure.');
      }
      heartRate = _parseOptionalReading(
          _heartRateController, 'Heart rate', 20, 240,
          wholeNumber: true);
      hrv = _parseOptionalReading(_hrvController, 'Heart rate variability', 0,
          500);
      oxygen = _parseOptionalReading(
          _oxygenController, 'Blood oxygen', 50, 100);
      respiratoryRate = _parseOptionalReading(
          _respiratoryRateController, 'Breathing rate', 4, 80,
          wholeNumber: true);
      skinTemperature = _parseOptionalReading(
          _skinTemperatureController, 'Skin temperature', 20, 45);
      weight = _parseOptionalReading(_weightController, 'Weight', 20, 300);
      steps = _parseOptionalReading(_stepsController, 'Steps', 0, 200000,
          wholeNumber: true);
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profileId = await ProfileService.motherProfileId();
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final nextDayStart = dayStart.add(const Duration(days: 1));
      final sameDayCheckIn = widget.initialCheckIn ?? await _supabase
          .from('daily_check_ins')
          .select('id,check_in_date')
          .eq('mother_profile_id', profileId)
          .gte('check_in_date', dayStart.toUtc().toIso8601String())
          .lt('check_in_date', nextDayStart.toUtc().toIso8601String())
          .order('check_in_date', ascending: false)
          .limit(1)
          .maybeSingle();
      final checkInTimestamp =
          sameDayCheckIn?['check_in_date'] as String? ??
              now.toUtc().toIso8601String();
      final values = {
        'mother_profile_id': profileId,
        'check_in_date': checkInTimestamp,
        'sleep_duration_hours': sleep,
        'sleep_quality': int.tryParse(_sleepQualityController.text),
        'mood': int.tryParse(_moodController.text),
        'energy': int.tryParse(_energyController.text),
        'stress': int.tryParse(_stressController.text),
        'hydration_status': _selectedHydration,
        'notes':
            _notesController.text.isNotEmpty ? _notesController.text : null,
      };
      final measurements = <String, dynamic>{
        'bp_systolic_mmhg': systolic?.toInt(),
        'bp_diastolic_mmhg': diastolic?.toInt(),
        'heart_rate_bpm': heartRate?.toInt(),
        'hrv_ms': hrv,
        'spo2_percent': oxygen,
        'respiratory_rate_per_min': respiratoryRate?.toInt(),
        'skin_temperature_c': skinTemperature,
        'weight_kg': weight,
        'steps_count': steps?.toInt(),
      };
      if (measurements.values.any((value) => value != null)) {
        values.addAll(measurements);
        values['measurement_source'] = _measurementSource;
      }
      final savedCheckIn = sameDayCheckIn == null
          ? await _supabase
              .from('daily_check_ins')
              .insert(values)
              .select()
              .single()
          : await _supabase
              .from('daily_check_ins')
              .update(values)
              .eq('id', sameDayCheckIn['id'] as String)
              .eq('mother_profile_id', profileId)
              .select()
              .single();

      if (!mounted) return;
      Navigator.of(context).pop(Map<String, dynamic>.from(savedCheckIn));
    } on PostgrestException catch (error) {
      if (!mounted) return;
      debugPrint('Check-in save failed (${error.code}): ${error.message}; '
          '${error.details ?? ''}; ${error.hint ?? ''}');
      final message = switch (error.code) {
        '42501' => 'Your check-in could not be saved because your account does not have permission. Please sign out and back in, then try again.',
        '23514' => 'One of the readings is outside the accepted range. Please review your entries and try again.',
        '23503' => 'Your pregnancy profile could not be matched to this check-in. Please reopen your profile and try again.',
        'PGRST204' || '42703' => 'The database is missing a check-in field this version needs. Your answers were not saved; please contact support.',
        _ => 'We couldn’t save your check-in. ${error.message}',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$message (Code: ${error.code})')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('We couldn’t save your check-in: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  double? _parseOptionalReading(
    TextEditingController controller,
    String label,
    double minimum,
    double maximum, {
    bool wholeNumber = false,
  }) {
    final input = controller.text.trim();
    if (input.isEmpty) return null;
    final value = double.tryParse(input);
    if (value == null ||
        !value.isFinite ||
        value < minimum ||
        value > maximum ||
        (wholeNumber && value != value.roundToDouble())) {
      final format = wholeNumber ? 'whole number' : 'number';
      throw FormatException(
          '$label must be a $format from $minimum to $maximum.');
    }
    return value;
  }

  Widget _buildMeasurementField(
      String label, TextEditingController controller, String unit,
      {bool wholeNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !wholeNumber),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-in'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth.clamp(0.0, 760.0).toDouble(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 28,
                  vertical: 20,
                ),
                child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling today?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'A few quick notes can help shape a caring plan for your day. Most answers are optional; choose a hydration status to save.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'There are no right or wrong answers. Choose what feels closest; you can skip any score.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'One check-in is saved for each day. Morning is a good time to share how you’re feeling; your plan will stay here to guide the rest of the day.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 22),

              // Sleep
              _buildFieldRow(
                Icons.bed,
                'Sleep Duration (hours)',
                _sleepController,
              ),
              const SizedBox(height: 16),
              _buildScoreRow(
                Icons.nights_stay_outlined,
                'Sleep quality',
                'How restful did your sleep feel?',
                _sleepQualityController,
              ),
              const SizedBox(height: 16),

              Text('Mood and energy',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              if (compact) ...[
                _buildScoreRow(Icons.emoji_emotions_outlined, 'Mood',
                    'How has your mood felt?', _moodController),
                const SizedBox(height: 16),
                _buildScoreRow(Icons.bolt, 'Energy',
                    'How much energy do you have?', _energyController),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildScoreRow(Icons.emoji_emotions_outlined,
                          'Mood', 'How has your mood felt?', _moodController),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildScoreRow(Icons.bolt, 'Energy',
                          'How much energy do you have?', _energyController),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _buildScoreRow(Icons.self_improvement_outlined, 'Stress',
                  'How stressed have you felt?', _stressController),
              const SizedBox(height: 16),

              // Hydration
              const Text(
                'Hydration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('Choose the option that best describes you right now.',
                  style: Theme.of(context).textTheme.bodySmall),
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
                    child: Text(
                        '${hydration[0].toUpperCase()}${hydration.substring(1)}'),
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

              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: const Text('Optional health readings'),
                subtitle: const Text('Enter only values you have measured'),
                children: [
                  Text(
                    'These are typed in by you; the app does not read or measure them. Source applies to all readings entered in this check-in.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wearable blood-pressure features vary and may require cuff calibration. This log does not assess reading accuracy or guide treatment.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _measurementSource,
                    decoration: const InputDecoration(
                      labelText: 'Reading source',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'manual', child: Text('Manual measurement')),
                      DropdownMenuItem(
                          value: 'wearable',
                          child: Text('Wearable display')),
                      DropdownMenuItem(
                          value: 'blood_pressure_cuff',
                          child: Text('Blood pressure cuff')),
                      DropdownMenuItem(
                          value: 'home_device',
                          child: Text('Other home device')),
                      DropdownMenuItem(
                          value: 'clinic', child: Text('Clinic or care team')),
                      DropdownMenuItem(
                          value: 'multiple', child: Text('Multiple sources')),
                      DropdownMenuItem(
                          value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(
                        () => _measurementSource = value ?? 'manual'),
                  ),
                  _buildMeasurementField('Systolic blood pressure',
                      _systolicController, 'mmHg',
                      wholeNumber: true),
                  _buildMeasurementField('Diastolic blood pressure',
                      _diastolicController, 'mmHg',
                      wholeNumber: true),
                  _buildMeasurementField(
                      'Pulse / heart rate', _heartRateController, 'bpm',
                      wholeNumber: true),
                  _buildMeasurementField(
                      'Heart rate variability', _hrvController, 'ms'),
                  _buildMeasurementField(
                      'Blood oxygen (SpO₂)', _oxygenController, '%'),
                  _buildMeasurementField('Breathing rate',
                      _respiratoryRateController, 'breaths/min',
                      wholeNumber: true),
                  _buildMeasurementField(
                      'Skin / wrist temperature', _skinTemperatureController, '°C'),
                  _buildMeasurementField(
                      'Weight (scale/device)', _weightController, 'kg'),
                  _buildMeasurementField(
                      'Steps', _stepsController, 'steps',
                      wholeNumber: true),
                ],
              ),
              const SizedBox(height: 8),

              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Anything else? (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add a note for your personal record',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitCheckIn,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSubmitting
                      ? 'Saving…'
                      : widget.initialCheckIn == null
                          ? 'Save today’s check-in'
                          : 'Update today’s check-in'),
                ),
              ),
            ],
                ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldRow(IconData icon, String label,
      TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF880E4F)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF880E4F))),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'For example, 7.5',
            suffixText: 'hours',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildScoreRow(
    IconData icon,
    String label,
    String scaleDescription,
    TextEditingController controller,
  ) {
    final selectedScore = int.tryParse(controller.text);
    final selectedChoice = selectedScore == null
        ? null
        : selectedScore <= 3
            ? 0
            : selectedScore <= 7
                ? 1
                : 2;
    final choices = _scoreChoices(label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF880E4F)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF880E4F))),
        ]),
        const SizedBox(height: 4),
        Text(scaleDescription,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: List<Widget>.generate(choices.length, (index) {
            return Semantics(
              label: choices[index],
              button: true,
              selected: selectedChoice == index,
              child: ChoiceChip(
                label: Text(choices[index]),
                selected: selectedChoice == index,
                onSelected: (_) {
                  controller.text = (index == 0 ? 2 : index == 1 ? 5 : 9)
                      .toString();
                  setState(() {});
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  List<String> _scoreChoices(String label) {
    final key = label.toLowerCase();
    if (key == 'stress') return const ['Low', 'Some', 'High'];
    if (key == 'sleep quality') return const ['Poor', 'Okay', 'Good'];
    if (key == 'energy') return const ['Low', 'Some', 'Plenty'];
    return const ['Low', 'Okay', 'Good'];
  }
}

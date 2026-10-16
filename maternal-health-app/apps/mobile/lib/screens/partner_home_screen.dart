import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mother_home_screen.dart'
    show
        BabyGrowthCard,
        partnerConnectionError,
        signOutOfCareApp,
        wellbeingReflection,
        wellbeingScoreLabel;

class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  String? _connectionId;
  Map<String, dynamic> _sharedData = {};
  List<Map<String, dynamic>> _messages = [];
  Timer? _refreshTimer;
  bool _refreshing = false;
  int _loadGeneration = 0;
  int? _selectedGrowthWeek;

  @override
  void initState() {
    super.initState();
    _loadPartnerHome();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_loading && !_sending) _loadPartnerHome(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerHome({bool silent = false}) async {
    if (!mounted || (silent && _refreshing)) return;
    final generation = ++_loadGeneration;
    _refreshing = true;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw StateError('Please sign in to continue.');
      final connection = await _supabase
          .from('caregiver_connections')
          .select('id,share_preferences')
          .eq('partner_user_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 20));
      if (!mounted || generation != _loadGeneration) return;
      if (connection == null) {
        setState(() {
          _connectionId = null;
          _sharedData = {};
          _messages = [];
          _selectedGrowthWeek = null;
          _loading = false;
          _error = null;
        });
        return;
      }

      final connectionId = connection['id'] as String;
      final sharedResult = await _supabase.rpc('get_partner_shared_data',
          params: {
            'p_connection_id': connectionId
          }).timeout(const Duration(seconds: 20));
      final sharedData = sharedResult is Map
          ? Map<String, dynamic>.from(sharedResult)
          : <String, dynamic>{};
      final messagesResult = await _supabase
          .from('care_messages')
          .select('id,sender_user_id,body,sent_at')
          .eq('connection_id', connectionId)
          .order('sent_at', ascending: false)
          .limit(40)
          .timeout(const Duration(seconds: 20));
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _connectionId = connectionId;
        _sharedData = sharedData;
        _messages =
            List<Map<String, dynamic>>.from(messagesResult).reversed.toList();
        _loading = false;
        _error = null;
        if (sharedData['pregnancy_progress'] is! Map) {
          _selectedGrowthWeek = null;
        }
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _error = partnerConnectionError(error);
        _sharedData = {};
        _messages = [];
      });
    } finally {
      if (generation == _loadGeneration) _refreshing = false;
    }
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    final connectionId = _connectionId;
    final user = _supabase.auth.currentUser;
    if (body.isEmpty || connectionId == null || user == null || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await _supabase
          .from('care_messages')
          .insert({
            'connection_id': connectionId,
            'sender_user_id': user.id,
            'body': body,
          })
          .select('id')
          .single();
      if (!mounted) return;
      _messageController.clear();
      await _loadPartnerHome();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not send message: $error')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MatruCare'),
        actions: [
          IconButton(
            tooltip: 'Refresh shared information',
            onPressed: _loading ? null : _loadPartnerHome,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () => signOutOfCareApp(context)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _connectionId == null && _error == null
              ? _buildNotConnected(context)
              : _error != null
                  ? _buildLoadError(context)
                  : _buildConnectedHome(context),
    );
  }

  Widget _buildNotConnected(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border,
                        size: 42, color: Color(0xFF70445E)),
                    const SizedBox(height: 12),
                    Text('Your shared care space is waiting',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                        'Ask the Mother to connect your MatruCare account using this email address: ${_supabase.auth.currentUser?.email ?? 'your account email'}. She chooses what information to share.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadPartnerHome,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check connection'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildLoadError(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        color: Color(0xFF9B5969), size: 36),
                    const SizedBox(height: 8),
                    Text('We couldn’t load your shared care space',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _loadPartnerHome,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildConnectedHome(BuildContext context) {
    final hasSharedInfo = _sharedData.isNotEmpty;
    return RefreshIndicator(
      onRefresh: _loadPartnerHome,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text('Here for her, together',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
              'Your partner chooses what to share with you. Ask how she would like your support today.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (hasSharedInfo) ...[
            if (_sharedData['pregnancy_progress'] is Map)
              _buildPregnancyProgress(
                  context,
                  Map<String, dynamic>.from(
                      _sharedData['pregnancy_progress'] as Map)),
            if (_sharedData['daily_wellbeing'] is List)
              _buildWellbeing(context,
                  List<dynamic>.from(_sharedData['daily_wellbeing'] as List)),
            if (_sharedData['symptoms'] is List)
              _buildSymptoms(
                  context, List<dynamic>.from(_sharedData['symptoms'] as List)),
            if (_sharedData['measurements'] is List)
              _buildMeasurements(context,
                  List<dynamic>.from(_sharedData['measurements'] as List)),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nothing shared yet',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                        'She has not enabled any shared categories. You can still send a message, and she can change sharing choices at any time.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildConversation(context),
        ],
      ),
    );
  }

  Widget _buildPregnancyProgress(
      BuildContext context, Map<String, dynamic> progress) {
    final rawLmpDate = progress['lmp_date']?.toString();
    final rawDueDate = progress['edd_date']?.toString();
    final dueDate = rawDueDate == null ? null : DateTime.tryParse(rawDueDate);
    final lmpDate = rawLmpDate == null
        ? (dueDate == null ? null : dueDate.subtract(const Duration(days: 280)))
        : DateTime.tryParse(rawLmpDate);
    final gestationDays = lmpDate == null || lmpDate.isAfter(DateTime.now())
        ? null
        : DateTime.now()
            .difference(DateTime(lmpDate.year, lmpDate.month, lmpDate.day))
            .inDays;
    final week = gestationDays == null
        ? null
        : (gestationDays ~/ 7).clamp(0, 42).toInt();
    final day = gestationDays == null ? null : gestationDays % 7;
    final trimester = week == null
        ? null
        : week < 13
            ? 1
            : week < 28
                ? 2
                : 3;
    final selectedWeek =
        _selectedGrowthWeek ?? (week ?? 1).clamp(1, 42).toInt();
    final conflictDays = lmpDate != null && dueDate != null
        ? dueDate.difference(lmpDate.add(const Duration(days: 280))).inDays
        : null;
    return BabyGrowthCard(
      week: week,
      weekLabel: week == null ? '—' : 'Week $week · Day $day',
      stage: week == null
          ? 'Pregnancy dates need to be set or reviewed'
          : 'Trimester $trimester · Week $week, day $day',
      progress: gestationDays == null
          ? 0
          : (gestationDays / 280).clamp(0.0, 1.0).toDouble(),
      selectedWeek: selectedWeek,
      onWeekChanged: (value) => setState(() => _selectedGrowthWeek = value),
      dueDate: dueDate,
      datesInvalid: lmpDate != null && lmpDate.isAfter(DateTime.now()),
      conflictDays:
          conflictDays != null && conflictDays.abs() > 14 ? conflictDays : null,
    );
  }

  Widget _buildWellbeing(BuildContext context, List<dynamic> checkIns) {
    final entries = checkIns
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    entries.sort((a, b) => (b['check_in_date']?.toString() ?? '')
        .compareTo(a['check_in_date']?.toString() ?? ''));
    final latest = entries.isEmpty ? null : entries.first;
    final checkedAt =
        DateTime.tryParse(latest?['check_in_date']?.toString() ?? '')
            ?.toLocal();
    final now = DateTime.now();
    final isToday = checkedAt != null &&
        checkedAt.year == now.year &&
        checkedAt.month == now.month &&
        checkedAt.day == now.day;
    final reflection = latest == null
        ? null
        : wellbeingReflection(latest, recentCheckIns: entries);
    return Card(
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.favorite_border, color: Color(0xFF789080)),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Her daily check-in',
                    style: Theme.of(context).textTheme.titleLarge)),
          ]),
          const SizedBox(height: 8),
          if (latest == null)
            const Text('No daily check-in has been shared yet.')
          else ...[
            Text(
                '${isToday ? 'Today’s check-in' : 'Last shared check-in'} · ${_formatDate(latest['check_in_date'])}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            _checkInReadings(latest),
            const SizedBox(height: 8),
            if (!isToday)
              const Text(
                  'No shared check-in for today yet. This older entry is history; it does not tell us how she feels today.')
            else if (reflection != null) ...[
              Text('Her reflection',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(reflection['summary'] as String),
              const SizedBox(height: 12),
              Text('Her care plan for today',
                  style: Theme.of(context).textTheme.titleMedium),
              if (reflection['modelNote'] != null) ...[
                const SizedBox(height: 6),
                Text(reflection['modelNote'] as String,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 4),
              const Text(
                  'These are the same suggestions she sees, based on her check-in. Ask what she would like help with.'),
              const SizedBox(height: 8),
              ..._planSteps(reflection['steps'] as List<String>),
              const SizedBox(height: 8),
              Text('How you can help',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._planSteps(reflection['partnerSteps'] as List<String>),
              Text(
                  'Support ideas based on what she reported, not a diagnosis. Follow her care team’s advice; contact them if she is worried or feels worse.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (entries.length > 1)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Previous shared check-ins'),
                children: entries
                    .skip(1)
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatDate(entry['check_in_date']),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                _checkInReadings(entry),
                              ]),
                        ))
                    .toList(),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _checkInReadings(Map<String, dynamic> entry) {
    const labels = {
      'mood': 'Mood',
      'energy': 'Energy',
      'stress': 'Stress',
      'sleep_quality': 'Sleep quality'
    };
    final hasReadings = labels.keys.any((key) => entry[key] != null) ||
        entry['sleep_duration_hours'] != null ||
        entry['hydration_status'] != null;
    if (!hasReadings) {
      return const Text('No wellbeing answers were included in this check-in.');
    }
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final field in labels.entries)
        if (entry[field.key] != null)
          _dataChip(
              field.value, wellbeingScoreLabel(field.key, entry[field.key])),
      if (entry['sleep_duration_hours'] != null)
        _dataChip('Sleep', '${entry['sleep_duration_hours']} hours'),
      if (entry['hydration_status'] != null)
        _dataChip(
            'Hydration', _capitalize(entry['hydration_status'].toString())),
    ]);
  }

  List<Widget> _planSteps(List<String> steps) => steps
      .asMap()
      .entries
      .map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${entry.key + 1}. '),
              Expanded(child: Text(entry.value)),
            ]),
          ))
      .toList();

  Widget _buildSymptoms(BuildContext context, List<dynamic> symptoms) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.health_and_safety_outlined,
                    color: Color(0xFF70445E)),
                const SizedBox(width: 8),
                Text('Symptoms she chose to share',
                    style: Theme.of(context).textTheme.titleLarge),
              ]),
              const SizedBox(height: 6),
              if (symptoms.isEmpty)
                const Text('No symptom entries have been shared.')
              else
                ...symptoms.take(5).map((item) {
                  final symptom = Map<String, dynamic>.from(item as Map);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title:
                        Text(symptom['symptom_name']?.toString() ?? 'Symptom'),
                    subtitle:
                        Text('Logged ${_formatDate(symptom['log_date'])}'),
                    trailing: Text('${symptom['severity'] ?? '—'}/10'),
                  );
                }),
              Text('These are self-reported entries, not a diagnosis.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );

  Widget _buildMeasurements(BuildContext context, List<dynamic> measurements) {
    final latest = measurements.isEmpty
        ? null
        : Map<String, dynamic>.from(measurements.first as Map);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.monitor_heart_outlined, color: Color(0xFF789080)),
            const SizedBox(width: 8),
            Text('Measurements she shared',
                style: Theme.of(context).textTheme.titleLarge),
          ]),
          if (latest == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No manual measurements have been shared.'),
            )
          else ...[
            const SizedBox(height: 4),
            Text('Latest entry · ${_formatDate(latest['check_in_date'])}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (latest['bp_systolic_mmhg'] != null &&
                  latest['bp_diastolic_mmhg'] != null)
                _dataChip('Blood pressure',
                    '${latest['bp_systolic_mmhg']}/${latest['bp_diastolic_mmhg']} mmHg'),
              if (latest['heart_rate_bpm'] != null)
                _dataChip('Pulse', '${latest['heart_rate_bpm']} bpm'),
              if (latest['spo2_percent'] != null)
                _dataChip('Blood oxygen', '${latest['spo2_percent']}%'),
              if (latest['weight_kg'] != null)
                _dataChip('Weight', '${latest['weight_kg']} kg'),
              if (latest['steps_count'] != null)
                _dataChip('Steps', '${latest['steps_count']}'),
              if (latest['hrv_ms'] != null)
                _dataChip('HRV', '${latest['hrv_ms']} ms'),
              if (latest['respiratory_rate_per_min'] != null)
                _dataChip('Breathing rate',
                    '${latest['respiratory_rate_per_min']}/min'),
              if (latest['skin_temperature_c'] != null)
                _dataChip('Temperature', '${latest['skin_temperature_c']} °C'),
            ]),
            const SizedBox(height: 8),
            Text(
                'Entered from ${_sourceLabel(latest['measurement_source']?.toString())}. MatruCare does not measure or assess these readings.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ]),
      ),
    );
  }

  Widget _buildConversation(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.chat_bubble_outline, color: Color(0xFF70445E)),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Your conversation',
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
              tooltip: 'Refresh messages',
              onPressed: _loadPartnerHome,
              icon: const Icon(Icons.refresh),
            ),
          ]),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEFE3E8)),
            ),
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                          'Send her a kind note or ask what support would help today.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      final isMine = message['sender_user_id'] == currentUserId;
                      final sentAt = DateTime.tryParse(
                              message['sent_at']?.toString() ?? '')
                          ?.toLocal();
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isMine ? const Color(0xFFF1E8ED) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message['body']?.toString() ?? ''),
                              if (sentAt != null)
                                Text(
                                    DateFormat('d MMM · h:mm a').format(sentAt),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Text('Messages refresh every 15 seconds while this page is open.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_sending,
                minLines: 1,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'Write her a message…',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: _sending ? null : _sendMessage,
              icon: const Icon(Icons.send),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _dataChip(String label, String value) => Chip(
        label: Text('$label · $value'),
        backgroundColor: const Color(0xFFFFF8FA),
        side: const BorderSide(color: Color(0xFFEFE3E8)),
      );

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null
        ? 'date not available'
        : DateFormat('d MMM · h:mm a').format(date);
  }

  String _capitalize(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';

  String _sourceLabel(String? source) {
    switch (source) {
      case 'blood_pressure_cuff':
        return 'a blood pressure cuff';
      case 'home_device':
        return 'a home device';
      case 'clinic':
        return 'the clinic or care team';
      case 'wearable':
        return 'a wearable display entered by her';
      case 'multiple':
        return 'multiple sources';
      case 'other':
        return 'another source';
      default:
        return 'manual entry';
    }
  }
}

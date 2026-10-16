import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final _client = Supabase.instance.client;

  static Future<String> homeRoute() => resolveCareHomeRoute(_client);

  static Future<String> motherProfileId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Please sign in first.');
    final row = await _client
        .from('pregnancy_profiles')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) {
      throw StateError(
          'Pregnancy profile is missing. Select the mother role and try again.');
    }
    return row['id'] as String;
  }
}

Future<String> resolveCareHomeRoute(SupabaseClient client) async {
  final user = client.auth.currentUser;
  if (user == null) return '/login';
  final profile = await client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();
  switch (profile?['role']) {
    case 'partner':
      return '/partner-home';
    case 'doctor':
      return '/doctor-portal';
    case 'mother':
      final pregnancy = await client
          .from('pregnancy_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      // A newly registered account has the default Mother role but has not
      // chosen its role until its pregnancy profile exists.
      return pregnancy == null ? '/role-selection' : '/mother-home';
    default:
      return '/role-selection';
  }
}

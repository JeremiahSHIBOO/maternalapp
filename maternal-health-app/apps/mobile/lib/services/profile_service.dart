import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final _client = Supabase.instance.client;

  static Future<String> motherProfileId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Please sign in first.');
    final row = await _client
        .from('pregnancy_profiles')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) {
      throw StateError('Pregnancy profile is missing. Select the mother role and try again.');
    }
    return row['id'] as String;
  }
}

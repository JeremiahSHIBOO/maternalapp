import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('YOUR_') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_');
}

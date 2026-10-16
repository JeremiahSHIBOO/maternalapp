import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  /// Base URL for the Python wellness insights API.
  /// Configure via API_BASE_URL in .env. Defaults to the Android emulator
  /// localhost (10.0.2.2). For production, set this to your HTTPS backend URL
  /// and never hardcode a development machine's IP.
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL']?.trim() ?? 'http://10.0.2.2:8000';

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('YOUR_') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_');
}

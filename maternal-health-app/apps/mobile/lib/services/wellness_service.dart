import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app_config.dart';

/// Client for the Python wellness insights API.
///
/// The Flutter app authenticates with Supabase; the Supabase access token is
/// forwarded as a Bearer token so the Python API can verify the user's identity
/// via Supabase JWKS (with a local dev fallback).
class WellnessService {
  static const Duration _timeout = Duration(seconds: 30);

  /// Submit a wellness check-in and return the server's analysis (insights,
  /// suggestions, historical trends, ML prediction).
  static Future<Map<String, dynamic>> submitCheckIn({
    required String accessToken,
    required Map<String, dynamic> values,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/wellness/check-ins');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(values),
    ).timeout(_timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final detail = _extractErrorDetail(response.body);
    throw Exception('API error ${response.statusCode}: $detail');
  }

  /// Fetch today's insights for the authenticated user.
  static Future<Map<String, dynamic>> fetchTodayInsights({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/wellness/insights/today');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(_timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final detail = _extractErrorDetail(response.body);
    throw Exception('API error ${response.statusCode}: $detail');
  }

  static String _extractErrorDetail(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (decoded.containsKey('detail')) {
        return decoded['detail'].toString();
      }
      if (decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return body;
  }
}

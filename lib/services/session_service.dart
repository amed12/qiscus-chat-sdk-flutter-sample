import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _sessionKey = 'qiscus:multichannel_session';

  /// Save session map to shared preferences.
  static Future<void> saveSession(Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session));
  }

  /// Load session map; returns null when missing or invalid.
  static Future<Map<String, dynamic>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStr = prefs.getString(_sessionKey);

    if (sessionStr == null) return null;

    try {
      final decoded = jsonDecode(sessionStr) as Map<String, dynamic>;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Clear saved session.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}

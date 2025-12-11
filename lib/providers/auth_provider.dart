import 'package:flutter/foundation.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';
import 'package:qiscus_chat_flutter_sample/constants.dart';
import 'package:qiscus_chat_flutter_sample/services/notification_service.dart';
import 'package:qiscus_chat_flutter_sample/services/qiscus_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final QiscusService _qiscusService = QiscusService.instance;
  
  QAccount? _currentUser;
  bool _isLoading = false;
  String? _error;

  QAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _checkLoginStatus();
    debugPrint('AuthProvider initialized');
  }

  /// Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    // Don't notify here - will notify after check completes
    
    try {
      debugPrint('Checking login status...');
      debugPrint('SDK isLogin: ${_qiscusService.isLoggedIn()}');
      
      // First check if SDK has an active session
      if (_qiscusService.isLoggedIn()) {
        _currentUser = _qiscusService.getCurrentUser();
        debugPrint('✅ User is already logged in via SDK: ${_currentUser?.id} - ${_currentUser?.name}');
        await NotificationService.instance.syncDeviceTokenWithQiscus();
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // If SDK session is not active, try to restore from saved credentials
      debugPrint('SDK session not active, checking saved credentials...');
      final credentials = await getSavedCredentials();
      
      if (credentials != null) {
        debugPrint('Found saved credentials, attempting auto-login for: ${credentials['userId']}');
        final success = await login(
          userId: credentials['userId']!,
          userKey: credentials['userKey']!,
        );
        
        if (success) {
          debugPrint('✅ Auto-login successful');
        } else {
          debugPrint('❌ Auto-login failed, clearing saved credentials');
          await _clearCredentials();
          _isLoading = false;
          notifyListeners();
        }
      } else {
        debugPrint('No saved credentials found');
        _isLoading = false;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking login status: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with credentials
  Future<bool> login({
    required String userId,
    required String userKey,
    String? username,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      debugPrint('Attempting login for: $userId');
      
      final account = await _qiscusService.loginWithCredentials(
        userId: userId,
        userKey: userKey,
        username: username,
        avatarUrl: avatarUrl,
      );

      _currentUser = account;
      debugPrint('Login successful, saving credentials...');
      
      // Save login credentials for persistence
      await _saveCredentials(userId, userKey);
      debugPrint('Credentials saved to SharedPreferences');
      await NotificationService.instance.syncDeviceTokenWithQiscus();
      
      _setLoading(false);
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Login failed: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Login with JWT token
  Future<bool> loginWithToken({required String token}) async {
    _setLoading(true);
    _error = null;

    try {
      final account = await _qiscusService.loginWithToken(token: token);
      _currentUser = account;
      await NotificationService.instance.syncDeviceTokenWithQiscus();
      _setLoading(false);
      return true;
    } catch (e) {
      final code = _extractStatusCode(e);
      final friendlyMessage =
          code != null ? QiscusErrorCodes.messages[code] : null;

      if (code == QiscusErrorCodes.unauthorized) {
        await _clearCredentials();
      }

      _error = friendlyMessage ?? e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await NotificationService.instance.removeDeviceToken();
      await _qiscusService.logout();
      _currentUser = null;
      await _clearCredentials();
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  /// Update profile
  Future<bool> updateProfile({
    String? username,
    String? avatarUrl,
    Map<String, dynamic>? extras,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final account = await _qiscusService.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
        extras: extras,
      );

      _currentUser = account;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Save login credentials to SharedPreferences
  Future<void> _saveCredentials(String userId, String userKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('userKey', userKey);
      debugPrint('✅ Credentials saved: userId=$userId');
    } catch (e) {
      debugPrint('❌ Failed to save credentials: $e');
    }
  }

  /// Clear saved credentials
  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userKey');
  }

  /// Get saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userKey = prefs.getString('userKey');

      if (userId != null && userKey != null) {
        debugPrint('Found saved credentials for: $userId');
        return {'userId': userId, 'userKey': userKey};
      }
      debugPrint('No saved credentials found');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get saved credentials: $e');
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  int? _extractStatusCode(Object error) {
    final message = error.toString();
    final codeMatch = RegExp(r'\"status\"\s*:\s*(\d+)').firstMatch(message) ??
        RegExp(r'\bstatus[:=]\s*(\d+)').firstMatch(message) ??
        RegExp(r'http status.*?(\\d+)').firstMatch(message.toLowerCase());
    if (codeMatch != null) {
      return int.tryParse(codeMatch.group(1) ?? '');
    }
    return null;
  }
}

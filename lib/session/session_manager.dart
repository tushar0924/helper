import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  SessionManager() : _prefsFuture = SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefsFuture;

  static const String _accessTokenKey = 'session_access_token';
  static const String _refreshTokenKey = 'session_refresh_token';
  static const String _userIdKey = 'session_user_id';
  static const String _phoneKey = 'session_phone';
  static const String _fullNameKey = 'session_full_name';
  static const String _roleKey = 'session_role';
  static const String _expiresInKey = 'session_expires_in';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    int? userId,
    String? phone,
    String? fullName,
    String? role,
    int? expiresInSeconds,
  }) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);

    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    } else {
      await prefs.remove(_userIdKey);
    }

    if (phone != null && phone.isNotEmpty) {
      await prefs.setString(_phoneKey, phone);
    } else {
      await prefs.remove(_phoneKey);
    }

    if (fullName != null && fullName.isNotEmpty) {
      await prefs.setString(_fullNameKey, fullName);
    } else {
      await prefs.remove(_fullNameKey);
    }

    if (role != null && role.isNotEmpty) {
      await prefs.setString(_roleKey, role);
    } else {
      await prefs.remove(_roleKey);
    }

    if (expiresInSeconds != null) {
      await prefs.setInt(_expiresInKey, expiresInSeconds);
    } else {
      await prefs.remove(_expiresInKey);
    }
  }

  Future<String?> get accessToken async {
    final prefs = await _prefsFuture;
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> get refreshToken async {
    final prefs = await _prefsFuture;
    return prefs.getString(_refreshTokenKey);
  }

  Future<bool> get isLoggedIn async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, Object?>> getSessionData() async {
    final prefs = await _prefsFuture;
    return <String, Object?>{
      'accessToken': prefs.getString(_accessTokenKey),
      'refreshToken': prefs.getString(_refreshTokenKey),
      'userId': prefs.getInt(_userIdKey),
      'phone': prefs.getString(_phoneKey),
      'fullName': prefs.getString(_fullNameKey),
      'role': prefs.getString(_roleKey),
      'expiresInSeconds': prefs.getInt(_expiresInKey),
    };
  }

  Future<void> clearSession() async {
    final prefs = await _prefsFuture;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_expiresInKey);
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  const AuthUser.empty()
    : id = 0,
      phone = '',
      fullName = '',
      role = '',
      isActive = false;

  final int id;
  final String phone;
  final String fullName;
  final String role;
  final bool isActive;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _asInt(json['id']),
      phone: json['phone']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }
}

class LoginResponse {
  const LoginResponse({required this.success, required this.message});

  final bool success;
  final String message;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] is bool ? json['success'] as bool : true,
      message: json['message']?.toString() ?? '',
    );
  }
}

class VerifyOtpResponse {
  const VerifyOtpResponse({
    required this.success,
    required this.message,
    required this.isNewUser,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final bool success;
  final String message;
  final bool isNewUser;
  final AuthUser user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final accessToken = json['accessToken']?.toString() ?? '';
    final refreshToken = json['refreshToken']?.toString() ?? '';

    return VerifyOtpResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : accessToken.isNotEmpty,
      message: json['message']?.toString() ?? '',
      isNewUser: json['isNewUser'] == true,
      user: userJson is Map<String, dynamic>
          ? AuthUser.fromJson(userJson)
          : const AuthUser.empty(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: _asInt(json['expiresIn']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

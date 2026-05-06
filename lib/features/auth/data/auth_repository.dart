import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';
import '../../../session/session_manager.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._sessionManager);

  final ApiClient _apiClient;
  final SessionManager _sessionManager;

  Future<LoginResponse> sendLoginOtp(String phone) async {
    final response = await _apiClient.postJson(
      AuthApiEndpoint.login,
      body: <String, dynamic>{'phone': phone},
      showSuccessToast: false,
    );

    final loginResponse = LoginResponse.fromJson(response);
    if (!loginResponse.success) {
      throw ApiException(
        message: loginResponse.message.isEmpty
            ? 'Unable to request OTP'
            : loginResponse.message,
      );
    }

    return loginResponse;
  }

  Future<VerifyOtpResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiClient.postJson(
      AuthApiEndpoint.verifyOtp,
      body: <String, dynamic>{'phone': phone, 'otp': otp},
      showSuccessToast: false,
      showErrorToast: false,
    );

    final verifyResponse = VerifyOtpResponse.fromJson(response);
    if (!verifyResponse.success) {
      throw ApiException(
        message: verifyResponse.message.isEmpty
            ? 'Unable to verify OTP'
            : verifyResponse.message,
      );
    }

    await _sessionManager.saveSession(
      accessToken: verifyResponse.accessToken,
      refreshToken: verifyResponse.refreshToken,
      userId: verifyResponse.user.id == 0 ? null : verifyResponse.user.id,
      phone: verifyResponse.user.phone.isEmpty
          ? phone
          : verifyResponse.user.phone,
      fullName: verifyResponse.user.fullName,
      role: verifyResponse.user.role,
      expiresInSeconds: verifyResponse.expiresIn == 0
          ? null
          : verifyResponse.expiresIn,
    );

    return verifyResponse;
  }

  Future<void> completeProfile({
    required String fullName,
    required String gender,
    String? email,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedGender = gender.trim();
    final trimmedEmail = email?.trim() ?? '';

    final response = await _apiClient.postJson(
      UserApiEndpoint.completeProfile,
      requiresAuth: true,
      showSuccessToast: false,
      body: <String, dynamic>{
        'fullName': trimmedName,
        'gender': trimmedGender,
        if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
      },
    );

    final success = response['success'];
    if (success is bool && !success) {
      throw ApiException(
        message:
            response['message']?.toString() ?? 'Unable to complete profile',
      );
    }

    await _sessionManager.updateFullName(trimmedName);
  }

  Future<void> logout() async {
    try {
      final response = await _apiClient.postJson(
        AuthApiEndpoint.logout,
        requiresAuth: true,
        showSuccessToast: false,
      );

      final success = response['success'];
      if (success is bool && !success) {
        throw ApiException(
          message: response['message']?.toString() ?? 'Unable to logout',
        );
      }
    } catch (_) {
      // Even if the API call fails, clear local session to ensure user is logged out locally.
    } finally {
      await _sessionManager.clearSession();
    }
  }
}

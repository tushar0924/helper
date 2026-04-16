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

  Future<void> logout() async {
    await _sessionManager.clearSession();
  }
}

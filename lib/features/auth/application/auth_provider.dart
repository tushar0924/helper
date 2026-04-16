import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network/api_client.dart';
import '../../../session/session_manager.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class AuthState {
  const AuthState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(sessionManagerProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider),
    ref.read(sessionManagerProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<LoginResponse> sendLoginOtp(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.sendLoginOtp(phone);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      rethrow;
    }
  }

  Future<VerifyOtpResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.verifyOtp(phone: phone, otp: otp);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.read(authRepositoryProvider));
  },
);

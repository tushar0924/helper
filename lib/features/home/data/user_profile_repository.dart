import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';
import '../../../session/session_manager.dart';
import '../modal/complete_profile_response_modal.dart';
import '../modal/user_profile_modal.dart';

class UserProfileRepository {
  UserProfileRepository(this._apiClient, this._sessionManager);

  final ApiClient _apiClient;
  final SessionManager _sessionManager;

  Future<UserProfileModal> getProfile() async {
    final response = await _apiClient.getJson(
      UserApiEndpoint.me,
      requiresAuth: true,
    );

    final profileResponse = UserProfileResponseModal.fromJson(response);
    if (!profileResponse.success) {
      throw ApiException(message: 'Unable to load profile');
    }

    await _sessionManager.updateFullName(profileResponse.data.fullName);
    return profileResponse.data;
  }

  Future<UserProfileModal> completeProfile({
    required String fullName,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
    };

    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }

    final response = await _apiClient.putJson(
      UserApiEndpoint.profile,
      requiresAuth: true,
      body: body,
    );

    final completeResponse = CompleteProfileResponseModal.fromJson(response);
    if (!completeResponse.success) {
      throw ApiException(
        message: completeResponse.message.isEmpty
            ? 'Unable to save profile'
            : completeResponse.message,
      );
    }

    await _sessionManager.updateFullName(completeResponse.user.fullName);
    return completeResponse.user;
  }
}

import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';

class HomeBootstrapRepository {
  HomeBootstrapRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getHomeByPincode(String pincode) async {
    final normalized = pincode.trim();
    if (normalized.isEmpty) {
      return const <String, dynamic>{};
    }

    return _apiClient.getJson(
      HomeApiEndpoint.homeByPincode(Uri.encodeQueryComponent(normalized)),
      requiresAuth: true,
      showSuccessToast: false,
      showErrorToast: false,
    );
  }

  Future<Map<String, dynamic>> notifyServiceability({
    required String pincode,
    int? userId,
  }) async {
    return _apiClient.postJson(
      ServiceabilityApiEndpoint.notify,
      requiresAuth: false,
      body: <String, dynamic>{
        'pincode': pincode,
        if (userId != null) 'userId': userId,
      },
    );
  }
}

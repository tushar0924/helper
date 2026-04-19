import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';
import '../modal/service_detail_modal.dart';
import '../modal/service_modal.dart';

class ServiceRepository {
  ServiceRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ServiceModal>> getServicesByCategory(int categoryId) async {
    final response = await _apiClient.getJson(
      '${HomeApiEndpoint.services}?categoryId=$categoryId',
    );

    if (response['success'] == false) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Unable to load services',
      );
    }

    final data = response['data'];
    if (data is! List) {
      return const <ServiceModal>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(ServiceModal.fromJson)
        .toList(growable: false);
  }

  Future<ServiceDetailModal> getServiceDetails(int serviceId) async {
    final response = await _apiClient.getJson(
      '${HomeApiEndpoint.services}/$serviceId',
    );

    if (response['success'] == false) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Unable to load service',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException(message: 'Unable to load service details');
    }

    return ServiceDetailModal.fromJson(Map<String, dynamic>.from(data));
  }
}

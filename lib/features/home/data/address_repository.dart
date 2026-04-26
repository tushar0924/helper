import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';
import 'address_models.dart';

class AddressRepository {
  AddressRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<GetAddressesResponse> getAddresses() async {
    final response = await _apiClient.getJson(
      UserApiEndpoint.addresses,
      requiresAuth: true,
    );

    return GetAddressesResponse.fromJson(response);
  }

  Future<SavedAddressData> getAddressById(int addressId) async {
    final response = await _apiClient.getJson(
      UserApiEndpoint.addressById(addressId),
      requiresAuth: true,
    );

    final dataJson = response['data'];
    if (response['success'] != true || dataJson is! Map<String, dynamic>) {
      throw ApiException(message: 'Unable to load address.');
    }

    return SavedAddressData.fromJson(dataJson);
  }

  Future<SavedAddressResponse> saveAddress(AddressDraft draft) async {
    final response = await _apiClient.postJson(
      UserApiEndpoint.addresses,
      requiresAuth: true,
      body: draft.toApiBody(),
    );

    return SavedAddressResponse.fromJson(response);
  }

  Future<SavedAddressResponse> updateAddress({
    required int addressId,
    required AddressDraft draft,
  }) async {
    final response = await _apiClient.putJson(
      UserApiEndpoint.addressById(addressId),
      requiresAuth: true,
      body: draft.toApiBody(),
    );

    return SavedAddressResponse.fromJson(response);
  }
}

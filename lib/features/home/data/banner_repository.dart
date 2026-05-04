import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';
import '../modal/banner_modal.dart';

class BannerRepository {
  BannerRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<BannerModal>> getBanners({String? city}) async {
    final normalizedCity = city?.trim();
    if (normalizedCity != null && normalizedCity.isNotEmpty) {
      try {
        final cityBanners = await _fetchBanners(city: normalizedCity);
        if (cityBanners.isNotEmpty) {
          return cityBanners;
        }
      } catch (_) {
        // Fall back to generic banners below.
      }
    }

    return _fetchBanners();
  }

  Future<List<BannerModal>> _fetchBanners({String? city}) async {
    final response = await _apiClient.getJson(
      HomeApiEndpoint.banners(city: city),
      requiresAuth: false,
      showSuccessToast: false,
    );

    final data = response['data'];
    if (data is! List) {
      return const <BannerModal>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(BannerModal.fromJson)
        .where((banner) => banner.mediaUrl.isNotEmpty)
        .toList(growable: false);
  }
}
